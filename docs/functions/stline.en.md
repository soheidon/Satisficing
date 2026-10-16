[English](stline.en.md) | [日本語](stline.ja.md)

# `stline()`: Detecting straight-line responses

[User guide](../guide.en.md) | [日本語ユーザーガイド](../guide.ja.md)

## 1. Overview

`stline()` checks whether a respondent gave the same value to all non-missing responses among a selected set of questionnaire items.

Repeatedly selecting the same response category across several items is generally called **straightlining**. In survey research, it has been studied as a possible indicator of reduced cognitive effort, careless responding, or insufficient-effort responding (IER).

Kim et al. (2019) review several measures of straightlining, including *simple nondifferentiation*, which checks whether responses across a battery of items are identical.

`stline()` provides a binary indicator for identical observed responses. Its missing-data behavior and other implementation details mean that it is not identical to Kim et al.'s measure under every condition.

## 2. Decision rule

Let respondent \(i\)'s responses to the selected items be

$$
\mathbf{x}_i=(x_{i1},x_{i2},\ldots,x_{ip}),
$$

where \(p\) is the number of selected items. Let \(V_i\) be the set of non-missing responses and \(n_i\) its size. `stline()` applies the following rule:

$$
S_i=
\begin{cases}
1 & n_i\geq 2 \text{ and } |V_i|=1 \\
0 & n_i\geq 2 \text{ and } |V_i|>1 \\
NA & n_i<2
\end{cases}
$$

Here, \(|V_i|\) means the number of distinct response values after missing values have been removed.

In other words, the result is 1 when at least two valid responses are all identical, 0 when at least two valid responses include different values, and `NA` when there is only one or no valid response.

For example, for four items on a five-point scale:

| Respondent | Q1 | Q2 | Q3 | Q4 | Result |
|---|---:|---:|---:|---:|---:|
| A | 3 | 3 | 3 | 3 | 1 |
| B | 4 | 4 | 4 | 4 | 1 |
| C | 3 | 3 | 4 | 3 | 0 |
| D | 3 | NA | 3 | 3 | 1 |
| E | 3 | NA | NA | NA | NA |
| F | NA | NA | NA | NA | NA |

Respondent D has missing values, but all observed responses are 3, so the result is 1.

Thus, `stline()` detects **identical responses among the observed items**, not necessarily identical responses to every selected item with no missing data.

## 3. Basic usage

The function has the following form:

```r
stline(
  data,
  columns,
  result_column_name = "straight_line",
  exclude_values = NULL
)
```

| Argument | Description |
|---|---|
| `data` | A data frame with respondents in rows and questionnaire items in columns |
| `columns` | Names of the items to evaluate |
| `result_column_name` | Name of the column that will contain the result |
| `exclude_values` | Response values that should not be counted as straightlining |

The following example evaluates four items for five respondents:

```r
library(Satisficing)

df <- data.frame(
  ID = 1:5,
  Q1 = c(3, 4, 3, 2, 1),
  Q2 = c(3, 4, 4, 2, 3),
  Q3 = c(3, 4, 3, 2, 5),
  Q4 = c(3, 4, 3, 4, 2)
)

result <- stline(
  df,
  columns = c("Q1", "Q2", "Q3", "Q4")
)

print(result)
```

The returned data frame has a new `straight_line` column:

| ID | Q1 | Q2 | Q3 | Q4 | straight_line |
|---|---:|---:|---:|---:|---:|
| 1 | 3 | 3 | 3 | 3 | 1 |
| 2 | 4 | 4 | 4 | 4 | 1 |
| 3 | 3 | 4 | 3 | 3 | 0 |
| 4 | 2 | 2 | 2 | 4 | 0 |
| 5 | 1 | 3 | 5 | 2 | 0 |

`stline()` adds the result column without changing the input rows or response values.

## 4. Excluding response values

Use `exclude_values` to prevent an identical response from being counted as straightlining when it consists of a specified value.

For example, to exclude the midpoint category 3 on a five-point scale:

```r
result <- stline(
  df,
  columns = c("Q1", "Q2", "Q3", "Q4"),
  exclude_values = 3
)
```

A respondent who answered 3 to every item will receive 0, while a respondent who answered 4 to every item will receive 1.

You can exclude multiple values:

```r
exclude_values = c(3, 4)
```

This can be useful when a study has a specific reason to exclude identical responses in particular categories.

However, **there is no general rule that straightlining at the midpoint is acceptable while straightlining at an extreme category is not, or vice versa.** Wang and Hau (2025) report that the probability of straightlining can differ across response categories, and that attentive respondents may also repeatedly select the same category.

Choose `exclude_values` based on the study design and analysis purpose. Mechanically excluding particular categories is not recommended.

## 5. Difference from Longstring

Straightlining can be assessed by checking whether all responses across selected items are identical, or by measuring the length of consecutive runs of identical responses. The latter is commonly called Longstring.

Consider a set of 35 responses:

- Q1–Q20: all 3
- Q21–Q35: all 4

The respondent did not give the same response across all 35 items, so `stline()` returns 0. However, the respondent gave the same response for 20 consecutive items, so the maximum Longstring is 20.

| Indicator | Result | What it measures |
|---|---:|---|
| `stline()` | 0 | Whether all selected observed responses are identical |
| `longstring()` | 20 | The longest consecutive run of identical responses |

`stline()` detects identical responses across the selected items as a whole. `longstring()` captures the longest uninterrupted run even when the response changes elsewhere in the sequence.

The two indicators are complementary. `stline()` does not depend on item order: both `3, 3, 4, 4` and `3, 4, 3, 4` return 0. Longstring does depend on order; these sequences have maximum run lengths of 2 and 1, respectively.

## 6. Applying the function to personality questionnaires such as the BFI

In a personality questionnaire such as the Big Five Inventory (BFI), repeatedly selecting the same category across items measuring different traits may warrant further examination.

If the 35 BFI items are stored as `BFI1` through `BFI35`, you can run:

```r
items <- paste0("BFI", 1:35)

result <- stline(
  bfi_data,
  columns = items
)
```

Count the flagged responses with:

```r
table(result$straight_line, useNA = "ifany")
```

Calculate the proportion among respondents for whom the result is available with:

```r
mean(result$straight_line, na.rm = TRUE)
```

This proportion is the share of respondents whose observed responses were identical across the selected 35 items.

The BFI includes items from multiple factors and reverse-keyed items. Selecting the same category throughout may therefore merit closer review. However, identical responses alone do not establish careless responding; a respondent's actual traits or attitudes toward the items may also produce the same category.

When assessing the response behavior of repeatedly selecting the same option, use the **original responses before reverse-scoring**, in general. Values after reverse-scoring may no longer represent the same options the respondent selected on the questionnaire.

## 7. Interpretation cautions

### 7.1 Straightlining is not sufficient evidence of careless responding

Meade and Craig (2012) describe different patterns of careless responding, including random and non-random patterns, which may require different indicators. `stline()` detects one type of non-random response pattern; it does not capture every form of careless responding.

A flagged straightlining pattern is not, by itself, proof that the respondent was inattentive.

### 7.2 Detection depends on the number and content of items

The probability of giving the same response across all items depends on the number of items, the number of response categories, correlations among items, and response distributions.

For example, complete agreement across three items on a five-point scale has a different statistical meaning from complete agreement across 35 items on the same scale. When comparing results across scales or studies, consider the number and content of the selected items.

### 7.3 Choosing the item set matters

The meaning of identical responses differs when evaluating items from different constructs together versus items from a single factor.

For example, answering 4 to all five items measuring one trait may be a natural response pattern. Answering 4 to all 35 items covering several traits or opposing item content may warrant additional review for consistency with the item wording.

### 7.4 Missing data can increase the apparent evidence

`stline()` returns 1 when at least two valid responses are identical, even if the other selected items are missing.

For example, if 33 of 35 items are missing and the remaining two responses are both 3, the result is 1. This follows the function's contract, but it is much weaker evidence than identical responses to all 35 items.

For datasets with substantial missingness, consider restricting analysis to complete cases or reviewing the number of valid responses alongside the indicator.

## 8. Using the function in research

`stline()` can support exploratory assessments of response quality and data cleaning. However, automatically excluding respondents solely because `stline()` flags them is not recommended.

Meade and Craig (2012) emphasize the use of multiple response-quality indicators. Wang and Hau (2025) also discuss the risk of misclassifying straightlining as careless responding without additional evidence.

Consider interpreting `stline()` together with Longstring, within-respondent response variability (IRV), item-response consistency, and other relevant evidence. If respondents are excluded, report the criteria, the number excluded, and how the results change with and without those exclusions.

## 9. References

Johnson, J. A. (2005). Ascertaining the validity of individual protocols from Web-based personality inventories. *Journal of Research in Personality, 39*(1), 103–129. https://doi.org/10.1016/j.jrp.2004.09.009

Kim, Y., Dykema, J., Stevenson, J., Black, P., & Moberg, D. P. (2019). Straightlining: Overview of measurement, comparison of indicators, and effects in mail–web mixed-mode surveys. *Social Science Computer Review, 37*(2), 214–233. https://doi.org/10.1177/0894439317752406

Meade, A. W., & Craig, S. B. (2012). Identifying careless responses in survey data. *Psychological Methods, 17*(3), 437–455. https://doi.org/10.1037/a0028085

Wang, M. D., & Hau, K. T. (2025). In Likert scale, is ticking options consecutively at two ends equally problematic as ticking in the middle? *Journal of Official Statistics, 41*(1), 73–95. https://doi.org/10.1177/0282423X241273455
