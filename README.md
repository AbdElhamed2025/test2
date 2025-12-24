# Inventory stock reversion script (Magento 2 / MSI)

This repo contains a **standalone PHP script** to:

- **Add qty back to source stock** (MSI `inventory_source_item`)
- **Release reserved qty** by appending a **compensating reservation** (MSI `inventory_reservation`)

## Files

- `revert_stock_and_reservations.php`: the script (dry-run by default)
- `revert_stock_list.tsv`: your current SKU/QTY list (tab-separated)

## How to run (from your Magento root)

1. Copy `revert_stock_and_reservations.php` into your Magento `pub/` directory.
2. Put your input file at `var/import/restore_stock.csv` (CSV or TSV with header: `sku` + `qty` or `qty_remaining`).
3. Dry-run first (default):

```bash
php pub/revert_stock_and_reservations.php
```

4. To apply changes, edit the script and set `$apply = true;`, then run:

```bash
php pub/revert_stock_and_reservations.php
```

## Config

Edit these at the top of `pub/revert_stock_and_reservations.php`:

- `$csvFile` (default: `BP . '/var/import/restore_stock.csv'`)
- `$sourceCode` (default: `default`)
- `$stockId` (default: `1`)
- `$apply` (default: `false` / dry-run)

## Notes / safety

- The script is **dry-run by default**. Nothing is written unless you pass `--apply`.
- If your store uses non-default `source_code` or `stock_id`, pass them explicitly.
- After applying, you may want to reindex (depends on your setup):

```bash
php bin/magento indexer:reindex inventory inventory_stock
```