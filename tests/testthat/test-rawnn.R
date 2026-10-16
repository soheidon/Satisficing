test_that("rawnn prints column indices and names correctly and returns invisible NULL", {
  df <- data.frame(a = 1:2, b = 3:4)

  # Check printed output
  out <- capture.output({
    ret <- withVisible(rawnn(df))
  })

  expect_true(any(grepl("1: a", out)))
  expect_true(any(grepl("2: b", out)))

  # Check invisible NULL
  expect_false(ret$visible)
  expect_null(ret$value)
})

test_that("rawnn raises error on non-data.frame argument", {
  expect_error(rawnn(c(1, 2, 3)), "'dataframe' must be a data frame")
  expect_error(rawnn("text"), "'dataframe' must be a data frame")
})

test_that("examples from documentation and README execute successfully", {
  expect_no_error(capture.output(rawnn(mtcars)))
  expect_no_error(capture.output(rawnn(iris)))
})
