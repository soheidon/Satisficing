[English](guide.en.md) | [日本語](guide.ja.md)

# Satisficing User Guide

**For version: 0.2.0**
**An explanatory guide, separate from the official reference manual**
[GitHub repository](https://github.com/soheidon/Satisficing)

## 1. About this guide

`Satisficing` is an R package for examining indicators of satisficing—the tendency to answer with less cognitive effort than a question requires—as well as response patterns associated with careless or insufficient-effort responding. Version 0.2.0 includes three original functions (`stline()`, `matching()`, and `rawnn()`) and seven functions ported from `careless` v1.2.2.

This guide does not repeat the argument lists from the help pages. Instead, it explains what each function can examine, how to read its results, and what its limitations are. **No single indicator establishes that a respondent was careless or dishonest.** Interpret results in light of the study purpose, item content, presentation order, scale properties, and other relevant information.

### 1.1 Which function should I use?

| What you want to know | Function | Main result |
|---|---|---|
| Whether responses are identical across selected items | [`stline()`](functions/stline.en.md) | Adds a 1 / 0 / NA flag |
| The maximum number of consecutive identical responses | [`longstring()`](functions/longstring.en.md) | Maximum and average run lengths |
| How much responses vary within each respondent | [`irv()`](functions/irv.en.md) | Within-respondent standard deviation |
| Whether odd- and even-item subscales are consistent | `evenodd()` | Within-respondent correlation |
| Whether responses to positively correlated item pairs are consistent | `psychsyn()` | Within-respondent correlation |
| Whether responses to negatively correlated item pairs are consistent | `psychant()` | Within-respondent correlation |
| Which item pairs to use for a consistency check | `psychsyn_critval()` | A table of item pairs and correlations |
| Whether a respondent is multivariately unusual relative to others | `mahad()` | Squared Mahalanobis distance and a flag |
| Whether rows meet a user-defined logical condition | `matching()` | Adds a 1 / 0 / NA flag |
| Column names and their column numbers | [`rawnn()`](functions/rawnn.en.md) | Console output |

### 1.2 Installation and example datasets

```r
# If the package is not installed (GitHub version)
# install.packages("remotes")
# remotes::install_github("soheidon/Satisficing")

library(Satisficing)

data("careless_dataset", package = "Satisficing")
data("careless_dataset2", package = "Satisficing")

dim(careless_dataset)   # 200 respondents x 50 items
dim(careless_dataset2)  # 1000 respondents x 100 items
```

`careless_dataset` is simulated data containing ordinary responses, straightlining, and random responses. It consists of 10 subscales with 5 items each. `careless_dataset2` simulates ordinary responses, long strings of identical responses, and generally careless responding; it consists of 10 subscales with 10 items each. Neither dataset comes from an actual survey.

### 1.3 Basic input structure

For most functions, rows should represent respondents and columns should represent items. Pass only the items to be analyzed; do not include respondent IDs, timestamps, or other metadata. Column order matters especially for `longstring()` and split IRV. If you want to assess the sequence of responses as presented, reverse-scoring items before analysis will not preserve the sequence of response options actually selected.

The examples below use this small dataset where needed:

```r
answers <- data.frame(
  id = 1:4,
  q1 = c(3, 3, 1, 4),
  q2 = c(3, 3, 2, 4),
  q3 = c(3, 4, 3, 4),
  q4 = c(3, 4, 4, 2),
  q5 = c(3, 4, 5, 2)
)
items <- answers[paste0("q", 1:5)]
```

## 2. `stline()`: Are responses identical across selected items?

**Purpose:** For each respondent, checks whether all non-missing responses across the selected items are identical.

```r
flagged <- stline(
  answers,
  columns = paste0("q", 1:5),
  result_column_name = "straight_line"
)
flagged[c("id", "straight_line")]
```

`stline()` returns the original data frame with an integer column added. `1` means there are at least two non-missing responses and they are all identical; `0` means the observed responses differ; `NA` means there are only zero or one non-missing responses. In this example, respondent 1 answered 3 to every item, so the result is `1`. Respondent 2 used both 3 and 4, so the result is `0`.

Use `exclude_values` to exclude a particular response value from being counted as a match:

```r
stline(answers, paste0("q", 1:5), exclude_values = 3)
```

With this setting, a respondent who answered 3 to every item receives `0`. Excluding a response such as “neutral” is possible, but the rationale should be stated in the research plan.

**Interpretation:** Identical responses to all five items may be a natural result of the item content. Also, a pattern such as `3333344444`, where responses change partway through, is not detected as a single identical response pattern. Use `longstring()` to examine such runs.

## 3. `longstring()`: How long are runs of identical responses?

See the detailed [`longstring()` guide](functions/longstring.en.md).

**Purpose:** Examines how many adjacent responses are identical in the order of the items.

```r
longstring(items)
longstring(items, avg = TRUE)
```

By default, the function returns a vector giving each respondent’s **maximum run length of identical responses**. With `avg = TRUE`, it returns a data frame with `longstr` (the longest run) and `avgstr` (the average length of the runs of identical responses).

For example, in `3,3,3,4,4,4,4,3`, the run lengths are 3, 4, and 1. The maximum run length is 4, and the average run length is (3 + 4 + 1) / 3 = 2.67. **All responses do not have to be the same.**

```r
pattern <- data.frame(
  q1 = 3, q2 = 3, q3 = 3, q4 = 4,
  q5 = 4, q6 = 4, q7 = 4, q8 = 3
)
longstring(pattern, avg = TRUE)
```

**Interpretation:** The result changes when item order changes. Analyze items in the order in which they were presented. For the exact behavior when missing values occur within a sequence, check the implementation for the package version you are using. A long run of identical responses alone does not establish careless responding.

## 4. `irv()`: How much do responses vary within a respondent?

See the detailed [`irv()` guide](functions/irv.en.md).

**Purpose:** Computes the standard deviation of item responses for each respondent (intra-individual response variability; IRV).

```r
irv(items)
irv(careless_dataset, split = TRUE, num.split = 4)
```

Lower values mean that a respondent’s answers are more similar; an extremely low value may indicate repeated use of the same response. Conversely, an extremely high value may be a candidate indicator of random responding. However, genuine variation in responses to the questions also affects IRV.

With `split = TRUE`, the function returns `irvTotal` for all items plus `irv1`, `irv2`, and so on for the requested number of consecutive item subsets. This can help identify, for example, a sharp decrease in response variation near the end of a survey. The default is `na.rm = TRUE`, which excludes missing values from the calculation.

```r
v <- irv(careless_dataset, split = TRUE, num.split = 4)
boxplot(v$irv1, v$irv2, v$irv3, v$irv4,
        names = paste0("Part ", 1:4), ylab = "IRV")
```

**Interpretation:** Carefully consider what the values mean when items use different scoring scales or combine multiple subscales. Scoring decisions, including reverse-scoring, can also affect interpretation.

## 5. `evenodd()`: Consistency between odd- and even-numbered items

**Purpose:** Within each factor, forms scores from odd- and even-numbered items and calculates the within-respondent correlation between those score series. It does not simply correlate all odd-numbered columns with all even-numbered columns in the questionnaire.

```r
eo <- evenodd(careless_dataset, factors = rep(5, 10))
eo_diag <- evenodd(careless_dataset, factors = rep(5, 10), diag = TRUE)
head(eo_diag)
```

`factors = rep(5, 10)` indicates that the data contain 10 consecutive factors (subscales), each with 5 items. With `diag = FALSE`, the function returns a numeric vector of correlations. With `diag = TRUE`, it returns a data frame containing `eo_cor` and `eo_missing`. The official manual describes `eo_missing` as the number of non-missing odd/even pairs available for the calculation. Do not interpret this column name as simply the number of missing responses.

**Interpretation:** The factor boundaries and item order must be specified correctly. A low correlation alone does not establish careless responding; also consider the subscale structure and reverse-scored items.

## 6. `psychsyn_critval()`: Find item pairs for consistency checks

**Purpose:** Calculates correlations between item pairs in the dataset. It is a helper function to use before `psychsyn()` or `psychant()`.

```r
pairs_pos <- psychsyn_critval(careless_dataset)
head(pairs_pos)

pairs_neg <- psychsyn_critval(careless_dataset2, anto = TRUE)
head(pairs_neg)
```

The returned data frame has columns `var1`, `var2`, and `cor`. With `anto = FALSE`, inspect item pairs with strong positive correlations; with `anto = TRUE`, inspect pairs with strong negative correlations.

**Interpretation:** These are correlations estimated from the data. The function does not determine whether items are semantically synonymous or antonymous. Results may be unstable when there are few candidate pairs or the sample is small.

## 7. `psychsyn()`: Consistency across positively correlated item pairs

**Purpose:** Selects item pairs that are strongly positively correlated in the full sample, then summarizes how consistently each respondent answered those pairs using a within-respondent correlation.

```r
syn <- psychsyn(careless_dataset, critval = 0.60)
syn_diag <- psychsyn(careless_dataset, critval = 0.60, diag = TRUE)
head(syn_diag)
```

`critval = 0.60` is the correlation threshold used to select item pairs. With `diag = FALSE`, the function returns a vector of correlation scores. With `diag = TRUE`, it returns a data frame containing `numPairs` (the number of item pairs used) and `cor` (the consistency score).

The default is `resample_na = TRUE`. According to the official manual, when a score is `NA`, the function attempts resampling. For reproducible analyses, check this argument’s behavior and set a random seed if appropriate.

**Interpretation:** Results depend on the number of synonym pairs, item content, and the correlation threshold. Avoid interpreting scores when very few item pairs can be calculated.

## 8. `psychant()`: Consistency across negatively correlated item pairs

**Purpose:** Examines respondent consistency for item pairs that are strongly negatively correlated in the full sample. It is a convenient wrapper around `psychsyn(..., anto = TRUE)`.

```r
ant <- psychant(careless_dataset2, critval = -0.60)
ant_diag <- psychant(careless_dataset2, critval = -0.60, diag = TRUE)
head(ant_diag)
```

With `diag = TRUE`, the returned data frame contains `numPairs` and `cor`. The default `critval` is `-0.6`. Do not confuse this with the positive correlation threshold used for `psychsyn()`.

**Interpretation:** Negative correlation does not necessarily mean that two items are semantic antonyms. Reverse-coding and the factor structure of the scale may change what a negative correlation means.

## 9. `mahad()`: Find multivariately unusual response patterns

**Purpose:** Identifies respondents whose response patterns are unusual relative to other respondents across a set of items. It calculates Mahalanobis distance using `psych::outlier()`.

```r
# A QQ plot is drawn by default
out <- mahad(careless_dataset, plot = FALSE)
out_flag <- mahad(careless_dataset, plot = FALSE,
                  flag = TRUE, confidence = 0.99)
head(out_flag)
```

When `flag = FALSE`, the function returns a numeric vector of **squared** Mahalanobis distances (`d_sq`). When `flag = TRUE`, it returns a data frame containing `d_sq` and the logical variable `flagged`. `confidence` is the confidence level used for flagging; its default is `0.99`. The default for `plot` is `TRUE`, so set it explicitly to `FALSE` if you do not need a plot.

**Interpretation:** A large distance indicates an unusual response pattern, not necessarily careless responding. Respondents with distinctive personality profiles may also be flagged. Consider the number of items and respondents, the correlation structure, and missing data.

## 10. `matching()`: Flag rows using a user-defined logical condition

**Purpose:** Makes it easier to identify respondents who meet a condition defined by the researcher. It is a general-purpose function that evaluates a logical expression row by row in a data frame, not an automatic satisficing detector.

```r
x <- data.frame(id = 1:4, a = c(1, 2, 3, NA), b = c(3, 2, 1, 4))
matching(x, a > b)
matching(x, a == b, result_col = "same_answer")
```

The function returns the original data frame with an integer column added. The result is `1` when the condition is `TRUE`, `0` when it is `FALSE`, and `NA` when it is `NA`. The expression can refer directly to column names in the data frame.

For example, you can explore combinations such as a high score on one item and a low score on another. Whether such a combination is contradictory depends on the item content. A condition being met does not mean the response is careless.

## 11. `rawnn()`: Inspect column numbers and names

See the detailed [`rawnn()` guide](functions/rawnn.en.md).

**Purpose:** Prints each data-frame column’s 1-based position and name to the console.

```r
rawnn(answers)
```

The output looks like `1: id`, `2: q1`, and so on. Use it to check column names or identify the range of items to analyze. The function does not modify the data and returns an invisible `NULL`.

## 12. Example with a real questionnaire: a 35-item BFI

Suppose a data frame named `bfi_data` contains 35 items named `BFI1` through `BFI35`. **These are example variable names; the package does not include BFI data.**

```r
library(Satisficing)

bfi_items <- paste0("BFI", 1:35)
x <- bfi_data[bfi_items]  # Use the actual presentation order

# Check for completely identical responses
result <- stline(bfi_data, columns = bfi_items)

# Maximum and average run lengths of identical responses
runs <- longstring(x, avg = TRUE)
result$longstr <- runs$longstr
result$avgstr <- runs$avgstr

# Within-respondent response variability
result$irv <- irv(x)

# Inspect the results
head(result[c("straight_line", "longstr", "avgstr", "irv")])
```

**How to read this:** If all 35 responses are 3, `straight_line` is 1 and the maximum run length is 35. If the first 20 responses are 3 and the next 15 are 4, `straight_line` is 0 but the maximum run length is 20. If 3 and 4 alternate, the maximum run length is 1. By contrast, the within-respondent standard deviation does not depend on the order of responses when the response frequencies are the same.

**Important:** Keep in mind that the BFI measures multiple personality factors, includes reverse-keyed items, and may be presented in different orders across studies. A longstring across all 35 items and factor-specific indicators address different questions.

## 13. Reporting results and other considerations

### 13.1 Use multiple indicators

Completely identical responses, long runs of identical responses, low IRV, high IRV, low consistency, and multivariate outliers each capture different aspects of response patterns. Rather than automatically excluding respondents based on one score or a universal cutoff, inspect the indicator distributions and item content.

### 13.2 Decisions to make before analysis

- Which items or subscales will be included in each indicator?
- Will the analysis use the item presentation order, and will items be analyzed before or after scoring and reverse-scoring?
- How will missing responses be handled?
- Which indicators will be used, and for what purpose?
- Will potentially problematic respondents be excluded, or will results be compared in a sensitivity analysis?

### 13.3 Example wording for a paper

> For an exploratory assessment of response quality, we used the R package Satisficing (version 0.2.0) to calculate completely identical responses across selected items (`stline`), the maximum run length of identical responses (`longstring`), and within-respondent standard deviation (`irv`). These were treated as response-pattern indicators, not definitive diagnoses of careless responding.

In an actual paper, report the functions used, the analyzed items, missing-data handling, the rationale for any thresholds, the number of exclusions, and sensitivity analyses.

## 14. References, sources, and licenses

- Johnson, J. A. (2005). Ascertaining the validity of individual protocols from web-based personality inventories. *Journal of Research in Personality, 39*, 103–129. https://doi.org/10.1016/j.jrp.2004.09.009
- Meade, A. W., & Craig, S. B. (2012). Identifying careless responses in survey data. *Psychological Methods, 17*, 437–455. https://doi.org/10.1037/a0028085
- Dunn, A. M., Heggestad, E. D., Shanock, L. R., & Theilgard, N. (2018). Intra-individual response variability as an indicator of insufficient effort responding. *Journal of Business and Psychology, 33*, 105–121.
- Marjanovic, Z., Holden, R., Struthers, W., Cribbie, R., & Greenglass, E. (2015). The inter-item standard deviation (ISD). *Personality and Individual Differences, 84*, 79–83.
- Yentes, R., & Wilhelm, F. `careless` R package, version 1.2.2. https://CRAN.R-project.org/package=careless

The `evenodd()`, `irv()`, `longstring()`, `mahad()`, `psychsyn()`, `psychant()`, and `psychsyn_critval()` functions, along with the two example datasets in v0.2.0, were ported from `careless` v1.2.2. See the files included in the repository for copyright and license notices. This guide explains how to use the package; it does not replace source-code license notices.

---

*This guide was prepared based on the official reference manual included with Satisficing v0.2.0 (2026-10-17 edition). For definitive behavior, consult `?function_name` and the source code for the package version you are using.*
