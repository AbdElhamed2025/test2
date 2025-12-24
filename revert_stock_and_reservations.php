<?php
declare(strict_types=1);

/**
 * Magento 2 MSI stock + reservations revert helper.
 *
 * What it does (per SKU):
 *  - Adds qty back to a source item (default source is "default")
 *  - Appends a compensating MSI reservation (positive qty) to release reserved qty
 *
 * Safety:
 *  - DRY-RUN by default. Use --apply to write changes.
 *
 * Usage examples (run from Magento root):
 *  php -d detect_unicode=0 revert_stock_and_reservations.php --input=revert_stock_list.tsv
 *  php revert_stock_and_reservations.php --input=revert_stock_list.tsv --source=default --stock-id=1
 *  php revert_stock_and_reservations.php --input=revert_stock_list.tsv --apply
 *  php revert_stock_and_reservations.php --input=revert_stock_list.tsv --reservation-mode=force --apply
 */

if (PHP_SAPI !== 'cli') {
    http_response_code(403);
    echo "This script must be run from CLI.\n";
    exit(1);
}

use Magento\Framework\App\Bootstrap;
use Magento\Framework\App\State;
use Magento\Framework\App\ResourceConnection;
use Magento\InventoryApi\Api\Data\SourceItemInterfaceFactory;
use Magento\InventoryApi\Api\GetSourceItemsBySkuInterface;
use Magento\InventoryApi\Api\SourceItemsSaveInterface;

// -----------------------------
// CLI parsing
// -----------------------------

function usageAndExit(int $code = 1): void
{
    $script = basename(__FILE__);
    fwrite(STDERR, <<<TXT
{$script}

Required:
  --input=path/to/file.tsv

Optional:
  --apply                      Actually write changes (default: dry-run)
  --source=default             MSI source_code to add qty back to
  --stock-id=1                 MSI stock_id for reservations table
  --reservation-mode=offset    "offset" (default) = only release up to current negative reservations
                               "force" = always append +qty reservation
  --skip-stock                 Do NOT change MSI source stock (only reservations)
  --skip-reservations          Do NOT append MSI reservations (only source stock)
  --area=adminhtml             Area code (adminhtml recommended)
  --quiet                      Less output

Examples:
  php {$script} --input=revert_stock_list.tsv
  php {$script} --input=revert_stock_list.tsv --apply

TXT);
    exit($code);
}

function parseArgs(array $argv): array
{
    $args = [
        'input' => null,
        'apply' => false,
        'source' => 'default',
        'stock_id' => 1,
        'reservation_mode' => 'offset', // offset|force
        'area' => 'adminhtml',
        'quiet' => false,
        'do_stock' => true,
        'do_reservations' => true,
    ];

    foreach ($argv as $i => $arg) {
        if ($i === 0) {
            continue;
        }
        if ($arg === '--apply') {
            $args['apply'] = true;
            continue;
        }
        if ($arg === '--quiet') {
            $args['quiet'] = true;
            continue;
        }
        if ($arg === '--skip-stock') {
            $args['do_stock'] = false;
            continue;
        }
        if ($arg === '--skip-reservations') {
            $args['do_reservations'] = false;
            continue;
        }
        if ($arg === '--help' || $arg === '-h') {
            usageAndExit(0);
        }
        if (str_starts_with($arg, '--input=')) {
            $args['input'] = substr($arg, strlen('--input='));
            continue;
        }
        if (str_starts_with($arg, '--source=')) {
            $args['source'] = substr($arg, strlen('--source='));
            continue;
        }
        if (str_starts_with($arg, '--stock-id=')) {
            $args['stock_id'] = (int)substr($arg, strlen('--stock-id='));
            continue;
        }
        if (str_starts_with($arg, '--reservation-mode=')) {
            $args['reservation_mode'] = strtolower(substr($arg, strlen('--reservation-mode=')));
            continue;
        }
        if (str_starts_with($arg, '--area=')) {
            $args['area'] = substr($arg, strlen('--area='));
            continue;
        }
        fwrite(STDERR, "Unknown argument: {$arg}\n");
        usageAndExit(1);
    }

    if (!$args['input']) {
        fwrite(STDERR, "Missing required --input=...\n");
        usageAndExit(1);
    }
    if ($args['stock_id'] < 1) {
        fwrite(STDERR, "--stock-id must be >= 1\n");
        usageAndExit(1);
    }
    if (!in_array($args['reservation_mode'], ['offset', 'force'], true)) {
        fwrite(STDERR, "--reservation-mode must be 'offset' or 'force'\n");
        usageAndExit(1);
    }

    return $args;
}

function logLine(string $msg, bool $quiet = false): void
{
    if ($quiet) {
        return;
    }
    fwrite(STDOUT, $msg . PHP_EOL);
}

/**
 * Excel sometimes converts numeric-looking SKUs into scientific notation.
 * Example: "6.224E+12" -> "6224000000000"
 */
function normalizeSku(string $sku): string
{
    $sku = trim($sku);
    if ($sku === '') {
        return '';
    }

    if (preg_match('/^\d+(?:\.\d+)?E\+\d+$/i', $sku) === 1) {
        // For values up to ~9e15, double can represent integer exactly (2^53 ~ 9e15).
        $asFloat = (float)$sku;
        $asInt = sprintf('%.0f', $asFloat);
        return $asInt;
    }

    return $sku;
}

/**
 * Parses a TSV/whitespace file with columns: sku <tab> qty
 * Also supports lines without tabs by using "last token = qty, rest = sku".
 *
 * Returns [sku => totalQty].
 */
function readSkuQtyFile(string $path): array
{
    if (!is_file($path)) {
        throw new RuntimeException("Input file not found: {$path}");
    }
    $raw = file_get_contents($path);
    if ($raw === false) {
        throw new RuntimeException("Failed to read input file: {$path}");
    }

    $lines = preg_split("/\r\n|\n|\r/", $raw) ?: [];
    $out = [];

    foreach ($lines as $idx => $line) {
        $line = trim($line);
        if ($line === '') {
            continue;
        }
        // Skip header if present
        if ($idx === 0 && preg_match('/^sku\b/i', $line) === 1) {
            continue;
        }

        $sku = '';
        $qty = null;

        if (str_contains($line, "\t")) {
            $parts = preg_split("/\t+/", $line) ?: [];
            if (count($parts) >= 2) {
                $sku = (string)$parts[0];
                $qty = (int)trim((string)$parts[1]);
            }
        } else {
            // Fallback: last whitespace token is qty
            $parts = preg_split('/\s+/', $line) ?: [];
            if (count($parts) >= 2) {
                $qtyToken = array_pop($parts);
                $qty = (int)trim((string)$qtyToken);
                $sku = trim(implode(' ', $parts));
            }
        }

        $sku = normalizeSku($sku);
        if ($sku === '' || $qty === null) {
            continue;
        }
        if ($qty <= 0) {
            continue;
        }

        $out[$sku] = ($out[$sku] ?? 0) + $qty;
    }

    return $out;
}

/**
 * Find Magento root by walking up until app/bootstrap.php is found.
 * Works when the script is placed in pub/ (or deeper) and executed from anywhere.
 */
function findMagentoRoot(string $startDir, int $maxLevelsUp = 6): string
{
    $dir = $startDir;
    for ($i = 0; $i <= $maxLevelsUp; $i++) {
        $bootstrap = $dir . DIRECTORY_SEPARATOR . 'app' . DIRECTORY_SEPARATOR . 'bootstrap.php';
        if (is_file($bootstrap)) {
            return $dir;
        }
        $parent = dirname($dir);
        if ($parent === $dir) {
            break;
        }
        $dir = $parent;
    }
    throw new RuntimeException("Cannot find Magento root (missing app/bootstrap.php) starting from: {$startDir}");
}

// -----------------------------
// Main
// -----------------------------

$args = parseArgs($argv);
$scriptDir = __DIR__;
$inputPath = $args['input'];

// If the user provided a relative path, resolve relative to the script directory (recommended when script lives in pub/)
if (!str_starts_with($inputPath, DIRECTORY_SEPARATOR)) {
    $inputPath = $scriptDir . DIRECTORY_SEPARATOR . $inputPath;
}

try {
    $magentoRoot = findMagentoRoot($scriptDir);
} catch (Throwable $e) {
    fwrite(STDERR, $e->getMessage() . PHP_EOL);
    fwrite(STDERR, "Tip: place this script in Magento 'pub/' and run: php pub/" . basename(__FILE__) . " ...\n");
    exit(2);
}

$bootstrapPath = $magentoRoot . DIRECTORY_SEPARATOR . 'app' . DIRECTORY_SEPARATOR . 'bootstrap.php';

$skuQty = readSkuQtyFile($inputPath);
if (count($skuQty) === 0) {
    fwrite(STDERR, "No valid rows found in input file: {$inputPath}\n");
    exit(3);
}

// Many Magento services assume CWD = Magento root.
@chdir($magentoRoot);

require $bootstrapPath;

$bootstrap = Bootstrap::create(BP, $_SERVER);
$objectManager = $bootstrap->getObjectManager();

/** @var State $state */
$state = $objectManager->get(State::class);
try {
    $state->setAreaCode($args['area']);
} catch (Throwable $e) {
    // Area code can only be set once; ignore if already set.
}

/** @var ResourceConnection $resource */
$resource = $objectManager->get(ResourceConnection::class);
$connection = $resource->getConnection();

/** @var GetSourceItemsBySkuInterface $getSourceItemsBySku */
$getSourceItemsBySku = $objectManager->get(GetSourceItemsBySkuInterface::class);
/** @var SourceItemsSaveInterface $sourceItemsSave */
$sourceItemsSave = $objectManager->get(SourceItemsSaveInterface::class);
/** @var SourceItemInterfaceFactory $sourceItemFactory */
$sourceItemFactory = $objectManager->get(SourceItemInterfaceFactory::class);

$reservationTable = $resource->getTableName('inventory_reservation');

$apply = (bool)$args['apply'];
$sourceCode = (string)$args['source'];
$stockId = (int)$args['stock_id'];
$reservationMode = (string)$args['reservation_mode'];
$quiet = (bool)$args['quiet'];
$doStock = (bool)$args['do_stock'];
$doReservations = (bool)$args['do_reservations'];

logLine("Input: {$inputPath}", $quiet);
logLine("Rows (unique SKUs): " . count($skuQty), $quiet);
logLine("Mode: " . ($apply ? "APPLY (will write changes)" : "DRY-RUN (no changes)"), $quiet);
logLine("Source: {$sourceCode}", $quiet);
logLine("Stock ID: {$stockId}", $quiet);
logLine("Reservation mode: {$reservationMode}", $quiet);
logLine("Do stock update: " . ($doStock ? "yes" : "no"), $quiet);
logLine("Do reservations update: " . ($doReservations ? "yes" : "no"), $quiet);
logLine(str_repeat('-', 80), $quiet);

$ok = 0;
$errors = 0;
$releasedReservationsTotal = 0.0;
$restockedTotal = 0.0;

foreach ($skuQty as $sku => $qtyToRevert) {
    try {
        $qtyToRevert = (float)$qtyToRevert;

        // Current net reservations for this SKU in this stock_id
        $reservedNet = 0.0;
        if ($doReservations) {
            $reservedNet = (float)$connection->fetchOne(
                "SELECT COALESCE(SUM(quantity), 0) FROM {$reservationTable} WHERE stock_id = ? AND sku = ?",
                [$stockId, $sku]
            );
        }

        // Determine how much reservation to append
        $releaseQty = 0.0;
        if ($doReservations) {
            $releaseQty = $qtyToRevert;
            if ($reservationMode === 'offset') {
                if ($reservedNet >= 0) {
                    $releaseQty = 0.0;
                } else {
                    $releaseQty = min($qtyToRevert, abs($reservedNet));
                }
            }
        }

        // Read source item for SKU + source
        $targetSourceItem = null;
        $oldSourceQty = 0.0;
        $newSourceQty = 0.0;
        if ($doStock) {
            $sourceItems = $getSourceItemsBySku->execute($sku);
            foreach ($sourceItems as $si) {
                if ($si->getSourceCode() === $sourceCode) {
                    $targetSourceItem = $si;
                    break;
                }
            }
            $oldSourceQty = $targetSourceItem ? (float)$targetSourceItem->getQuantity() : 0.0;
            $newSourceQty = $oldSourceQty + $qtyToRevert;
        }

        if (!$quiet) {
            logLine("SKU: {$sku}");
            if ($doStock) {
                logLine("  - Source qty: {$oldSourceQty} -> {$newSourceQty} (+" . $qtyToRevert . ")");
            } else {
                logLine("  - Source qty: (skipped)");
            }
            if ($doReservations) {
                logLine("  - Net reserved (stock {$stockId}): {$reservedNet}");
                logLine("  - Reservation append: +" . $releaseQty . ($releaseQty > 0 ? '' : ' (skipped)'));
            } else {
                logLine("  - Reservations: (skipped)");
            }
        }

        if ($apply) {
            if ($doStock) {
                if ($targetSourceItem) {
                    $targetSourceItem->setQuantity($newSourceQty);
                    $targetSourceItem->setStatus(1); // in stock
                    $sourceItemsSave->execute([$targetSourceItem]);
                } else {
                    $newItem = $sourceItemFactory->create();
                    $newItem->setSku($sku);
                    $newItem->setSourceCode($sourceCode);
                    $newItem->setQuantity($newSourceQty);
                    $newItem->setStatus(1); // in stock
                    $sourceItemsSave->execute([$newItem]);
                }
            }

            if ($doReservations && $releaseQty > 0) {
                $metadata = [
                    'event_type' => 'manual_stock_revert',
                    'object_type' => 'manual',
                    'object_id' => (string)date('Ymd-His'),
                    'comment' => 'Revert back to stock + release reserved (script)',
                    'source_code' => $sourceCode,
                    'input_file' => basename($inputPath),
                ];

                $connection->insert($reservationTable, [
                    'stock_id' => $stockId,
                    'sku' => $sku,
                    'quantity' => (string)$releaseQty,
                    'metadata' => json_encode($metadata, JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE),
                ]);
            }
        }

        if ($doStock) {
            $restockedTotal += $qtyToRevert;
        }
        if ($doReservations) {
            $releasedReservationsTotal += $releaseQty;
        }
        $ok++;
    } catch (Throwable $e) {
        $errors++;
        fwrite(STDERR, "ERROR for SKU '{$sku}': " . $e->getMessage() . PHP_EOL);
    }

    if (!$quiet) {
        logLine(str_repeat('-', 80), $quiet);
    }
}

logLine("Done.", $quiet);
logLine("Successful SKUs: {$ok}", $quiet);
logLine("Errors: {$errors}", $quiet);
logLine("Total qty added back to source: {$restockedTotal}", $quiet);
logLine("Total reservations released (appended): {$releasedReservationsTotal}", $quiet);

if ($apply) {
    logLine("", $quiet);
    logLine("Note: you may want to run indexers after this (depends on your setup):", $quiet);
    logLine("  php bin/magento indexer:reindex inventory inventory_stock", $quiet);
}

