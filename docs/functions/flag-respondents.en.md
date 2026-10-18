[English](flag-respondents.en.md) | [日本語](flag-respondents.ja.md)

# `flag_respondents()`: Create Respondent Flags from Conditions

## 1. Overview

`flag_respondents()` evaluates user-defined logical conditions against a data frame of respondent-level indicators and returns one logical flag column for each condition. For example, after calculating indicators such as longstring or semantic inconsistency, researchers can identify respondents who meet specified screening rules.

The function evaluates conditions and returns flags. It does not automatically exclude respondents or assess whether a cutoff is valid. Treat flags as information for examining response patterns, and base exclusion decisions on a documented rationale and sensitivity analyses.

## 2. Basic Usage

```r
flag_respondents(indicators, ..., id = NULL)
```

| Argument | Description |
|---|---|
| `indicators` | A data frame of respondent-level indicators. Column names must be non-missing, non-empty, and unique. |
| `...` | One or more logical expressions to evaluate. Each must return a logical vector with one value per row. |
| `id` | Name of an identifier column to retain. If `NULL` (the default), an existing `id` column is retained automatically. |

Expressions can refer to columns by name. Named expressions use their supplied names in the output.

```r
library(Satisficing)

indicators <- data.frame(
  id = 1:4,
  longstring = c(12, 5, 15, 3),
  inconsistency = c(0.8, 0.2, 0.9, 0.1)
)

flags <- flag_respondents(
  indicators,
  high_longstring = longstring >= 10,
  high_inconsistency = inconsistency >= 0.75
)
flags
```

The result is a data frame like this:

```text
  id high_longstring high_inconsistency
1  1            TRUE               TRUE
2  2           FALSE              FALSE
3  3            TRUE               TRUE
4  4           FALSE              FALSE
```

## 3. How Conditions Are Evaluated

Expressions are evaluated with `indicators` as the data context. Objects that are not columns are looked up in the environment from which the function was called.

```r
longstring_cutoff <- 10

flags <- flag_respondents(
  indicators,
  longstring >= longstring_cutoff
)
```

If an expression is unnamed, its deparsed expression is used as the output column name. Naming conditions explicitly usually makes analysis code and output easier to read.

Every condition must return a **logical vector** whose length is exactly `nrow(indicators)`. Numeric `0` / `1` values are not converted to logical values, and a length-one result is not recycled across rows; either case causes an error.

## 4. Missing Values

Any `NA` values in a condition result are preserved in the corresponding flag column. For example, comparing a missing indicator can produce an `NA` flag.

```r
indicators_with_missing <- data.frame(
  id = 1:3,
  score = c(0.9, NA, 0.2)
)

flag_respondents(
  indicators_with_missing,
  high_score = score >= 0.75
)
```

Here, `high_score` is `TRUE`, `NA`, and `FALSE`. The function does not turn `NA` into `FALSE` or remove rows. Decide explicitly how downstream analysis should handle missing flags.

## 5. Identifier and Return Value

The function returns a data frame in the same row order as the input. If an identifier is retained, it appears first, followed by one logical column per expression in the order supplied.

- With `id = NULL`, an input column named `id` is retained automatically.
- Set `id = "respondent_id"` to retain a different column. An error is raised if the specified column does not exist.
- If `id` is omitted and there is no `id` column, no identifier is included in the result.
- The function does not check that identifier values are unique. Choose a column that is appropriate as an identifier for your analysis.

Duplicate condition names, empty condition names, and a condition name that conflicts with the retained identifier name cause an error. Input column names must also be unique.

## 6. Using the Flags with Other Functions

`flag_respondents()` creates flags. `filter_respondents()` can then use those flags to filter response data and produce an audit record. Keeping flag creation separate makes it possible to inspect each condition before filtering.

```r
flags <- flag_respondents(
  indicators,
  high_longstring = longstring >= 10,
  high_inconsistency = inconsistency >= 0.75
)

# To filter, specify the aggregation rule and handling of NA decisions.
# filtered <- filter_respondents(
#   survey_data, flags,
#   strategy = "any", id = "id", na_action = "keep"
# )
```

Before passing flags to `filter_respondents()`, ensure the identifier columns correspond to the same respondents. Specify how multiple flags should be combined and how indeterminate decisions caused by missing values should be handled.

## 7. Practical Considerations

- Researchers define the conditions and cutoffs; the function does not supply universal screening criteria.
- Different flags can capture different response patterns. A single flag does not establish careless responding.
- Check how `NA` flags will be handled in subsequent steps.
- In reports, describe the indicators, conditions, cutoffs, and missing-data handling used.

---

[User guide](../guide.en.md) | [日本語ユーザーガイド](../guide.ja.md)
