[English](rawnn.en.md) | [日本語](rawnn.ja.md)

# `rawnn()`: List Column Numbers and Variable Names

## 1. Overview

`rawnn()` prints the variable names in a data frame together with their column numbers.

Survey datasets may contain respondent IDs, demographics, questionnaire items, scale scores, and other variables in a single data frame. When there are many columns, it can be difficult to see which variable is in which position. `rawnn()` displays the position and name of every column in the data frame.

For example, the console prints a character vector like this (spacing and line wrapping can depend on console width):

```text
[1] "1: ID" "2: Age" "3: Gender" "4: Q1" "5: Q2" "6: Q3" "7: Q4"
```

This list can help you inspect where the items of interest are located. `rawnn()` does not evaluate response quality or calculate a statistical indicator. It is a utility for inspecting data structure and selecting variables appropriately.

## 2. Basic usage

The function has the following form:

```r
rawnn(dataframe)
```

| Argument | Description |
|---|---|
| `dataframe` | A data frame whose column numbers and names will be printed |

For example:

```r
library(Satisficing)

df <- data.frame(
  ID = 1:3,
  Age = c(25, 32, 41),
  Q1 = c(3, 4, 2),
  Q2 = c(4, 4, 3),
  Q3 = c(3, 5, 2)
)

rawnn(df)
```

The output is:

```text
1: ID
2: Age
3: Q1
4: Q2
5: Q3
```

Column numbering follows R's standard indexing and starts at 1. The columns are printed in their current data-frame order; `rawnn()` does not sort variable names alphabetically.

## 3. Inspecting columns for analysis

One common use is to identify the positions of items in a data frame with many variables. Suppose the output is:

```text
1: ID
2: Age
3: Gender
4: Q1
5: Q2
6: Q3
7: Q4
8: Q5
9: Total
```

Items Q1 through Q5 occupy columns 4 through 8. You can select them by position:

```r
items <- df[, 4:8]
```

Or select them by name:

```r
items <- df[, paste0("Q", 1:5)]
```

Use `rawnn()` to inspect the data structure before selecting columns. Positional selection can refer to different variables if columns are added, removed, or reordered. For reproducible analysis code, selecting by variable name is generally safer. If you use column numbers, confirm that the data frame still has the expected column structure.

## 4. Using it with other functions

`rawnn()` can help identify the item columns to pass to other `Satisficing` functions. For example, because `longstring()` treats input columns as the item sequence, select the intended items in their actual presentation order:

```r
rawnn(df)
longstring(df[, 4:8])
```

`stline()` accepts column names, which can also be checked with `rawnn()`:

```r
stline(
  df,
  columns = c("Q1", "Q2", "Q3", "Q4", "Q5")
)
```

This can help avoid accidentally including IDs, demographics, or other non-item columns in an analysis.

## 5. Difference from `names()` and `colnames()`

R provides `names()` and `colnames()` to retrieve column names. For example, `names(df)` returns a character vector such as:

```text
[1] "ID" "Age" "Q1" "Q2" "Q3" "Q4" "Q5"
```

`rawnn()` instead prints one line per column, pairing each name with its position.

| Function | Main use | Return value |
|---|---|---|
| `names()` | Retrieve names | Character vector |
| `colnames()` | Retrieve column names | Character vector |
| `rawnn()` | Inspect the mapping between positions and names | `invisible(NULL)` |

Use `names()` or `colnames()` when you need to reuse column names in code. `rawnn()` is intended for visual inspection in the console.

## 6. Return value and behavior

`rawnn()` prints its output to the console. It does not return a vector or data frame of results; its documented return value is `invisible(NULL)`. For example:

```r
result <- rawnn(df)
```

The column list is still printed, but `result` is `NULL`. Use `names()` or `colnames()` if you need to store or reuse the names programmatically.

The function does not modify the data frame: it does not add, remove, or reorder columns.

## 7. Notes

### 7.1 Column numbers depend on the current data-frame structure

The numbers printed by `rawnn()` refer to column positions at the time the function is called. Adding, removing, or reordering columns can change those positions. Check the current structure before using positional references in analysis code.

### 7.2 The function does not identify what variables mean

`rawnn()` prints the column names as stored. It does not determine which scale or construct a variable belongs to, whether an item is reverse-keyed, or which response categories it uses. Consult the questionnaire, codebook, or variable documentation for that information.

### 7.3 The function does not display data values

Only column numbers and names are printed. The function does not show values, data types, missing-value counts, or response distributions. Use R functions such as `str()`, `summary()`, and `head()` to inspect those properties.

## 8. Summary

`rawnn()` is a utility for printing the mapping between data-frame column numbers and variable names. It is particularly useful when checking the positions of items in a dataset with many columns.

It is not a response-quality indicator. Use it to inspect the data structure, then select only the intended variables for analysis.

## 9. References

R Core Team. *R: A Language and Environment for Statistical Computing*. R Foundation for Statistical Computing. https://www.R-project.org/

See the R help pages for `names()`, `colnames()`, and `seq_along()`:

```r
?names
?colnames
?seq_along
```

`rawnn()` is a utility that prints column positions and names, not a statistical method; no method-specific research citation is needed.

---

[User guide](../guide.en.md) | [ユーザーガイド](../guide.ja.md)
