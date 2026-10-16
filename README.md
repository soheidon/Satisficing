[English](README.md) | [日本語](README-ja.md)

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
- `irv()` computes the intra-individual response variability (standard deviation across consecutive responses).
- `evenodd()` computes the even-odd consistency score based on subscale correlations.
- `psychsyn()` computes within-person correlation across psychometric synonym item pairs.
- `psychant()` computes within-person correlation across psychometric antonym item pairs.
- `psychsyn_critval()` computes and ranks correlations among item pairs to help set critical values.
- `mahad()` computes Mahalanobis distance using `psych::outlier` and flags potential outliers.
- Datasets: `careless_dataset` and `careless_dataset2` provide simulated response datasets for demonstration and testing.

## Installation

Install the package using `remotes`:

```r
install.packages("remotes")
remotes::install_github("soheidon/Satisficing")
```

## Usage

```r
library(Satisficing)

# Straight-line detection
responses <- data.frame(
  q1 = c(1, 1, 1, 2, NA),
  q2 = c(1, 1, 2, 2, NA),
  q3 = c(1, 2, 3, 2, 1)
)
stline(responses, c("q1", "q2", "q3"))

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

## License

GPL (>= 2). See [`LICENSE.md`](https://github.com/soheidon/Satisficing/blob/main/LICENSE.md) for the full license text and copyright notice.

## 日本語

日本語の概要は [README-ja.md](README-ja.md) を参照してください。
