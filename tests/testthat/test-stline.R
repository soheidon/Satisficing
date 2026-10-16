test_that("stline detects straight-line responses across numeric columns", {
  df <- data.frame(
    id = 1:5,
    q1 = c(1, 2, 3, 4, NA),
    q2 = c(1, 2, 3, 5, NA),
    q3 = c(1, 2, 4, 6, 1)
  )

  res <- stline(df, c("q1", "q2", "q3"))

  expect_s3_class(res, "data.frame")
  expect_identical(names(res), c("id", "q1", "q2", "q3", "straight_line"))
  expect_type(res$straight_line, "integer")
  expect_identical(res$straight_line, c(1L, 1L, 0L, 0L, NA_integer_))
  # Check preservation of original columns and order
  expect_identical(res[, 1:4], df)
})

test_that("stline handles integer and double columns together as numeric", {
  df <- data.frame(
    q1 = c(1L, 2L, 3L),
    q2 = c(1.0, 2.0, 4.0)
  )
  res <- stline(df, c("q1", "q2"))
  expect_identical(res$straight_line, c(1L, 1L, 0L))
})

test_that("stline respects exclude_values", {
  df <- data.frame(
    q1 = c(1, 9, 2),
    q2 = c(1, 9, 2),
    q3 = c(1, 9, 3)
  )

  res <- stline(df, c("q1", "q2", "q3"), exclude_values = 9)
  expect_identical(res$straight_line, c(1L, 0L, 0L))

  res2 <- stline(df, c("q1", "q2", "q3"), exclude_values = c(1, 9))
  expect_identical(res2$straight_line, c(0L, 0L, 0L))
})

test_that("stline handles missing values correctly (0 or 1 valid value yields NA)", {
  df <- data.frame(
    q1 = c(NA, NA, 1, 1),
    q2 = c(NA, 1,  NA, 1),
    q3 = c(NA, NA, NA, 1)
  )

  res <- stline(df, c("q1", "q2", "q3"))
  expect_identical(res$straight_line, c(NA_integer_, NA_integer_, NA_integer_, 1L))
})

test_that("stline works with character, logical, and factor columns", {
  # Character
  df_chr <- data.frame(
    c1 = c("a", "a", "a"),
    c2 = c("a", "b", "a"),
    stringsAsFactors = FALSE
  )
  res_chr <- stline(df_chr, c("c1", "c2"), exclude_values = "a")
  expect_identical(res_chr$straight_line, c(0L, 0L, 0L))

  # Logical
  df_log <- data.frame(
    l1 = c(TRUE, TRUE, FALSE),
    l2 = c(TRUE, FALSE, FALSE)
  )
  res_log <- stline(df_log, c("l1", "l2"))
  expect_identical(res_log$straight_line, c(1L, 0L, 1L))

  # Factor with same levels and ordered attribute
  f1 <- factor(c("low", "med", "high"), levels = c("low", "med", "high"))
  f2 <- factor(c("low", "low", "high"), levels = c("low", "med", "high"))
  df_fac <- data.frame(f1 = f1, f2 = f2)
  res_fac <- stline(df_fac, c("f1", "f2"), exclude_values = "high")
  expect_identical(res_fac$straight_line, c(1L, 0L, 0L))
})

test_that("stline works with 0 rows data frame", {
  df_empty <- data.frame(q1 = numeric(0), q2 = numeric(0))
  res <- stline(df_empty, c("q1", "q2"))
  expect_equal(nrow(res), 0L)
  expect_identical(names(res), c("q1", "q2", "straight_line"))
  expect_type(res$straight_line, "integer")
})

test_that("stline supports custom result_column_name", {
  df <- data.frame(q1 = c(1, 2), q2 = c(1, 3))
  res <- stline(df, c("q1", "q2"), result_column_name = "flag")
  expect_true("flag" %in% names(res))
  expect_identical(res$flag, c(1L, 0L))
})

test_that("stline validates inputs and raises errors on invalid arguments", {
  df <- data.frame(q1 = c(1, 2), q2 = c(1, 3), q3 = c("a", "b"))

  # Non-data.frame
  expect_error(stline(list(q1 = 1), "q1"), "'data' must be a data frame")

  # Duplicate column names in data
  df_dup_names <- data.frame(q1 = c(1, 2), q1 = c(1, 2), check.names = FALSE)
  expect_error(
    stline(df_dup_names, "q1"),
    "contains duplicate column names, which causes ambiguous column selection"
  )

  # columns validation
  expect_error(stline(df, character(0)), "'columns' must be a non-empty character vector")
  expect_error(stline(df, 1:2), "'columns' must be a non-empty character vector")
  expect_error(stline(df, c("q1", "q1")), "'columns' must contain unique column names")
  expect_error(stline(df, c("q1", "missing_col")), "do not exist")
  expect_error(stline(df, c("q1", NA_character_)), "'columns' must be a non-empty character vector")

  # result_column_name validation
  expect_error(stline(df, c("q1", "q2"), result_column_name = 123), "'result_column_name' must be a non-empty character string")
  expect_error(stline(df, c("q1", "q2"), result_column_name = c("a", "b")), "'result_column_name' must be a non-empty character string")
  expect_error(stline(df, c("q1", "q2"), result_column_name = "q1"), "already exists")

  # Incompatible type groups across columns
  expect_error(stline(df, c("q1", "q3")), "must belong to the same type group")

  # Unsupported column types
  df_unsupported <- data.frame(q1 = c(1, 2))
  df_unsupported$lst <- list(1, 2)
  expect_error(stline(df_unsupported, c("q1", "lst")), "Unsupported column type")

  # Factor levels mismatch
  df_fac_mismatch <- data.frame(
    f1 = factor(c("a", "b"), levels = c("a", "b")),
    f2 = factor(c("a", "b"), levels = c("b", "a"))
  )
  expect_error(stline(df_fac_mismatch, c("f1", "f2")), "identical levels and ordered")

  # Factor ordered mismatch
  df_fac_ord <- data.frame(
    f1 = factor(c("a", "b"), levels = c("a", "b"), ordered = TRUE),
    f2 = factor(c("a", "b"), levels = c("a", "b"), ordered = FALSE)
  )
  expect_error(stline(df_fac_ord, c("f1", "f2")), "identical levels and ordered")

  # exclude_values validation
  expect_error(stline(df, c("q1", "q2"), exclude_values = list(1)), "'exclude_values' must be an atomic vector")
  expect_error(stline(df, c("q1", "q2"), exclude_values = "string"), "'exclude_values' must be compatible")
})

test_that("examples from documentation and README execute successfully", {
  df <- data.frame(
    q1 = c(1, 1, 1, 2, NA),
    q2 = c(1, 1, 2, 2, NA),
    q3 = c(1, 2, 3, 2, 1)
  )
  expect_no_error(res1 <- stline(df, c("q1", "q2", "q3")))
  expect_no_error(res2 <- stline(df, c("q1", "q2", "q3"), exclude_values = 2))
  expect_identical(res1$straight_line, c(1L, 0L, 0L, 1L, NA_integer_))
  expect_identical(res2$straight_line, c(1L, 0L, 0L, 0L, NA_integer_))
})
