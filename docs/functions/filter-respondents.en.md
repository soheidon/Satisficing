[English](filter-respondents.en.md) | [日本語](filter-respondents.ja.md)

# `filter_respondents()`: Filter Respondents Using Quality Flags

## 1. Overview

`filter_respondents()` uses respondent-level logical flags to split survey data into retained and excluded respondents. It matches flags to response data by respondent ID, lets you choose how multiple flags are combined and how missing flags are handled, and returns an audit table containing each respondent's decision.

The function applies the rules you specify. It does not determine whether a flag or cutoff is appropriate for a study. Excluding respondents can affect study results, so document the criteria and consider sensitivity analyses comparing results with and without exclusions.

## 2. Basic Usage

```r
filter_respondents(
  data,
  flags,
  strategy = c("any", "all", "at_least"),
  n = NULL,
  id = NULL,
  na_action = c("error", "keep", "exclude")
)
```

| Argument | Description |
|---|---|
| `data` | The original survey response data frame. |
| `flags` | A data frame with an ID column and one or more logical flag columns. Flag names cannot use reserved audit column names. |
| `strategy` | How to combine flags: `"any"`, `"all"`, or `"at_least"`. |
| `n` | The minimum number of `TRUE` flags required for exclusion with `strategy = "at_least"`. Use `NULL` for the other strategies. |
| `id` | The ID column name present in both data frames. If `NULL`, a shared column named `id` is used. |
| `na_action` | How to handle an indeterminate (`NA`) aggregate decision: `"error"` (default), `"keep"`, or `"exclude"`. |

## 3. Matching by ID

`data` and `flags` are matched using an ID column present in both. The function does not join rows by position alone. ID values must be non-missing and unique in both inputs, have the same type and class, and contain exactly the same set of values.

```r
survey <- data.frame(
  id = 1:4,
  q1 = c(5, 5, 1, 3),
  q2 = c(5, 1, 5, 3)
)

# The flags may be in a different order; matching is performed by ID.
flags <- data.frame(
  id = c(3, 1, 4, 2),
  flag_speed = c(FALSE, FALSE, FALSE, TRUE),
  flag_inconsistent = c(TRUE, FALSE, NA, TRUE)
)
```

By default, both inputs must contain an `id` column. For a different column name, pass it explicitly, for example `id = "respondent_id"`. The function errors if an ID is missing from either input, if the ID sets differ, or if ID values are missing or duplicated.

## 4. Combining Flags

The `strategy` argument specifies how each respondent's flag values are combined into an exclusion decision. `TRUE` means that a flag meets its exclusion criterion; `FALSE` means that it does not.

### `strategy = "any"`

The decision is `TRUE` if at least one flag is `TRUE`. It is `FALSE` if all flags are `FALSE`. If there are no `TRUE` values and at least one `NA`, the decision is indeterminate (`NA`).

| Flags | Decision |
|---|---|
| `FALSE, FALSE` | Retain (`FALSE`) |
| `TRUE, NA` | Exclude (`TRUE`) |
| `FALSE, NA` | Indeterminate (`NA`) |

### `strategy = "all"`

The decision is `TRUE` only when all flags are `TRUE`. Any `FALSE` makes it `FALSE`. If there are no `FALSE` values and at least one `NA`, the decision is indeterminate (`NA`).

### `strategy = "at_least"`

The decision is `TRUE` when the number of `TRUE` flags is at least `n`. It is `FALSE` when the number of `TRUE` and `NA` flags combined is less than `n`, because even if every missing flag were `TRUE`, the criterion could not be met. Otherwise the decision is indeterminate (`NA`). `n` must be an integer from 1 to the number of flag columns.

## 5. Indeterminate Decisions and `na_action`

If the aggregate decision for a respondent cannot be determined because of missing flags, `na_action` controls what happens:

| `na_action` | Behavior |
|---|---|
| `"error"` | Default. Raises an error if any respondent has an indeterminate decision. |
| `"keep"` | Retains respondents with indeterminate decisions. Their final `excluded` value is `FALSE`. |
| `"exclude"` | Excludes respondents with indeterminate decisions. Their final `excluded` value is `TRUE`. |

This setting applies only when the aggregate decision is `NA`; it does not change decisions already determined by the selected rule. For example, with `strategy = "any"`, `TRUE, NA` is already an exclusion decision, while `FALSE, NA` is indeterminate.

## 6. Example

This example excludes respondents with any positive flag and keeps respondents whose decision is indeterminate. Flags are matched by ID, so their input order can differ from `survey`.

```r
library(Satisficing)

res <- filter_respondents(
  survey,
  flags,
  strategy = "any",
  na_action = "keep"
)

res$data      # Retained respondents: IDs 1 and 4
res$excluded  # Excluded respondents: IDs 2 and 3
res$audit     # Decision record for all respondents
```

## 7. Return Value and Audit Table

The function returns a named list with three elements:

- `$data`: Retained rows, preserving the columns, column order, and values in `data`.
- `$excluded`: Excluded rows, preserving the columns, column order, and values in `data`.
- `$audit`: A data frame recording decisions for every respondent in the row order of `data`.

The audit columns appear in this order: ID, `row_index`, each flag column, `n_flagged`, `n_missing_flags`, `decision`, `strategy`, `n_required`, `na_action`, and `excluded`.

| Column | Meaning |
|---|---|
| ID | Respondent identifier. |
| `row_index` | 1-based row number in the original `data`. |
| Each flag column | Logical flags aligned by ID. |
| `n_flagged` | Number of `TRUE` flags. |
| `n_missing_flags` | Number of `NA` flags. |
| `decision` | Aggregate decision before applying `na_action`; `NA` means indeterminate. |
| `strategy` | Aggregation strategy used. |
| `n_required` | 1 for `any`, number of flags for `all`, or supplied `n` for `at_least`. |
| `na_action` | The selected handling of indeterminate decisions. |
| `excluded` | Final exclusion decision after applying `na_action`. |

The ID column name and flag column names cannot use reserved audit names: `row_index`, `n_flagged`, `n_missing_flags`, `decision`, `strategy`, `n_required`, `na_action`, or `excluded`.

## 8. Practical Considerations

- `flags` must contain at least one logical flag column besides the ID. Numeric `0` / `1` columns are not converted to logical values.
- ID types and classes are checked as well as their values. For example, integer IDs in one input and character IDs in the other cannot be matched.
- `na_action = "keep"` and `"exclude"` lead to different outcomes for indeterminate respondents. Record the reason for the choice in your analysis procedure.
- Exclusion rules, the number of flags, and missing-value handling can affect results. State these choices and consider sensitivity analyses under alternative settings.

---

[User guide](../guide.en.md) | [日本語ユーザーガイド](../guide.ja.md)
