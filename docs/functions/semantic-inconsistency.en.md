[English](semantic-inconsistency.en.md) | [日本語](semantic-inconsistency.ja.md)

# `semantic_inconsistency()`: Semantic Inconsistency across Item Pairs

## 1. Overview

`semantic_inconsistency()` evaluates the degree of semantic response inconsistency across user-specified item pairs that share expected directional relationships (same-direction `same` or opposite-direction `opposite`).

In survey questionnaires, respondents answering attentively are expected to give similar ratings to semantically synonymous items, and contrasting ratings to reverse-coded or antonymous items. Inconsistency scores quantify the extent to which observed responses diverge from these expected relationships. All inconsistency scores are normalized to the theoretical response scale range \([0, 1]\), where 0 represents complete consistency and 1 represents maximal inconsistency.

Semantic inconsistency is an exploratory indicator of response patterns. It does not definitively prove careless, dishonest, or insufficient-effort responding.

## 2. Mathematical Definition

Let the theoretical response scale range from minimum \(L\) to maximum \(U\), with theoretical width \(R = U - L\). For respondent \(k\) and an item pair with observed valid ratings \(x_i\) and \(x_j\):

### Same Direction (`relation = "same"`)
When items are expected to be rated identically:
\[
\text{Inconsistency} = \frac{|x_i - x_j|}{U - L}
\]

### Opposite Direction (`relation = "opposite"`)
When items are expected to be rated in opposite directions:
\[
\text{Inconsistency} = \frac{|(x_i - L) - (U - x_j)|}{U - L} = \frac{|x_i + x_j - (L + U)|}{U - L}
\]

Both formulas are symmetric with respect to item ordering (\(x_i\) and \(x_j\) can be swapped without changing the result).

### Example on a 5-Point Scale (\(L = 1, U = 5, R = 4\)):

| \(x_i\) | \(x_j\) | Relation | Formula | Score | Interpretation |
|---:|---:|---|---|---:|---|
| 5 | 5 | same | \(|5 - 5| / 4\) | 0.00 | Complete consistency |
| 5 | 3 | same | \(|5 - 3| / 4\) | 0.50 | Moderate inconsistency |
| 5 | 1 | same | \(|5 - 1| / 4\) | 1.00 | Maximal inconsistency |
| 5 | 1 | opposite | \(|(5 - 1) - (5 - 1)| / 4\) | 0.00 | Complete consistency |
| 5 | 3 | opposite | \(|(5 - 1) - (5 - 3)| / 4\) | 0.50 | Moderate inconsistency |
| 5 | 5 | opposite | \(|(5 - 1) - (5 - 5)| / 4\) | 1.00 | Maximal inconsistency |
| 3 | 3 | opposite | \(|(3 - 1) - (5 - 3)| / 4\) | 0.00 | Complete consistency (midpoints) |

## 3. Basic Usage

```r
semantic_inconsistency(
  data,
  pairs,
  scale_min,
  scale_max,
  threshold = 0.75,
  min_valid_pairs = 1L,
  details = FALSE
)
```

| Argument | Description |
|---|---|
| `data` | Matrix or data frame with respondents in rows and survey items in columns. Target columns must be bare numeric (integer or double). |
| `pairs` | Data frame with columns `item1`, `item2`, and `relation`. `relation` must be `"same"` or `"opposite"`. Duplicate pairs and self-pairs are not permitted. |
| `scale_min` | Finite numeric scalar specifying the theoretical minimum of the response scale. |
| `scale_max` | Finite numeric scalar specifying the theoretical maximum of the response scale (`scale_min < scale_max`). |
| `threshold` | Finite numeric scalar in \([0, 1]\) defining high inconsistency (`>= threshold`). Defaults to `0.75` (an illustrative default, not a validated cutoff). |
| `min_valid_pairs` | Integer scalar \(\ge 1\) specifying the minimum valid pairs required to compute summary scores. Defaults to `1L`. |
| `details` | Logical scalar; if `TRUE`, returns a named list with respondent summaries and detailed pair evaluations. Defaults to `FALSE`. |

### Worked example

The scale limits below are 1 and 5. `q1` and `q2` are specified as a same-direction pair, while `q1` and `q3` are specified as an opposite-direction pair.

```r
library(Satisficing)

responses <- data.frame(
  q1 = c(5, 5, 1, NA),
  q2 = c(5, 3, 5, 1),
  q3 = c(1, 5, 5, NA)
)

item_pairs <- data.frame(
  item1 = c("q1", "q1"),
  item2 = c("q2", "q3"),
  relation = c("same", "opposite")
)

scores <- semantic_inconsistency(
  responses,
  pairs = item_pairs,
  scale_min = 1,
  scale_max = 5
)
scores
```

The first respondent has zero inconsistency for both pairs. The second respondent scores 0.5 for the same-direction pair and 1 for the opposite-direction pair, giving a mean of 0.75. The fourth respondent has no valid pair because `q1` is missing; the pair counts remain informative even though the summary scores are `NA`.

The main output columns for this example are shown below (numeric formatting may vary by R session).

```text
  mean_inconsistency max_inconsistency sum_inconsistency n_valid_pairs n_missing_pairs
1              0.00              0.00              0.00             2               0
2              0.75              1.00              1.50             2               0
3              0.50              1.00              1.00             2               0
4                NA                NA                NA             0               2
```

For respondent 3, the same-direction pair has maximal inconsistency (1), while the opposite-direction pair is fully consistent (0), so the mean is 0.5. `n_high_inconsistency` and `prop_high_inconsistency` count pairs with scores at or above the default `threshold = 0.75`.

## 4. Returned Values

### Respondent Summary (`details = FALSE`)
Returns a data frame with one row per respondent preserving input order:

1. `mean_inconsistency` (double): Average inconsistency score across valid pairs.
2. `max_inconsistency` (double): Maximum inconsistency score among valid pairs.
3. `sum_inconsistency` (double): Sum of inconsistency scores across valid pairs.
4. `n_valid_pairs` (integer): Number of pairs where both items were non-missing.
5. `n_missing_pairs` (integer): Number of pairs where at least one item was missing (`NA`).
6. `n_high_inconsistency` (integer): Number of valid pairs with score \(\ge\) `threshold`.
7. `prop_high_inconsistency` (double): `n_high_inconsistency / n_valid_pairs`.

When `n_valid_pairs < min_valid_pairs`, summary score columns (1–3, 6–7) are set to `NA`, while count columns (4–5) report observed values.

### Detailed Pair Evaluations (`details = TRUE`)
Returns a list with elements:
- `$respondents`: The respondent summary data frame.
- `$pairs`: A long data frame in row-major order (respondent row then pair ID) with columns `respondent_row`, `pair_id`, `item1`, `item2`, `relation`, and `inconsistency`.

For example, `semantic_inconsistency(responses, item_pairs, 1, 5, details = TRUE)` returns both the summary table and the two item-pair scores for every respondent. `respondent_row` is the 1-based row position in `data`; `pair_id` is the 1-based row position in `pairs`.

```r
result <- semantic_inconsistency(
  responses,
  item_pairs,
  scale_min = 1,
  scale_max = 5,
  details = TRUE
)

result$respondents  # respondent-level summaries
result$pairs        # respondent- and pair-level scores
```

Missing pairs are retained as rows in `result$pairs`, with `NA` in `inconsistency`. This lets you inspect pair-level missingness and the observations underlying each summary.

## 5. Methodological Considerations

- **Item selection:** Inconsistency scores depend directly on the researcher's choice of item pairs and assumed relations.
- **Item overlap:** Items can appear in multiple pairs, but the resulting pair scores are correlated and must not be treated as independent evidence.
- **Thresholds and screening:** Cutoffs such as 0.75 are illustrative. Researchers should conduct sensitivity analyses rather than automatically excluding respondents based on a single threshold.

### Missing responses and minimum pair count

A pair contributes a score only when both of its responses are observed. If either value is `NA`, that pair is counted in `n_missing_pairs` and excluded from the score summaries. When the number of valid pairs is below `min_valid_pairs`, `mean_inconsistency`, `max_inconsistency`, `sum_inconsistency`, `n_high_inconsistency`, and `prop_high_inconsistency` are `NA`; `n_valid_pairs` and `n_missing_pairs` still report the observed counts. With the default `min_valid_pairs = 1`, a respondent with no valid pairs therefore has `NA` summary values.

### Choosing pairs and scale limits

Specify `scale_min` and `scale_max` from the response scale's theoretical endpoints, not from the observed minimum and maximum in a particular sample. Every selected item must be a bare numeric column, and its non-missing values must lie within those endpoints. `NaN`, infinite values, categorical columns, and values outside the declared scale range are rejected.

The `same` or `opposite` relation must describe the values supplied to the function. If responses have been reverse-scored, the expected relation may differ from the relation for the originally recorded choices. Decide the scoring and pairing rules before interpreting the scores.

### Interpretation

The function computes a researcher-specified distance from an expected pair relationship. It does not discover item meaning, choose pairs, or provide a validated universal cutoff. A high score signals divergence from the specified relationship and should be interpreted with item wording, scale coding, missingness, and other response-quality evidence. It is not a standalone diagnosis of careless responding.

---

[User guide](../guide.en.md) | [日本語ユーザーガイド](../guide.ja.md)
