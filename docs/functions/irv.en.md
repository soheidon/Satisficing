[English](irv.en.md) | [日本語](irv.ja.md)

# `irv()`: Intra-individual Response Variability

## 1. Overview

`irv()` quantifies the variability of each respondent's item responses using a standard deviation. This measure is called intra-individual response variability (IRV) and describes how much the respondent varies their response categories across items.

Respondents who answer “3” to every item have less response variability than respondents who use “1,” “3,” and “5.” Dunn et al. (2018) examined IRV as an indicator for assessing insufficient effort responding (IER). A low IRV indicates little variation in response values, whereas a high IRV indicates a wider spread. High variability has also been used as a clue when examining possible random responding.

Response variation can also reflect respondents' actual characteristics and item content. Neither a low nor a high IRV, by itself, establishes careless responding.

## 2. Calculation

IRV is the **sample standard deviation** of a respondent's responses to the selected items. Let \(x_{ij}\) be respondent \(i\)'s valid response to item \(j\), \(n_i\) the number of valid responses, and \(\bar{x}_i\) their mean. Then:

\[
IRV_i=\sqrt{\frac{1}{n_i-1}\sum_{j=1}^{n_i}(x_{ij}-\bar{x}_i)^2}.
\]

The denominator is \(n_i-1\). The implementation applies R's `sd()` function to each respondent's row.

| Respondent | Q1 | Q2 | Q3 | Q4 | Q5 | IRV |
|---|---:|---:|---:|---:|---:|---:|
| A | 3 | 3 | 3 | 3 | 3 | 0.000 |
| B | 3 | 3 | 4 | 3 | 4 | 0.548 |
| C | 1 | 2 | 3 | 4 | 5 | 1.581 |
| D | 1 | 5 | 1 | 5 | 3 | 2.000 |

Respondent A has an IRV of 0 because all responses are identical. B uses only 3 and 4; C and D use values across a wider range and have larger IRVs. This does not establish that C or D responded carelessly.

## 3. Basic usage

```r
irv(x, na.rm = TRUE, split = FALSE, num.split = 3)
```

| Argument | Description |
|---|---|
| `x` | A matrix or data frame with respondents in rows and items in columns |
| `na.rm` | Whether to remove missing values when calculating the standard deviation; defaults to `TRUE` |
| `split` | Whether to calculate IRV for item subsets in addition to all items |
| `num.split` | Number of item subsets; defaults to 3 |

### 3.1 IRV across all items

```r
library(Satisficing)

df <- data.frame(
  Q1 = c(3, 3, 1, 1),
  Q2 = c(3, 3, 2, 5),
  Q3 = c(3, 4, 3, 1),
  Q4 = c(3, 3, 4, 5),
  Q5 = c(3, 4, 5, 3)
)

irv(df)
```

The function returns a numeric vector with one value per respondent:

```text
[1] 0.0000000 0.5477226 1.5811388 2.0000000
```

To add IRV to the data frame, pass only the response items and assign the result:

```r
df$irv <- irv(df)
```

Including respondent IDs or demographic variables by mistake means the result no longer describes only the variability of the intended item responses.

## 4. IRV for item subsets

With `split = TRUE`, the function calculates IRV for all items and for subsets formed from column positions. This can help examine whether response variability changes across parts of a questionnaire.

```r
result <- irv(careless_dataset, split = TRUE, num.split = 4)
head(result)
```

The returned data frame has an `irvTotal` column for all items and columns such as `irv1`, `irv2`, and so on for the subsets. For example, you can compare the first and last parts:

```r
boxplot(
  result$irv1,
  result$irv4,
  names = c("First", "Last"),
  ylab = "IRV"
)
```

The implementation partitions column positions using `cut(..., breaks = num.split)`. When the number of items is not divisible by the number of subsets, subset sizes may differ. Each subset's IRV is calculated from that subset; `irvTotal` is the standard deviation across all items, not the average of the subset IRVs.

Because the partition depends on column order, arrange columns in the actual presentation order when examining response changes through the questionnaire. Differences across subsets can also reflect differences in item content, response-category distributions, or scale structure—not only a change in response quality.

## 5. Missing values

The default `na.rm = TRUE` calculates the standard deviation from non-missing responses. For `3, 3, NA, 4, 4`, for example, the function calculates `sd(c(3, 3, 4, 4))`, which is approximately 0.577.

With `na.rm = FALSE`, a respondent with missing values receives `NA`. The result is also `NA` when there is only one or no valid response because a standard deviation cannot be calculated.

| Response pattern | `na.rm = TRUE` | `na.rm = FALSE` |
|---|---:|---:|
| `3, 3, 3, 3` | 0 | 0 |
| `3, 3, 4, 4` | About 0.577 | About 0.577 |
| `3, 3, NA, 4` | About 0.577 | NA |
| `3, NA, NA, NA` | NA | NA |
| `NA, NA, NA, NA` | NA | NA |

When missing values are removed, respondents may have different numbers of valid items. For datasets with substantial missingness, check the number of valid responses as well.

## 6. Interpreting low IRV

A low IRV indicates little variation in response values. For example, `3 3 3 3 3 3 3 3` has an IRV of 0. IRV can also be low when a respondent mostly uses the same value, as in `3 3 3 4 3 3 3 4`.

Dunn et al. (2018) considered low IRV as a clue for identifying overly consistent or straightlining responses. However, IRV may be low for attentive respondents when similar items measuring the same construct are presented together. Do not exclude respondents solely because they have a low IRV.

## 7. Interpreting high IRV

A high IRV means that responses span a wider range. For example, `1 5 1 5 1 5 1 5` has a high IRV.

Marjanovic et al. (2015) examined the inter-item standard deviation (ISD) for distinguishing random from conscientious respondents and reported larger ISDs among random responders. Their study also calculated ISD within subscales and used aggregated values across subscales. Do not treat those aggregated ISD values as identical to `irv()`, which can calculate one standard deviation across all selected items, including items from multiple scales.

**High IRV is not synonymous with random responding.** Respondents with genuinely different attitudes toward different items can also have high IRV. IRV is also independent of item order: `1 1 5 5` and `1 5 1 5` have the same response distribution and therefore the same IRV. Use another indicator, such as `longstring()`, to examine run lengths or the order in which responses change.

## 8. Difference from `longstring()`

| Feature | `irv()` | `longstring()` |
|---|---|---|
| What it measures | Variation in response values | Length of runs of identical responses |
| Calculation | Standard deviation | Run lengths |
| Depends on item order | No | Yes |
| All responses identical | IRV = 0 | Longstring = number of items |
| Subset analysis | `split = TRUE` | Select item columns and calculate separately |

For example, `3 3 3 3 4 4 4 4` and `3 4 3 4 3 4 3 4` have the same response frequencies and therefore the same IRV, but their Maximum Longstring values are 4 and 1. Using both indicators distinguishes response variability from the continuity of the response sequence.

## 9. Thresholds and cautions

`irv()` calculates a standard deviation; it does not provide a fixed threshold for classifying insufficient effort responding. Interpretation depends on the numeric range of response categories, item correlations, item content, scale structure, the number of valid responses, and the composition of subsets when splitting is used.

IRV uses the numeric distances assigned to response categories. Interpret results carefully when those distances do not have a meaningful interpretation or when items from different scales are combined. For reverse-keyed items, clarify whether the goal is to describe response behavior or variability in scores after recoding.

## 10. Use in research

IRV is one of several clues that can be used to examine response quality. Dunn et al. (2018) studied IER indicators including low IRV, while Marjanovic et al. (2015) examined identifying random responses using high item-response variability. Low and high IRV focus on different response patterns; state which one the analysis evaluates and why.

For reproducibility, report the item set, item order, whether subsets were used, how missing data were handled, and the rationale for any threshold. If respondents are excluded, report the number excluded and the results before and after exclusion.

## 11. References

Dunn, A. M., Heggestad, E. D., Shanock, L. R., & Theilgard, N. (2018). Intra-individual response variability as an indicator of insufficient effort responding: Comparison to other indicators and relationships with individual differences. *Journal of Business and Psychology, 33*(1), 105–121. [https://doi.org/10.1007/s10869-016-9479-0](https://doi.org/10.1007/s10869-016-9479-0)

Marjanovic, Z., Holden, R., Struthers, W., Cribbie, R., & Greenglass, E. (2015). The inter-item standard deviation (ISD): An index that discriminates between conscientious and random responders. *Personality and Individual Differences, 84*, 79–83. [https://doi.org/10.1016/j.paid.2014.08.021](https://doi.org/10.1016/j.paid.2014.08.021)

Yentes, R., & Wilhelm, F. (2023). *careless: Procedures for computing indices of careless responding* (R package version 1.2.2). [CRAN](https://CRAN.R-project.org/package=careless)

`Satisficing` v0.2.0's `irv()` was ported from `careless` 1.2.2. Cite Dunn et al. (2018) and Marjanovic et al. (2015) for methodological context, and Yentes and Wilhelm (2023) for the source implementation.

---

[User guide](../guide.en.md) | [ユーザーガイド](../guide.ja.md)
