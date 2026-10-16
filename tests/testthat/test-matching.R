test_that("matching evaluates condition and maps TRUE/FALSE/NA to 1/0/NA_integer_", {
  df <- data.frame(
    id = 1:4,
    score = c(10, 20, 30, NA)
  )

  res <- matching(df, score > 15)

  expect_s3_class(res, "data.frame")
  expect_identical(names(res), c("id", "score", "match"))
  expect_type(res$match, "integer")
  expect_identical(res$match, c(0L, 1L, 1L, NA_integer_))
  expect_identical(res[, 1:2], df)
})

test_that("matching supports custom result_col name", {
  df <- data.frame(val = c(1, 2, 3))
  res <- matching(df, val == 2, result_col = "is_two")
  expect_true("is_two" %in% names(res))
  expect_identical(res$is_two, c(0L, 1L, 0L))
})

test_that("matching handles 0-row and 1-row data frames", {
  # 0 rows
  df_0 <- data.frame(val = numeric(0))
  res_0 <- matching(df_0, val > 0)
  expect_equal(nrow(res_0), 0L)
  expect_identical(names(res_0), c("val", "match"))
  expect_type(res_0$match, "integer")

  # 1 row
  df_1 <- data.frame(val = 5)
  res_1 <- matching(df_1, val > 0)
  expect_equal(nrow(res_1), 1L)
  expect_identical(res_1$match, 1L)
})

test_that("matching raises error when condition length does not match nrow (no recycling)", {
  df_multi <- data.frame(val = 1:3)

  # Length 1 on multi-row data frame
  expect_error(
    matching(df_multi, TRUE),
    "Length of condition result \\(1\\) must match number of rows in 'data' \\(3\\)"
  )

  # Length 2 on length 3 data frame
  expect_error(
    matching(df_multi, c(TRUE, FALSE)),
    "Length of condition result \\(2\\) must match number of rows in 'data' \\(3\\)"
  )
})

test_that("matching raises error on non-logical conditions", {
  df <- data.frame(val = 1:3)
  expect_error(matching(df, val + 1), "'condition' must evaluate to a logical vector")
  expect_error(matching(df, "TRUE"), "'condition' must evaluate to a logical vector")
})

test_that("matching validates data and result_col arguments", {
  df <- data.frame(val = 1:2)

  # Invalid data
  expect_error(matching(list(val = 1), val > 0), "'data' must be a data frame")

  # Invalid result_col
  expect_error(matching(df, val > 0, result_col = 123), "'result_col' must be a non-empty character string")
  expect_error(matching(df, val > 0, result_col = c("a", "b")), "'result_col' must be a non-empty character string")
  expect_error(matching(df, val > 0, result_col = ""), "'result_col' must be a non-empty character string")
  expect_error(matching(df, val > 0, result_col = NA_character_), "'result_col' must be a non-empty character string")
  expect_error(matching(df, val > 0, result_col = "val"), "Column 'val' already exists in 'data'")
})

test_that("examples from documentation and README execute successfully", {
  # Help example
  df1 <- data.frame(ID = c(1, 2, 3, 4), Value = c(10, 20, 30, 40))
  expect_no_error(res1 <- matching(df1, Value > 20))
  expect_identical(res1$match, c(0L, 0L, 1L, 1L))

  # README example
  df2 <- data.frame(
    ID = 1:4,
    Age = c(25, 17, 30, NA),
    Employed = c(TRUE, FALSE, TRUE, TRUE)
  )
  expect_no_error(res2 <- matching(df2, Age >= 18, result_col = "adult"))
  expect_identical(res2$adult, c(1L, 0L, 1L, NA_integer_))
})
