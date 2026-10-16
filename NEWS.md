# Satisficing 0.2.0

Version 0.2.0 incorporates 7 careless responding indices and 2 sample datasets ported from the CRAN package `careless` (version 1.2.2), while maintaining full backward compatibility with the existing functions (`stline`, `matching`, `rawnn`).

### New Features (Ported from 'careless' 1.2.2)

- `longstring()`: Computes the maximum (and optionally average) length of consecutive identical responses across items.
- `irv()`: Computes intra-individual response variability (IRV) across all items or subsets of items.
- `evenodd()`: Computes the even-odd consistency score based on subscale correlations.
- `psychsyn()`: Computes the within-person correlation across psychometric synonym item pairs.
- `psychant()`: Computes the within-person correlation across psychometric antonym item pairs.
- `psychsyn_critval()`: Computes and ranks correlations between all item pairs to assist in determining critical values.
- `mahad()`: Computes Mahalanobis D using `psych::outlier` and flags potential multivariate outliers.
- Datasets: Added `careless_dataset` (200 x 50) and `careless_dataset2` (1000 x 100) from `careless` 1.2.2.

### Third-Party Licensing and Attribution

- Ported code, datasets, and documentation from `careless` 1.2.2 are licensed under the MIT License ((c) 2016 Richard Yentes).
- Full MIT license text and component copyright notices are available in `inst/licenses/careless-MIT.txt` and `inst/COPYRIGHTS` (and at `licenses/careless-MIT.txt` and `COPYRIGHTS` in installed packages).
- `Satisficing` as a whole remains licensed under GPL (>= 2).
- Added `Imports: psych` for `mahad()`. `careless` itself is not a runtime dependency.

---

# Satisficing 0.1.0

Initial release of `Satisficing`, titled to describe its role in detecting indicators of survey satisficing. The package provides functions for inspecting survey response patterns and evaluating row-wise logical conditions; these indicators do not establish satisficing on their own.

- `stline()` adds a straight-line indicator across selected columns. It supports logical, numeric (integer and double), character, and factor columns. All selected columns must belong to the same type group; factor columns must have identical levels and ordered status. Rows with fewer than two non-missing selected values return `NA_integer_`; rows with at least two values return `1L` when all are equal and not excluded, and `0L` otherwise. `exclude_values` can mark a matching repeated response as `0L`.
- `matching()` evaluates a logical expression in the data frame context with caller-environment fallback. The result must be logical and have exactly `nrow(data)` values; `TRUE`, `FALSE`, and `NA` become `1L`, `0L`, and `NA_integer_`.
- `rawnn()` prints each column's 1-based index and name, and returns `invisible(NULL)`.
