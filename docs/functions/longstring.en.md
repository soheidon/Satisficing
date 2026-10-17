[English](longstring.en.md) | [日本語](longstring.ja.md)

# `longstring()`: Maximum and Average Runs of Identical Responses

## 1. Overview

`longstring()` measures how many consecutive items receive the same response category.

In questionnaires, respondents may select the same option across several consecutive items. This response pattern, often called straightlining, has been studied as a possible indicator of insufficient effort responding (IER) or careless responding. A long run alone does not establish that a response is careless.

For each respondent, `longstring()` can calculate two indices:

- **Maximum Longstring**: the number of items in the longest uninterrupted run of identical responses.
- **Average Longstring**: the mean length of all consecutive runs.

Consider the following responses to 12 items:

```text
Item     01 02 03 04 05 06 07 08 09 10 11 12
Response  3  3  3  3  4  4  4  3  3  3  3  5
          └── 4 ──┘ └─3─┘ └── 4 ──┘ 1
```

The sequence has four runs with lengths 4, 3, 4, and 1. Therefore:

\[
\mathrm{Maximum\ Longstring}=4
\]

\[
\mathrm{Average\ Longstring}=\frac{4+3+4+1}{4}=3
\]

Maximum Longstring describes the longest run. Average Longstring summarizes how long identical responses tend to continue across the sequence.

## 2. How it is calculated

Let respondent \(i\)'s responses in presentation order be

\[
\mathbf{x}_i=(x_{i1},x_{i2},\ldots,x_{ip}),
\]

where \(p\) is the number of selected items. Adjacent equal responses belong to the same run; a different response starts a new run. Suppose the sequence is divided into \(K_i\) runs with lengths

\[
L_{i1},L_{i2},\ldots,L_{iK_i}.
\]

### 2.1 Maximum Longstring

The maximum run length is

\[
LS_{\max,i}=\max_{1\leq k\leq K_i} L_{ik}.
\]

For example, `3 3 3 4 4 3 3 3 3 5` has run lengths 3, 2, 4, and 1, so its Maximum Longstring is 4. If all responses are identical, the value equals the number of selected items.

### 2.2 Average Longstring

Average Longstring is the mean of the run lengths:

\[
LS_{\mathrm{avg},i}=\frac{1}{K_i}\sum_{k=1}^{K_i}L_{ik}.
\]

For a sequence without missing values, this is also \(p/K_i\), because the run lengths sum to the number of items. For example, 10 responses divided into four runs have an Average Longstring of 2.5. Fewer runs generally result in a larger average.

## 3. Basic usage

The function has the following form:

```r
longstring(x, avg = FALSE)
```

| Argument | Description |
|---|---|
| `x` | A matrix or data frame with respondents in rows and items in columns |
| `avg` | Logical value indicating whether to also calculate Average Longstring |

With the default `avg = FALSE`, the function returns a numeric vector of Maximum Longstring values, one per respondent. With `avg = TRUE`, it returns a data frame with two columns:

| Column | Meaning |
|---|---|
| `longstr` | Maximum Longstring |
| `avgstr` | Average Longstring |

### 3.1 Maximum Longstring

```r
library(Satisficing)

df <- data.frame(
  Q1 = c(3, 4, 2),
  Q2 = c(3, 4, 3),
  Q3 = c(3, 4, 2),
  Q4 = c(4, 4, 3),
  Q5 = c(4, 2, 2),
  Q6 = c(4, 2, 3)
)

longstring(df)
```

The three response sequences are `3, 3, 3, 4, 4, 4`, `4, 4, 4, 4, 2, 2`, and `2, 3, 2, 3, 2, 3`. The result is:

```text
[1] 3 4 1
```

### 3.2 Average Longstring

```r
longstring(df, avg = TRUE)
```

| Respondent | Run lengths | `longstr` | `avgstr` |
|---:|---|---:|---:|
| 1 | 3, 3 | 3 | 3.0 |
| 2 | 4, 2 | 4 | 3.0 |
| 3 | 1, 1, 1, 1, 1, 1 | 1 | 1.0 |

Respondents can have different maximum run lengths but the same average run length.

## 4. Why item order matters

The value of `longstring()` depends on item order. Consider these two sequences:

```text
A: 3 3 3 3 4 4 4 4
B: 3 4 3 4 3 4 3 4
```

Both contain four responses of 3 and four responses of 4, but their results differ:

| Sequence | Maximum Longstring | Average Longstring |
|---|---:|---:|
| A | 4 | 4 |
| B | 1 | 1 |

This shows that Longstring measures the continuity of responses, not how frequently each category was used. Use the order in which the items were presented to respondents. If the data-frame columns are in a different order, reorder them before calculation.

For straightlining as a response behavior, use the **original responses before reverse-scoring**. Reverse-scored values may not represent the options respondents actually selected in the questionnaire.

## 5. Difference from `stline()`

`stline()` checks whether responses across all selected items are identical. The functions are related, but measure different patterns.

| Feature | `stline()` | `longstring()` |
|---|---|---|
| Main purpose | Detects identical responses across the selected items as a whole | Measures the length of consecutive runs |
| Output | 0, 1, or NA flag | Run length |
| Depends on item order | No | Yes |
| If responses change partway through | Returns 0 | Calculates the longest run |
| Detects partial straightlining | Not directly | Yes |

For example, with `3 3 3 3 3 4 4 4 4 4`, `stline()` returns 0 while `longstring()` returns 5. Longstring captures a consecutive run even when responses are not identical across the entire item set.

## 6. Missing values

The treatment of missing values affects how consecutive runs are defined. For `3, 3, NA, 3, 3`, treating the missing value as a break gives two runs of 3 with length 2 each.

`Satisficing` v0.2.0's `longstring()` was ported from `careless` 1.2.2. The implementation does not remove missing values; it uses R's `rle()` function. In R, each `NA` is treated as unequal to the preceding value, including another `NA`. Thus, the run lengths for `3, 3, NA, 3, 3` are `2, 1, 1, 2`: Maximum Longstring is 2 and Average Longstring is 1.5.

Do not assume that missing values are omitted before calculation. Restricting an analysis to complete cases avoids this particular behavior, but may affect which respondents remain in the sample.

## 7. Interpreting the results

A larger Maximum Longstring means that the same response category was selected for a longer uninterrupted sequence. A larger Average Longstring means that the runs tend to be longer across the full sequence.

**A large Longstring value does not, by itself, establish careless responding.** Repeated answers can also result from similar item content, respondent characteristics, response-category distributions, or item placement.

The chance of a long identical run depends on the number of items and response categories. A Longstring of 5 across five items does not have the same measurement meaning as a Longstring of 5 across 50 items. Consider item count and content when comparing different item sets or studies.

## 8. Thresholds

`longstring()` calculates run lengths; it does not provide a universal cutoff for classifying respondents as careless. A rule such as flagging Maximum Longstring values of 10 or greater cannot be assumed to apply to every questionnaire.

The probability of coincidental agreement depends on the number of items, response categories, correlations among items, and response distributions. Choose and justify any threshold in light of the study design. Maximum Longstring describes only the single longest run, so using Maximum and Average Longstring together may provide a broader description of the response sequence.

## 9. Use in research

Longstring is one of several possible indicators for evaluating response quality. Meade and Craig (2012) discuss multiple approaches to identifying careless responses and the limitations of relying on a single indicator.

For respondents with large Longstring values, consider other evidence such as within-respondent response variability (IRV), item consistency, and logically inconsistent answers. In research reports, state the number and presentation order of the analyzed items, whether Maximum or Average Longstring was used, how missing values were handled, and the rationale for any threshold. If respondents are excluded, report the number excluded and results before and after exclusion.

## 10. References

Johnson, J. A. (2005). Ascertaining the validity of individual protocols from web-based personality inventories. *Journal of Research in Personality, 39*(1), 103–129. https://doi.org/10.1016/j.jrp.2004.09.009

Meade, A. W., & Craig, S. B. (2012). Identifying careless responses in survey data. *Psychological Methods, 17*(3), 437–455. https://doi.org/10.1037/a0028085

Yentes, R., & Wilhelm, F. (2023). *careless: Procedures for computing indices of careless responding* (R package version 1.2.2). https://CRAN.R-project.org/package=careless

`Satisficing` v0.2.0's `longstring()` was ported from `careless` 1.2.2 by Yentes and Wilhelm. Distinguish the source of the implementation from the methodological references for the index.

---

[User guide](../guide.en.md) | [ユーザーガイド](../guide.ja.md)
