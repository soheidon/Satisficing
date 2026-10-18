test_that("semantic_inconsistency computes exact 5-point scale values for same and opposite pairs", {
  # 5-point scale: L = 1, U = 5, range = 4
  df <- data.frame(
    q1 = c(5, 5, 5, 5, 5, 5, 1, 3),
    q2 = c(5, 3, 1, 1, 3, 5, 1, 3)
  )

  pairs_same <- data.frame(item1 = "q1", item2 = "q2", relation = "same", stringsAsFactors = FALSE)
  pairs_opp  <- data.frame(item1 = "q1", item2 = "q2", relation = "opposite", stringsAsFactors = FALSE)

  res_same <- semantic_inconsistency(df, pairs_same, scale_min = 1, scale_max = 5)
  res_opp  <- semantic_inconsistency(df, pairs_opp, scale_min = 1, scale_max = 5)

  # same: |q1 - q2| / 4
  # Row 1: |5 - 5| / 4 = 0.0
  # Row 2: |5 - 3| / 4 = 0.5
  # Row 3: |5 - 1| / 4 = 1.0
  expect_equal(res_same$mean_inconsistency[1:3], c(0.0, 0.5, 1.0), tolerance = 1e-10)
  expect_equal(res_same$max_inconsistency[1:3],  c(0.0, 0.5, 1.0), tolerance = 1e-10)
  expect_equal(res_same$sum_inconsistency[1:3],  c(0.0, 0.5, 1.0), tolerance = 1e-10)

  # opposite: |(q1 - 1) - (5 - q2)| / 4
  # Row 4 (5, 1): |(5 - 1) - (5 - 1)| / 4 = |4 - 4| / 4 = 0.0
  # Row 5 (5, 3): |(5 - 1) - (5 - 3)| / 4 = |4 - 2| / 4 = 0.5
  # Row 6 (5, 5): |(5 - 1) - (5 - 5)| / 4 = |4 - 0| / 4 = 1.0
  # Row 7 (1, 1): |(1 - 1) - (5 - 1)| / 4 = |0 - 4| / 4 = 1.0
  # Row 8 (3, 3): |(3 - 1) - (5 - 3)| / 4 = |2 - 2| / 4 = 0.0
  expect_equal(res_opp$mean_inconsistency[4:8], c(0.0, 0.5, 1.0, 1.0, 0.0), tolerance = 1e-10)
})

test_that("semantic_inconsistency normalizes correctly for 1-7 scales and stays in [0, 1]", {
  df7 <- data.frame(
    a = c(1, 4, 7, 2),
    b = c(7, 4, 1, 6)
  )
  pairs_opp <- data.frame(item1 = "a", item2 = "b", relation = "opposite", stringsAsFactors = FALSE)
  res7 <- semantic_inconsistency(df7, pairs_opp, scale_min = 1, scale_max = 7)

  # 1-7 opposite:
  # (1, 7): |(1 - 1) - (7 - 7)| / 6 = 0
  # (4, 4): |(4 - 1) - (7 - 4)| / 6 = 0
  # (7, 1): |(7 - 1) - (7 - 1)| / 6 = 0
  # (2, 6): |(2 - 1) - (7 - 6)| / 6 = 0
  expect_equal(res7$mean_inconsistency, c(0, 0, 0, 0), tolerance = 1e-10)

  # Range bounded in [0, 1]
  expect_true(all(res7$mean_inconsistency >= 0 & res7$mean_inconsistency <= 1))
})

test_that("item order in pairs is invariant", {
  df <- data.frame(x = c(1, 2, 4), y = c(5, 3, 2))
  p1 <- data.frame(item1 = "x", item2 = "y", relation = "same", stringsAsFactors = FALSE)
  p2 <- data.frame(item1 = "y", item2 = "x", relation = "same", stringsAsFactors = FALSE)

  r1 <- semantic_inconsistency(df, p1, scale_min = 1, scale_max = 5)
  r2 <- semantic_inconsistency(df, p2, scale_min = 1, scale_max = 5)
  expect_identical(r1, r2)

  p1_opp <- data.frame(item1 = "x", item2 = "y", relation = "opposite", stringsAsFactors = FALSE)
  p2_opp <- data.frame(item1 = "y", item2 = "x", relation = "opposite", stringsAsFactors = FALSE)

  r1_opp <- semantic_inconsistency(df, p1_opp, scale_min = 1, scale_max = 5)
  r2_opp <- semantic_inconsistency(df, p2_opp, scale_min = 1, scale_max = 5)
  expect_identical(r1_opp, r2_opp)
})

test_that("multiple pairs aggregate mean, max, sum, valid, missing, and threshold counts", {
  df <- data.frame(
    q1 = c(5, 5, 1, NA, 3),
    q2 = c(5, 1, 5, 2,  NA),
    q3 = c(1, 5, 5, NA, NA)
  )
  # Pair 1: q1 - q2 (same)
  # Pair 2: q1 - q3 (opposite)
  pairs <- data.frame(
    item1 = c("q1", "q1"),
    item2 = c("q2", "q3"),
    relation = c("same", "opposite"),
    stringsAsFactors = FALSE
  )

  # Threshold 0.75:
  # Row 1 (5, 5, 1):
  #   p1 (same, 5, 5): 0.0
  #   p2 (opp,  5, 1): 0.0
  #   valid: 2, missing: 0, mean: 0.0, max: 0.0, sum: 0.0, n_high: 0, prop_high: 0.0
  # Row 2 (5, 1, 5):
  #   p1 (same, 5, 1): 1.0 (>= 0.75 -> high)
  #   p2 (opp,  5, 5): 1.0 (>= 0.75 -> high)
  #   valid: 2, missing: 0, mean: 1.0, max: 1.0, sum: 2.0, n_high: 2, prop_high: 1.0
  # Row 3 (1, 5, 5):
  #   p1 (same, 1, 5): 1.0 (>= 0.75 -> high)
  #   p2 (opp,  1, 5): 0.0 (< 0.75)
  #   valid: 2, missing: 0, mean: 0.5, max: 1.0, sum: 1.0, n_high: 1, prop_high: 0.5
  # Row 4 (NA, 2, NA):
  #   p1: NA, p2: NA -> valid: 0, missing: 2
  #   min_valid_pairs = 1 -> n_valid < 1 -> summary scores are NA
  # Row 5 (3, NA, NA):
  #   p1: NA, p2: NA -> valid: 0, missing: 2 -> scores NA

  res <- semantic_inconsistency(df, pairs, scale_min = 1, scale_max = 5, threshold = 0.75, min_valid_pairs = 1L)

  expect_named(res, c(
    "mean_inconsistency", "max_inconsistency", "sum_inconsistency",
    "n_valid_pairs", "n_missing_pairs", "n_high_inconsistency", "prop_high_inconsistency"
  ))

  # Check column types
  expect_type(res$mean_inconsistency, "double")
  expect_type(res$max_inconsistency, "double")
  expect_type(res$sum_inconsistency, "double")
  expect_type(res$n_valid_pairs, "integer")
  expect_type(res$n_missing_pairs, "integer")
  expect_type(res$n_high_inconsistency, "integer")
  expect_type(res$prop_high_inconsistency, "double")

  # Numerical checks
  expect_equal(res$mean_inconsistency[1:3], c(0.0, 1.0, 0.5), tolerance = 1e-10)
  expect_equal(res$max_inconsistency[1:3],  c(0.0, 1.0, 1.0), tolerance = 1e-10)
  expect_equal(res$sum_inconsistency[1:3],  c(0.0, 2.0, 1.0), tolerance = 1e-10)
  expect_identical(res$n_valid_pairs[1:3], c(2L, 2L, 2L))
  expect_identical(res$n_missing_pairs[1:3], c(0L, 0L, 0L))
  expect_identical(res$n_high_inconsistency[1:3], c(0L, 2L, 1L))
  expect_equal(res$prop_high_inconsistency[1:3], c(0.0, 1.0, 0.5), tolerance = 1e-10)

  # Check rows with 0 valid pairs
  expect_true(is.na(res$mean_inconsistency[4]))
  expect_true(is.na(res$max_inconsistency[4]))
  expect_true(is.na(res$sum_inconsistency[4]))
  expect_identical(res$n_valid_pairs[4], 0L)
  expect_identical(res$n_missing_pairs[4], 2L)
  expect_true(is.na(res$n_high_inconsistency[4]))
  expect_true(is.na(res$prop_high_inconsistency[4]))
})

test_that("min_valid_pairs threshold masks summary scores when not satisfied", {
  df <- data.frame(
    q1 = c(5, 5),
    q2 = c(5, NA),
    q3 = c(1, 1)
  )
  pairs <- data.frame(
    item1 = c("q1", "q1"),
    item2 = c("q2", "q3"),
    relation = c("same", "opposite"),
    stringsAsFactors = FALSE
  )

  # Respondent 1 has 2 valid pairs; Respondent 2 has 1 valid pair (q1 - q3)
  res_min2 <- semantic_inconsistency(df, pairs, scale_min = 1, scale_max = 5, min_valid_pairs = 2L)

  # Respondent 1: valid = 2 >= 2 -> scores computed
  expect_false(is.na(res_min2$mean_inconsistency[1]))
  expect_identical(res_min2$n_valid_pairs[1], 2L)

  # Respondent 2: valid = 1 < 2 -> summary scores masked as NA, but counts reported
  expect_true(is.na(res_min2$mean_inconsistency[2]))
  expect_true(is.na(res_min2$max_inconsistency[2]))
  expect_true(is.na(res_min2$sum_inconsistency[2]))
  expect_true(is.na(res_min2$n_high_inconsistency[2]))
  expect_true(is.na(res_min2$prop_high_inconsistency[2]))
  expect_identical(res_min2$n_valid_pairs[2], 1L)
  expect_identical(res_min2$n_missing_pairs[2], 1L)
})

test_that("threshold boundary: exact match is classified as high inconsistency", {
  df <- data.frame(q1 = c(4), q2 = c(1))
  # |4 - 1| / 4 = 3/4 = 0.75
  pairs <- data.frame(item1 = "q1", item2 = "q2", relation = "same", stringsAsFactors = FALSE)

  res <- semantic_inconsistency(df, pairs, scale_min = 1, scale_max = 5, threshold = 0.75)
  expect_equal(res$mean_inconsistency, 0.75, tolerance = 1e-10)
  expect_identical(res$n_high_inconsistency, 1L)
  expect_equal(res$prop_high_inconsistency, 1.0, tolerance = 1e-10)
})

test_that("details = TRUE returns correct respondents and pairs structures and row-major order", {
  df <- data.frame(
    q1 = c(5, 1),
    q2 = c(5, NA),
    q3 = c(1, 2)
  )
  pairs <- data.frame(
    item1 = c("q1", "q1"),
    item2 = c("q2", "q3"),
    relation = c("same", "opposite"),
    stringsAsFactors = FALSE
  )

  res_det <- semantic_inconsistency(df, pairs, scale_min = 1, scale_max = 5, details = TRUE)

  expect_type(res_det, "list")
  expect_named(res_det, c("respondents", "pairs"))
  expect_equal(nrow(res_det$respondents), 2L)
  expect_equal(nrow(res_det$pairs), 2L * 2L) # 2 respondents x 2 pairs

  p_df <- res_det$pairs
  expect_named(p_df, c("respondent_row", "pair_id", "item1", "item2", "relation", "inconsistency"))
  expect_identical(p_df$respondent_row, c(1L, 1L, 2L, 2L))
  expect_identical(p_df$pair_id, c(1L, 2L, 1L, 2L))
  expect_identical(p_df$item1, c("q1", "q1", "q1", "q1"))
  expect_identical(p_df$item2, c("q2", "q3", "q2", "q3"))
  expect_identical(p_df$relation, c("same", "opposite", "same", "opposite"))

  # Inconsistency values:
  # Resp 1, Pair 1: |5 - 5| / 4 = 0.0
  # Resp 1, Pair 2: |(5 - 1) - (5 - 1)| / 4 = 0.0
  # Resp 2, Pair 1: q2 is NA -> NA_real_
  # Resp 2, Pair 2: |(1 - 1) - (5 - 2)| / 4 = |0 - 3| / 4 = 0.75
  expect_equal(p_df$inconsistency[1], 0.0, tolerance = 1e-10)
  expect_equal(p_df$inconsistency[2], 0.0, tolerance = 1e-10)
  expect_true(is.na(p_df$inconsistency[3]))
  expect_equal(p_df$inconsistency[4], 0.75, tolerance = 1e-10)
})

test_that("empty 0-row data returns typed empty results", {
  df_empty <- data.frame(q1 = numeric(0), q2 = numeric(0))
  pairs <- data.frame(item1 = "q1", item2 = "q2", relation = "same", stringsAsFactors = FALSE)

  res_empty <- semantic_inconsistency(df_empty, pairs, scale_min = 1, scale_max = 5, details = FALSE)
  expect_equal(nrow(res_empty), 0L)
  expect_named(res_empty, c(
    "mean_inconsistency", "max_inconsistency", "sum_inconsistency",
    "n_valid_pairs", "n_missing_pairs", "n_high_inconsistency", "prop_high_inconsistency"
  ))
  expect_type(res_empty$mean_inconsistency, "double")
  expect_type(res_empty$n_valid_pairs, "integer")

  res_det_empty <- semantic_inconsistency(df_empty, pairs, scale_min = 1, scale_max = 5, details = TRUE)
  expect_equal(nrow(res_det_empty$respondents), 0L)
  expect_equal(nrow(res_det_empty$pairs), 0L)
  expect_named(res_det_empty$pairs, c(
    "respondent_row", "pair_id", "item1", "item2", "relation", "inconsistency"
  ))
  expect_type(res_det_empty$pairs$respondent_row, "integer")
  expect_type(res_det_empty$pairs$inconsistency, "double")
})

test_that("matrix input with valid column names is supported", {
  mat <- matrix(c(5, 1, 5, 5), nrow = 2, ncol = 2,
                dimnames = list(NULL, c("q1", "q2")))
  pairs <- data.frame(item1 = "q1", item2 = "q2", relation = "same", stringsAsFactors = FALSE)

  res_mat <- semantic_inconsistency(mat, pairs, scale_min = 1, scale_max = 5)
  expect_s3_class(res_mat, "data.frame")
  expect_equal(nrow(res_mat), 2L)
})

test_that("input validation catches invalid arguments and data constraints", {
  valid_df <- data.frame(q1 = c(1, 2), q2 = c(3, 4))
  valid_pairs <- data.frame(item1 = "q1", item2 = "q2", relation = "same", stringsAsFactors = FALSE)

  # scale_min / scale_max errors
  expect_error(semantic_inconsistency(valid_df, valid_pairs, scale_min = "1", scale_max = 5), "single finite numeric")
  expect_error(semantic_inconsistency(valid_df, valid_pairs, scale_min = 1, scale_max = Inf), "single finite numeric")
  expect_error(semantic_inconsistency(valid_df, valid_pairs, scale_min = 5, scale_max = 1), "strictly less than")
  expect_error(semantic_inconsistency(valid_df, valid_pairs, scale_min = 1, scale_max = 1), "strictly less than")

  # threshold errors
  expect_error(semantic_inconsistency(valid_df, valid_pairs, 1, 5, threshold = -0.1), "between 0 and 1")
  expect_error(semantic_inconsistency(valid_df, valid_pairs, 1, 5, threshold = 1.1), "between 0 and 1")
  expect_error(semantic_inconsistency(valid_df, valid_pairs, 1, 5, threshold = NA_real_), "between 0 and 1")

  # min_valid_pairs errors and boundary acceptance
  expect_error(semantic_inconsistency(valid_df, valid_pairs, 1, 5, min_valid_pairs = 0L), "integer >= 1")
  expect_error(semantic_inconsistency(valid_df, valid_pairs, 1, 5, min_valid_pairs = 1.5), "integer >= 1")
  expect_error(semantic_inconsistency(valid_df, valid_pairs, 1, 5, min_valid_pairs = NA_integer_), "integer >= 1")
  expect_error(semantic_inconsistency(valid_df, valid_pairs, 1, 5, min_valid_pairs = 2147483648), "integer >= 1")
  expect_error(semantic_inconsistency(valid_df, valid_pairs, 1, 5, min_valid_pairs = 1e15), "integer >= 1")
  expect_no_error(semantic_inconsistency(valid_df, valid_pairs, 1, 5, min_valid_pairs = .Machine$integer.max))

  # details errors
  expect_error(semantic_inconsistency(valid_df, valid_pairs, 1, 5, details = "TRUE"), "single non-missing logical")
  expect_error(semantic_inconsistency(valid_df, valid_pairs, 1, 5, details = NA), "single non-missing logical")

  # pairs errors
  expect_error(semantic_inconsistency(valid_df, list(item1 = "q1"), 1, 5), "must be a data.frame")
  expect_error(semantic_inconsistency(valid_df, data.frame(a = 1), 1, 5), "must contain columns")
  expect_error(semantic_inconsistency(valid_df, valid_pairs[0, ], 1, 5), "at least one item pair")

  # self-pairs
  self_p <- data.frame(item1 = "q1", item2 = "q1", relation = "same", stringsAsFactors = FALSE)
  expect_error(semantic_inconsistency(valid_df, self_p, 1, 5), "Self-pairs")

  # duplicate pairs (A, B) and (B, A)
  dup_p <- data.frame(
    item1 = c("q1", "q2"),
    item2 = c("q2", "q1"),
    relation = c("same", "opposite"),
    stringsAsFactors = FALSE
  )
  expect_error(semantic_inconsistency(valid_df, dup_p, 1, 5), "Duplicate item pair")

  # invalid relation
  bad_rel <- data.frame(item1 = "q1", item2 = "q2", relation = "SAME", stringsAsFactors = FALSE)
  expect_error(semantic_inconsistency(valid_df, bad_rel, 1, 5), "either 'same' or 'opposite'")

  # data validation
  expect_error(semantic_inconsistency("not_data", valid_pairs, 1, 5), "matrix or data.frame")

  # missing column in data
  missing_p <- data.frame(item1 = "q1", item2 = "q3", relation = "same", stringsAsFactors = FALSE)
  expect_error(semantic_inconsistency(valid_df, missing_p, 1, 5), "not found in 'data'")

  # non-numeric target column
  char_df <- data.frame(q1 = c(1, 2), q2 = c("a", "b"), stringsAsFactors = FALSE)
  expect_error(semantic_inconsistency(char_df, valid_pairs, 1, 5), "bare numeric")

  factor_df <- data.frame(q1 = c(1, 2), q2 = factor(c("1", "2")))
  expect_error(semantic_inconsistency(factor_df, valid_pairs, 1, 5), "bare numeric")

  # NaN / Inf in target columns
  nan_df <- data.frame(q1 = c(1, NaN), q2 = c(3, 4))
  expect_error(semantic_inconsistency(nan_df, valid_pairs, 1, 5), "NaN values")

  inf_df <- data.frame(q1 = c(1, Inf), q2 = c(3, 4))
  expect_error(semantic_inconsistency(inf_df, valid_pairs, 1, 5), "infinite values")

  # Out of scale range
  out_df <- data.frame(q1 = c(0, 2), q2 = c(3, 4))
  expect_error(semantic_inconsistency(out_df, valid_pairs, 1, 5), "outside \\['scale_min', 'scale_max'\\]")
  out_df2 <- data.frame(q1 = c(1, 6), q2 = c(3, 4))
  expect_error(semantic_inconsistency(out_df2, valid_pairs, 1, 5), "outside \\['scale_min', 'scale_max'\\]")
})

test_that("vectorized calculation matches sequential loop reference across enumerated data", {
  # Generate deterministic grid of responses
  vals <- 1:5
  grid <- expand.grid(q1 = vals, q2 = vals, q3 = vals)

  pairs <- data.frame(
    item1 = c("q1", "q1", "q2"),
    item2 = c("q2", "q3", "q3"),
    relation = c("same", "opposite", "same"),
    stringsAsFactors = FALSE
  )

  # Sequential reference calculation
  n_rows <- nrow(grid)
  ref_means <- numeric(n_rows)
  ref_maxs  <- numeric(n_rows)
  ref_sums  <- numeric(n_rows)
  ref_highs <- integer(n_rows)

  for (i in seq_len(n_rows)) {
    s1 <- abs(grid$q1[i] - grid$q2[i]) / 4
    s2 <- abs((grid$q1[i] - 1) - (5 - grid$q3[i])) / 4
    s3 <- abs(grid$q2[i] - grid$q3[i]) / 4
    scores <- c(s1, s2, s3)
    ref_means[i] <- mean(scores)
    ref_maxs[i]  <- max(scores)
    ref_sums[i]  <- sum(scores)
    ref_highs[i] <- sum(scores >= 0.75)
  }

  res_vec <- semantic_inconsistency(grid, pairs, scale_min = 1, scale_max = 5, threshold = 0.75)

  expect_equal(res_vec$mean_inconsistency, ref_means, tolerance = 1e-10)
  expect_equal(res_vec$max_inconsistency,  ref_maxs,  tolerance = 1e-10)
  expect_equal(res_vec$sum_inconsistency,  ref_sums,  tolerance = 1e-10)
  expect_identical(res_vec$n_high_inconsistency, ref_highs)
})

test_that("duplicate pair detection is separator-independent and does not collide on underscores", {
  # ("a___b", "c") and ("a", "b___c") are distinct pairs that would collide under sep = "___"
  df_sep <- data.frame(
    `a___b` = c(1, 2),
    c = c(3, 4),
    a = c(2, 3),
    `b___c` = c(4, 5),
    check.names = FALSE
  )
  pairs_distinct <- data.frame(
    item1 = c("a___b", "a"),
    item2 = c("c", "b___c"),
    relation = c("same", "same"),
    stringsAsFactors = FALSE
  )

  # Must succeed without false duplicate error
  res <- expect_no_error(semantic_inconsistency(df_sep, pairs_distinct, scale_min = 1, scale_max = 5))
  expect_equal(nrow(res), 2L)

  # Actual duplicates with underscore names must still be rejected
  pairs_dup <- data.frame(
    item1 = c("a___b", "c"),
    item2 = c("c", "a___b"),
    relation = c("same", "opposite"),
    stringsAsFactors = FALSE
  )
  expect_error(semantic_inconsistency(df_sep, pairs_dup, scale_min = 1, scale_max = 5), "Duplicate item pair")
})
