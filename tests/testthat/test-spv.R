test_that("spv computes exact hand-calculated values on numeric data", {
  df <- data.frame(
    q1 = c(3, 1, 1, 1, 1, NA),
    q2 = c(3, 1, 2, 1, NA, NA),
    q3 = c(4, 1, 3, NA, NA, NA),
    q4 = c(4, 1, 4, NA, NA, NA)
  )

  res <- spv(df, c("q1", "q2", "q3", "q4"))
  expect_s3_class(res, "data.frame")
  expect_named(res, c("q1", "q2", "q3", "q4", "spv"))

  # Row 1: (3, 3, 4, 4) -> props: (0.5, 0.5) -> 1 - (0.25 + 0.25) = 0.5
  # Row 2: (1, 1, 1, 1) -> props: (1.0) -> 1 - 1.0 = 0.0
  # Row 3: (1, 2, 3, 4) -> props: (0.25, 0.25, 0.25, 0.25) -> 1 - 4*(0.0625) = 0.75
  # Row 4: (1, 1, NA, NA) -> props: 1 (2/4), NA (2/4) -> 1 - (0.25 + 0.25) = 0.5
  # Row 5: (1, NA, NA, NA) -> props: 1 (1/4), NA (3/4) -> 1 - (0.0625 + 0.5625) = 0.375
  # Row 6: (NA, NA, NA, NA) -> props: NA (4/4) -> 1 - 1.0 = 0.0
  expect_equal(res$spv, c(0.5, 0.0, 0.75, 0.5, 0.375, 0.0), tolerance = 1e-10)
})

test_that("spv handles factor columns using display level labels rather than internal integer codes", {
  f1 <- factor(c("High", "Low", "High"), levels = c("Low", "High"))
  f2 <- factor(c("High", "Low", "Low"), levels = c("High", "Low"))
  df_fac <- data.frame(f1 = f1, f2 = f2)

  res <- spv(df_fac, c("f1", "f2"))
  # Row 1: ("High", "High") -> 1 - 1^2 = 0.0
  # Row 2: ("Low", "Low") -> 1 - 1^2 = 0.0
  # Row 3: ("High", "Low") -> 1 - (0.5^2 + 0.5^2) = 0.5
  expect_equal(res$spv, c(0.0, 0.0, 0.5), tolerance = 1e-10)
})

test_that("spv handles 0-row data frame correctly", {
  df0 <- data.frame(q1 = numeric(0), q2 = numeric(0))
  res0 <- spv(df0, c("q1", "q2"))
  expect_equal(nrow(res0), 0L)
  expect_equal(res0$spv, numeric(0))
})

test_that("spv is column permutation invariant and preserves row order", {
  df <- data.frame(
    q1 = c(1, 2, 3),
    q2 = c(1, 2, 3),
    q3 = c(2, 2, 3)
  )
  res1 <- spv(df, c("q1", "q2", "q3"))
  res2 <- spv(df, c("q3", "q2", "q1"))
  expect_equal(res1$spv, res2$spv, tolerance = 1e-10)

  df_rev <- df[3:1, ]
  res_rev <- spv(df_rev, c("q1", "q2", "q3"))
  expect_equal(res_rev$spv, res1$spv[3:1], tolerance = 1e-10)
})

test_that("spv validates input arguments strictly", {
  df <- data.frame(q1 = 1:3, q2 = 4:6, q3 = 7:9)

  # Non-data.frame
  expect_error(spv(1:10, c("q1", "q2")), "'data' must be a data frame")

  # Duplicated column names in data
  df_dup <- data.frame(q1 = 1:3, q2 = 4:6)
  names(df_dup) <- c("q1", "q1")
  expect_error(spv(df_dup, c("q1", "q1")), "Column names in 'data' must be unique")

  # columns validation
  expect_error(spv(df, 1:2), "'columns' must be a character vector")
  expect_error(spv(df, "q1"), "contain at least 2 column names")
  expect_error(spv(df, c("q1", NA)), "missing or empty")
  expect_error(spv(df, c("q1", "")), "missing or empty")
  expect_error(spv(df, c("q1", "q1")), "duplicate column names")
  expect_error(spv(df, c("q1", "nonexistent")), "do not exist in 'data'")

  # result_column_name validation
  expect_error(spv(df, c("q1", "q2"), result_column_name = 123), "'result_column_name' must be a non-empty character string")
  expect_error(spv(df, c("q1", "q2"), result_column_name = "q1"), "already exists in 'data'")

  # Type rejections: mixed numeric and factor, character, logical
  df_mixed <- data.frame(q1 = 1:3, q2 = factor(c("a", "b", "c")))
  expect_error(spv(df_mixed, c("q1", "q2")), "must be numeric .* or all must be factors")

  df_chr <- data.frame(q1 = c("a", "b"), q2 = c("c", "d"))
  expect_error(spv(df_chr, c("q1", "q2")), "must be numeric .* or all must be factors")

  df_lgl <- data.frame(q1 = c(TRUE, FALSE), q2 = c(FALSE, TRUE))
  expect_error(spv(df_lgl, c("q1", "q2")), "must be numeric .* or all must be factors")

  # Non-finite values: Inf, -Inf, NaN
  df_inf <- data.frame(q1 = c(1, Inf), q2 = c(2, 3))
  expect_error(spv(df_inf, c("q1", "q2")), "contains non-finite values")

  df_nan <- data.frame(q1 = c(1, NaN), q2 = c(2, 3))
  expect_error(spv(df_nan, c("q1", "q2")), "contains non-finite values")
})
