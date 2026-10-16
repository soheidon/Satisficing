# Satisficing

Tools for Detecting Indicators of Survey Satisficing.

`Satisficing` provides utilities for inspecting survey response patterns and evaluating row-wise logical conditions. These functions can help identify indicators for further review; they do not determine satisficing on their own.

## Features

- `stline()` flags rows with identical responses across selected columns. It supports logical, numeric, character, and factor columns of a consistent type; rows with fewer than two non-missing responses are marked `NA`.
- `matching()` evaluates a logical expression in the context of a data frame and adds an integer indicator (`1L`, `0L`, or `NA_integer_`). The expression must return exactly one logical value per row.
- `rawnn()` prints column names with their 1-based indices.

## Installation

Install the released package from GitHub:

```r
install.packages("remotes")
remotes::install_github("soheidon/Satisficing")
```

## Usage

```r
library(Satisficing)

responses <- data.frame(
  q1 = c(1, 1, 1, 2, NA),
  q2 = c(1, 1, 2, 2, NA),
  q3 = c(1, 2, 3, 2, 1)
)

stline(responses, c("q1", "q2", "q3"))

respondents <- data.frame(
  age = c(25, 17, 30, NA),
  employed = c(TRUE, FALSE, TRUE, TRUE)
)
matching(respondents, age >= 18, result_col = "adult")

rawnn(iris)
```

For `stline()`, rows with 0 or 1 non-missing selected values return `NA_integer_`; rows with at least two values return `1L` when all are equal and not excluded, otherwise `0L`. Use `exclude_values` to treat specified response codes as non-matches.

## Reference manual

The package reference manual is available as [`Satisficing.pdf`](https://github.com/soheidon/Satisficing/releases/latest/download/Satisficing.pdf) on the [GitHub Releases page](https://github.com/soheidon/Satisficing/releases).

## License

GPL (>= 2). See [`LICENSE`](LICENSE) for the full license text and copyright notice.

## 日本語

日本語の概要は [README-ja.md](README-ja.md) を参照してください。
