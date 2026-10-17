# Satisficing 0.3.0

Version 0.3.0 implements straightlining measures described by Kim et al. (2019) aligned with the canonical API conventions of `mweylandt/straightliner` (commit `2873384c8bc54aec48abb54e9543c408723fbe0a`), while maintaining full backward compatibility with all existing functions (`stline`, `irv`, `matching`, `rawnn`, and careless-derived indices).

### Canonical Straightliner API

- `meanRootPairs()`: Computes the sample-normalized Mean Root of Pairs (MRP) across valid item pairs using the Kim et al. (2019) paper formula, where higher values indicate relatively less differentiation (more straightlining).
- `maxIdenticalRating()`: Computes the Maximum Identical Rating (MIR), defined as the proportion of questions answered with the most common response choice.
- `question_sd()`: Computes the intra-individual standard deviation across the question battery for each respondent.
- `scale_point_variation()`: Computes the Scale Point Variation (SPV), measuring response diversity across response categories (treating missing data as a separate category, matching straightliner conventions).
- `nondiff()`: Computes simple nondifferentiation as a logical vector (`TRUE` if all responses in a row are identical, `FALSE` otherwise).
- `straightlining()`: Convenience function computing multiple individual-level straightlining indicators (`mrp`, `mir`, `qsd`, `spv`, `nondiff`) for a question set, optionally appending results to the original data.
- `straightlining_qset()`: Computes aggregate battery-level straightlining summaries across multiple question sets, returning an object of class `c("straightliner", "data.frame")` with custom `print()` formatting.

### Legacy Compatibility Wrappers

- `mrp()`: Backward-compatibility wrapper around `meanRootPairs()`, appending the normalized MRP scores to the input data frame.
- `mir()`: Backward-compatibility wrapper around `maxIdenticalRating()`, appending MIR scores to the input data frame.
- `spv()`: Backward-compatibility wrapper around `scale_point_variation()`, appending SPV scores to the input data frame.
- `stline()`: Long-term original straight-line detection function returning an integer indicator (`1L`, `0L`, `NA_integer_`) based on whether observed non-missing values (at least 2) are identical.
- `irv()`: Long-term function computing intra-individual response variability (row-wise standard deviation).

### Methodological Notes and Comparison

- **Kim et al. (2019) 5 Straightlining Measures Correspondence**:
  - Simple nondifferentiation: Evaluated by `nondiff()` (logical) and `stline()` (integer flag). `nondiff()` evaluates whether `length(unique(row)) == 1L`. In complete data, both identify identical responses; under partial item nonresponse, `stline()` evaluates whether observed non-missing responses are identical (requiring at least 2 observed values).
  - Mean root of pairs: Implemented by `meanRootPairs()` and `mrp()`. Evaluated using exact Kim et al. (2019) paper formula hand calculations. (Note: code-level numerical comparison with `straightliner` commit `2873384c8bc54aec48abb54e9543c408723fbe0a` is unverified because its `R/MRP.R` references undefined `vars` and computes `sqrt(sums)` rather than the sum of square roots).
  - Maximum identical rating: Implemented by `maxIdenticalRating()` and `mir()`.
  - Standard deviation of battery: Implemented by `question_sd()` and `irv()`.
  - Scale point variation: Implemented by `scale_point_variation()` and `spv()`.
- Reference: Kim, Y., Dykema, J., Stevenson, J., Black, P., & Moberg, D. P. (2019). Straightlining: Overview of Measurement, Comparison of Indicators, and Effects in Mail–Web Mixed-Mode Surveys. *Social Science Computer Review*, 37(2), 214–233. DOI: 10.1177/0894439317752406.

---

# Satisficing 0.2.0

Version 0.2.0 incorporates 7 careless responding indices and 2 sample datasets ported from the CRAN package `careless` (version 1.2.2), while maintaining full backward compatibility with the existing functions (`stline`, `matching`, `rawnn`).

### New Features (Ported from 'careless' 1.2.2)

- `longstring()`: Computes the maximum (and optionally average) length of consecutive identical responses across items.
- `irv()`: Computes intra-individual response variability as the standard deviation of responses across selected items; unlike `longstring()`, it does not measure consecutive runs and does not depend on item order.
- `evenodd()`: Computes the even-odd consistency score based on subscale correlations.
- `psychsyn()`: Computes within-person correlation across psychometric synonym item pairs.
- `psychant()`: Computes within-person correlation across psychometric antonym item pairs.
- `psychsyn_critval()`: Computes and ranks correlations among item pairs to help set critical values.
- `mahad()`: Computes Mahalanobis distance using `psych::outlier` and flags potential outliers.
- Datasets: `careless_dataset` and `careless_dataset2` provide simulated response datasets for demonstration and testing.

---

# Satisficing 0.1.0

Initial release of `Satisficing`.

- `stline()`: Detects straight-line response patterns in survey data.
- `matching()`: Evaluates a logical expression row-wise within a data frame.
- `rawnn()`: Displays column names with 1-based indices.
