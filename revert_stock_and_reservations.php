<?php
declare(strict_types=1);

/**
 * Magento 2 MSI stock + reservations revert helper (place in pub/).
 *
 * What it does (per SKU):
 *  - Adds qty back to a source item (increment current qty)
 *  - Appends a compensating MSI reservation (+qty) to release reserved qty
 *
 * Safety:
 *  - Set $apply = true to write changes.
 *
 * Run:
 *  php pub/revert_stock_and_reservations.php
 */

if (PHP_SAPI !== 'cli') {
    http_response_code(403);
    echo "This script must be run from CLI.\n";
    exit(1);
}

use Magento\Framework\App\Bootstrap;
use Magento\Framework\App\State;

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
 * Auto-detect delimiter (comma vs tab) from the header line.
 * Returns ',' or "\t".
 */
function detectCsvDelimiter(string $headerLine): string
{
    $commaCount = substr_count($headerLine, ',');
    $tabCount = substr_count($headerLine, "\t");
    return $tabCount > $commaCount ? "\t" : ',';
}

require __DIR__ . '/../app/bootstrap.php';

$bootstrap = Bootstrap::create(BP, $_SERVER);
$objectManager = $bootstrap->getObjectManager();

/** @var State $state */
$state = $objectManager->get(State::class);
try {
    $state->setAreaCode('adminhtml');
} catch (Throwable $e) {
    // Area code can only be set once; ignore if already set.
}

/** ==============================
 *  CONFIG
 *  ============================== */
$apply = false; // set true to write changes
$csvFile = BP . '/var/import/restore_stock.csv'; // CSV/TSV must contain: sku + qty (or qty_remaining)
$sourceCode = 'default';
$stockId = 1; // for MSI reservations
$reservationMetadata = 'manual restore from csv';

if (!file_exists($csvFile)) {
    echo "CSV file not found: {$csvFile}\n";
    exit(1);
}

/** ==============================
 *  SERVICES
 *  ============================== */
$sourceItemFactory = $objectManager->get(
    \Magento\InventoryApi\Api\Data\SourceItemInterfaceFactory::class
);

$getSourceItemsBySku = $objectManager->get(
    \Magento\InventoryApi\Api\GetSourceItemsBySkuInterface::class
);

$sourceItemsSave = $objectManager->get(
    \Magento\InventoryApi\Api\SourceItemsSaveInterface::class
);

$reservationFactory = $objectManager->get(
    \Magento\InventoryReservationsApi\Api\Data\ReservationInterfaceFactory::class
);

$reservationAppend = $objectManager->get(
    \Magento\InventoryReservationsApi\Model\AppendReservationsInterface::class
);

/** ==============================
 *  READ CSV / TSV
 *  ============================== */
$handle = fopen($csvFile, 'r');
if ($handle === false) {
    echo "Failed to open file: {$csvFile}\n";
    exit(1);
}

$firstLine = fgets($handle);
if ($firstLine === false) {
    echo "File is empty: {$csvFile}\n";
    exit(1);
}

$delimiter = detectCsvDelimiter($firstLine);
$header = str_getcsv(trim($firstLine), $delimiter);

$skuIndex = array_search('sku', $header, true);
$qtyIndex = array_search('qty', $header, true);
if ($qtyIndex === false) {
    $qtyIndex = array_search('qty_remaining', $header, true);
}

if ($skuIndex === false || $qtyIndex === false) {
    echo "CSV must contain headers: sku + qty (or qty_remaining)\n";
    exit(1);
}

echo "Starting stock restore...\n";
echo "Mode: " . ($apply ? "APPLY" : "DRY-RUN") . "\n";
echo "File: {$csvFile}\n";
echo "Delimiter: " . ($delimiter === "\t" ? "TAB" : "COMMA") . "\n";

/** ==============================
 *  PROCESS
 *  ============================== */
while (($row = fgetcsv($handle, 0, $delimiter)) !== false) {
    $sku = normalizeSku((string)($row[$skuIndex] ?? ''));
    $qty = (float)($row[$qtyIndex] ?? 0);

    if ($sku === '' || $qty <= 0) {
        continue;
    }

    // 1) Restore physical stock (increment existing qty for this source)
    $oldQty = 0.0;
    $existing = null;
    $sourceItems = $getSourceItemsBySku->execute($sku);
    foreach ($sourceItems as $si) {
        if ($si->getSourceCode() === $sourceCode) {
            $existing = $si;
            break;
        }
    }
    if ($existing) {
        $oldQty = (float)$existing->getQuantity();
    }
    $newQty = $oldQty + $qty;

    $sourceItem = $existing ?: $sourceItemFactory->create();
    $sourceItem->setSku($sku);
    $sourceItem->setSourceCode($sourceCode);
    $sourceItem->setQuantity($newQty);
    $sourceItem->setStatus(1);

    // 2) Release reservation by appending +qty (offsets existing negative reservations)
    $reservation = $reservationFactory->create();
    $reservation->setSku($sku);
    $reservation->setQuantity($qty);
    if (method_exists($reservation, 'setStockId')) {
        $reservation->setStockId($stockId);
    }
    $reservation->setMetadata($reservationMetadata);

    if ($apply) {
        $sourceItemsSave->execute([$sourceItem]);
        $reservationAppend->execute([$reservation]);
    }

    echo "✔ SKU {$sku} | stock {$oldQty} -> {$newQty} | reservation +" . $qty . "\n";
}

fclose($handle);

echo "Done.\n";

