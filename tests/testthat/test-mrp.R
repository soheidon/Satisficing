test_that("mrp computes exact hand-calculated unstandardized and normalized values", {
  # Row 1: x = (3, 3, 4, 4), pairwise diffs: 0, 1, 1, 1, 1, 0 -> sqrt: 0, 1, 1, 1, 1, 0 -> sum = 4, pairs = 6 -> T = 4/6
  # Row 2: x = (1, 1, 1, 1), pairwise diffs: all 0 -> T = 0
  # Row 3: x = (1, 1, 1, 2), diffs: (1,1)->0, (1,1)->0, (1,2)->1, (1,1)->0, (1,2)->1, (1,2)->1 -> sum = 3, pairs = 6 -> T = 3/6 = 0.5
  df <- data.frame(
    q1 = c(3, 1, 1),
    q2 = c(3, 1, 1),
    q3 = c(4, 1, 1),
    q4 = c(4, 1, 2)
  )

  res <- mrp(df, c("q1", "q2", "q3", "q4"))
  expect_s3_class(res, "data.frame")
  expect_named(res, c("q1", "q2", "q3", "q4", "mrp"))

  # min(T) = 0, max(T) = 2/3
  # Row 1: (2/3 - 2/3) / (2/3 - 0) = 0
  # Row 2: (2/3 - 0) / (2/3 - 0) = 1 (complete straightlining = 1)
  # Row 3: (2/3 - 0.5) / (2/3 - 0) = (1/6) / (2/3) = 0.25
  expect_equal(res$mrp, c(0, 1, 0.25), tolerance = 1e-10)
})

test_that("mrp normalization handles constant sample and single-case sample with NA", {
  # All rows identical T (e.g. all straightline, T = 0)
  df_const <- data.frame(
    q1 = c(1, 2, 3),
    q2 = c(1, 2, 3),
    q3 = c(1, 2, 3)
  )
  res_const <- mrp(df_const, c("q1", "q2", "q3"))
  expect_identical(res_const$mrp, c(NA_real_, NA_real_, NA_real_))

  # Only one respondent has >= 2 valid responses
  df_single <- data.frame(
    q1 = c(1, 1, NA),
    q2 = c(2, NA, NA),
    q3 = c(3, NA, NA)
  )
  res_single <- mrp(df_single, c("q1", "q2", "q3"))
  expect_identical(res_single$mrp, c(NA_real_, NA_real_, NA_real_))
})

test_that("mrp returns NA_real_ for rows with fewer than 2 valid responses", {
  df_na <- data.frame(
    q1 = c(1, 1, NA, NA),
    q2 = c(2, NA, NA, NA),
    q3 = c(3, NA, NA, NA)
  )
  # Row 1 has 3 valid, row 2 has 1 valid, row 3 and 4 have 0 valid
  # To test normalization when row 1 is valid, add another valid row
  df_na2 <- data.frame(
    q1 = c(1, 1, NA, 2),
    q2 = c(2, NA, NA, 2),
    q3 = c(3, NA, NA, 3)
  )
  res <- mrp(df_na2, c("q1", "q2", "q3"))
  expect_true(!is.na(res$mrp[1]))
  expect_true(is.na(res$mrp[2]))
  expect_true(is.na(res$mrp[3]))
  expect_true(!is.na(res$mrp[4]))
})

test_that("mrp handles 0-row data frame correctly", {
  df0 <- data.frame(q1 = numeric(0), q2 = numeric(0))
  res0 <- mrp(df0, c("q1", "q2"))
  expect_equal(nrow(res0), 0L)
  expect_equal(res0$mrp, numeric(0))
})

test_that("mrp is column permutation invariant and preserves row order", {
  df <- data.frame(
    q1 = c(1, 5, 2),
    q2 = c(2, 5, 3),
    q3 = c(3, 5, 4)
  )
  res1 <- mrp(df, c("q1", "q2", "q3"))
  res2 <- mrp(df, c("q3", "q2", "q1"))
  expect_equal(res1$mrp, res2$mrp, tolerance = 1e-10)

  # Reverse rows
  df_rev <- df[3:1, ]
  res_rev <- mrp(df_rev, c("q1", "q2", "q3"))
  expect_equal(res_rev$mrp, res1$mrp[3:1], tolerance = 1e-10)
})

test_that("mrp validates input arguments strictly", {
  df <- data.frame(q1 = 1:3, q2 = 4:6, q3 = 7:9)

  # Non-data.frame
  expect_error(mrp(1:10, c("q1", "q2")), "'data' must be a data frame")
  expect_error(mrp(matrix(1:4, 2, 2), c("q1", "q2")), "'data' must be a data frame")

  # Duplicated column names in data
  df_dup <- data.frame(q1 = 1:3, q2 = 4:6)
  names(df_dup) <- c("q1", "q1")
  expect_error(mrp(df_dup, c("q1", "q1")), "Column names in 'data' must be unique")

  # columns validation
  expect_error(mrp(df, 1:2), "'columns' must be a character vector")
  expect_error(mrp(df, "q1"), "contain at least 2 column names")
  expect_error(mrp(df, c("q1", NA)), "missing or empty")
  expect_error(mrp(df, c("q1", "")), "missing or empty")
  expect_error(mrp(df, c("q1", "q1")), "duplicate column names")
  expect_error(mrp(df, c("q1", "nonexistent")), "do not exist in 'data'")

  # result_column_name validation
  expect_error(mrp(df, c("q1", "q2"), result_column_name = 123), "'result_column_name' must be a non-empty character string")
  expect_error(mrp(df, c("q1", "q2"), result_column_name = c("a", "b")), "'result_column_name' must be a non-empty character string")
  expect_error(mrp(df, c("q1", "q2"), result_column_name = ""), "'result_column_name' must be a non-empty character string")
  expect_error(mrp(df, c("q1", "q2"), result_column_name = NA_character_), "'result_column_name' must be a non-empty character string")
  expect_error(mrp(df, c("q1", "q2"), result_column_name = "q1"), "already exists in 'data'")

  # Type rejections: factor, character, logical
  df_fac <- data.frame(q1 = 1:3, q2 = factor(c("a", "b", "c")))
  expect_error(mrp(df_fac, c("q1", "q2")), "not numeric")

  df_chr <- data.frame(q1 = 1:3, q2 = c("a", "b", "c"))
  expect_error(mrp(df_chr, c("q1", "q2")), "not numeric")

  df_lgl <- data.frame(q1 = 1:3, q2 = c(TRUE, FALSE, TRUE))
  expect_error(mrp(df_lgl, c("q1", "q2")), "not numeric")

  # Non-finite values: Inf, -Inf, NaN
  df_inf <- data.frame(q1 = c(1, Inf), q2 = c(2, 3))
  expect_error(mrp(df_inf, c("q1", "q2")), "contains non-finite values")

  df_minf <- data.frame(q1 = c(1, -Inf), q2 = c(2, 3))
  expect_error(mrp(df_minf, c("q1", "q2")), "contains non-finite values")

  df_nan <- data.frame(q1 = c(1, NaN), q2 = c(2, 3))
  expect_error(mrp(df_nan, c("q1", "q2")), "contains non-finite values")
})
