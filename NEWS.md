# Satisficing 0.1.0

Initial release of `Satisficing`, titled to describe its role in detecting indicators of survey satisficing. The package provides functions for inspecting survey response patterns and evaluating row-wise logical conditions; these indicators do not establish satisficing on their own.

- `stline()` adds a straight-line indicator across selected columns. It supports logical, numeric (integer and double), character, and factor columns. All selected columns must belong to the same type group; factor columns must have identical levels and ordered status. Rows with fewer than two non-missing selected values return `NA_integer_`; rows with at least two values return `1L` when all are equal and not excluded, and `0L` otherwise. `exclude_values` can mark a matching repeated response as `0L`.
- `matching()` evaluates a logical expression in the data frame context with caller-environment fallback. The result must be logical and have exactly `nrow(data)` values; `TRUE`, `FALSE`, and `NA` become `1L`, `0L`, and `NA_integer_`.
- `rawnn()` prints each column's 1-based index and name, and returns `invisible(NULL)`.
