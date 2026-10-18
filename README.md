[English](https://github.com/soheidon/Satisficing/blob/main/README.md) | [日本語](https://github.com/soheidon/Satisficing/blob/main/docs/README-ja.md) | [User Guide](https://github.com/soheidon/Satisficing/blob/main/docs/guide.en.md) | [日本語ガイド](https://github.com/soheidon/Satisficing/blob/main/docs/guide.ja.md)

# Satisficing

Tools for Detecting Indicators of Survey Satisficing.

`Satisficing` provides utilities for inspecting survey response patterns and evaluating row-wise logical conditions. It includes original detection tools as well as careless and insufficient effort responding indices ported from the CRAN package `careless` (version 1.2.2). These functions help identify indicators for further review; they do not determine satisficing on their own.

## Features

### Original Tools
- `stline()` flags rows with identical responses across selected columns. It supports logical, numeric, character, and factor columns of a consistent type; rows with fewer than two non-missing responses are marked `NA`.
- `matching()` evaluates a logical expression in the context of a data frame and adds an integer indicator (`1L`, `0L`, or `NA_integer_`). The expression must return exactly one logical value per row.
- `rawnn()` prints column names with their 1-based indices.

### Ported Indices from 'careless'
- `longstring()` identifies the longest uninterrupted string of identical responses (and optionally the average length).
- `irv()` computes intra-individual response variability as the standard deviation of responses across selected items; it does not depend on item order. `longstring()` measures consecutive runs of identical responses.
- `evenodd()` computes the even-odd consistency score based on subscale correlations.
- `psychsyn()` computes within-person correlation across psychometric synonym item pairs.
- `psychant()` computes within-person correlation across psychometric antonym item pairs.
- `psychsyn_critval()` computes and ranks correlations among item pairs to help set critical values.
- `mahad()` computes Mahalanobis distance using `psych::outlier` and flags potential outliers.
- Datasets: `careless_dataset` and `careless_dataset2` provide simulated response datasets for demonstration and testing.

### Straightlining Measures (Kim et al., 2019 / straightliner conventions)
- Canonical straightliner API:
  - `meanRootPairs()`: Computes sample-normalized Mean Root of Pairs (MRP) using the Kim et al. (2019) formula.
  - `maxIdenticalRating()`: Computes Maximum Identical Rating (MIR), the proportion of questions with the most frequent response.
  - `question_sd()`: Computes standard deviation across the question battery for each respondent.
  - `scale_point_variation()`: Computes Scale Point Variation (SPV) across response categories.
  - `nondiff()`: Computes simple nondifferentiation as a logical vector (`TRUE` if all responses in a row are identical).
  - `straightlining()`: Multi-metric individual straightlining analysis returning selected indicators (`mrp`, `mir`, `qsd`, `spv`, `nondiff`).
  - `straightlining_qset()`: Summary aggregation across multiple question sets (batteries) with formatted output.
- Legacy wrappers:
  - `mrp()`, `mir()`, `spv()`: Retained for backward compatibility; append the calculated indicator as a column to the input data frame.
- Together with `stline()` (original integer indicator for identical observed responses) and `irv()` (row-wise standard deviation), `Satisficing` covers all five straightlining measures discussed in Kim et al. (2019).

### Semantic Inconsistency
- `semantic_inconsistency()`: Computes response inconsistency across user-specified item pairs with expected directional relationships (`same` or `opposite`), normalized to the theoretical response scale range [0, 1].

### Respondent Screening and Filtering
- `flag_respondents()`: Evaluates user-specified logical rules across survey quality indicators with data-masking and automatic/explicit ID retention.
- `filter_respondents()`: Filters survey response data based on quality flags using explicit ID matching, three-valued logic aggregation (`any`, `all`, `at_least`), and structured audit logging.

## Installation

Install the package using `remotes`:

```r
install.packages("remotes")
remotes::install_github("soheidon/Satisficing")
```

## Usage

```r
library(Satisficing)

# Example survey responses
responses <- data.frame(
  q1 = c(1, 1, 1, 2, NA),
  q2 = c(1, 1, 2, 2, NA),
  q3 = c(1, 2, 3, 2, 1)
)

# Straight-line detection (original tool)
stline(responses, c("q1", "q2", "q3"))

# Semantic inconsistency across item pairs
item_pairs <- data.frame(
  item1 = c("q1", "q1"),
  item2 = c("q2", "q3"),
  relation = c("same", "opposite"),
  stringsAsFactors = FALSE
)
semantic_scores <- semantic_inconsistency(
  responses, item_pairs,
  scale_min = 1, scale_max = 5
)

# Canonical straightliner functions (Kim et al., 2019)
straightlining(responses, varnames = c("q1", "q2", "q3"))
maxIdenticalRating(responses, varnames = c("q1", "q2", "q3"))
meanRootPairs(responses, varnames = c("q1", "q2", "q3"))
nondiff(responses, varnames = c("q1", "q2", "q3"))

# Logical condition matching
respondents <- data.frame(
  age = c(25, 17, 30, NA),
  employed = c(TRUE, FALSE, TRUE, TRUE)
)
matching(respondents, age >= 18, result_col = "adult")

# Inspect column numbers
rawnn(iris)

# Careless responding indices
data(careless_dataset)
ls_scores <- longstring(careless_dataset)
irv_scores <- irv(careless_dataset)
syn_scores <- psychsyn(careless_dataset, critval = 0.60)
maha_dist <- mahad(careless_dataset, plot = FALSE)
```

## Reference manual

The package reference manual is available as [`Satisficing.pdf`](https://github.com/soheidon/Satisficing/releases/latest/download/Satisficing.pdf) on the [GitHub Releases page](https://github.com/soheidon/Satisficing/releases).

## Acknowledgements and Third-Party Code

`Satisficing` incorporates functions, datasets, and documentation ported from the R package `careless` (version 1.2.2), originally created by Richard Yentes and Francisco Wilhelm.

- **Ported components**: `longstring`, `irv`, `evenodd`, `psychsyn`, `psychant`, `psychsyn_critval`, `mahad`, `careless_dataset`, and `careless_dataset2`.
- **License**: The ported components are licensed under the MIT License (c) 2016 Richard Yentes.
  - Source tree: [`inst/licenses/careless-MIT.txt`](inst/licenses/careless-MIT.txt) and [`inst/COPYRIGHTS`](inst/COPYRIGHTS).
  - Installed package: `licenses/careless-MIT.txt` and `COPYRIGHTS`.
- **Disclaimer**: `Satisficing` is an independent package developed and maintained by Sohei IDE. It is not affiliated with, nor endorsed by, the authors of `careless`.

## References

- Kim, Y., Dykema, J., Stevenson, J., Black, P., & Moberg, D. P. (2019). Straightlining: Overview of Measurement, Comparison of Indicators, and Effects in Mail–Web Mixed-Mode Surveys. *Social Science Computer Review*, 37(2), 214–233. <https://doi.org/10.1177/0894439317752406>

## License

GPL (>= 2). See [`LICENSE.md`](https://github.com/soheidon/Satisficing/blob/main/LICENSE.md) for the full license text and copyright notice.
