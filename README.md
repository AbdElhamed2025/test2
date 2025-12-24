# Inventory stock reversion script (Magento 2 / MSI)

This repo contains a **standalone PHP script** to:

- **Add qty back to source stock** (MSI `inventory_source_item`)
- **Release reserved qty** by appending a **compensating reservation** (MSI `inventory_reservation`)

## Files

- `revert_stock_and_reservations.php`: the script (dry-run by default)
- `revert_stock_list.tsv`: your current SKU/QTY list (tab-separated)

## How to run (from your Magento root)

1. Copy `revert_stock_and_reservations.php` and `revert_stock_list.tsv` into your Magento root (same folder as `app/` and `bin/`).
2. Dry-run first:

```bash
php revert_stock_and_reservations.php --input=revert_stock_list.tsv
```

3. Apply changes:

```bash
php revert_stock_and_reservations.php --input=revert_stock_list.tsv --apply
```

## Options

- `--source=default`: which MSI `source_code` to add qty back to
- `--stock-id=1`: which MSI `stock_id` to use for reservations
- `--reservation-mode=offset|force`:
  - `offset` (default): only releases up to the **current negative** net reservation for that SKU
  - `force`: always appends `+qty` reservation from the file
- `--skip-stock`: only release reservations (don’t change source qty)
- `--skip-reservations`: only add back to stock (don’t touch reservations)
- `--quiet`: less output

## Notes / safety

- The script is **dry-run by default**. Nothing is written unless you pass `--apply`.
- If your store uses non-default `source_code` or `stock_id`, pass them explicitly.
- After applying, you may want to reindex (depends on your setup):

```bash
php bin/magento indexer:reindex inventory inventory_stock
```