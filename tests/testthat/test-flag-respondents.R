test_that("flag_respondents evaluates logical expressions with data-mask and caller-environment", {
  cutoff <- 10
  ind <- data.frame(
    id = c("A", "B", "C"),
    score1 = c(5, 15, 20),
    score2 = c(0.8, 0.2, 0.9),
    stringsAsFactors = FALSE
  )

  # Column from data, cutoff from caller environment
  flags <- flag_respondents(
    ind,
    high_score1 = score1 >= cutoff,
    high_score2 = score2 >= 0.75
  )

  expect_s3_class(flags, "data.frame")
  expect_named(flags, c("id", "high_score1", "high_score2"))
  expect_identical(flags$id, c("A", "B", "C"))
  expect_identical(flags$high_score1, c(FALSE, TRUE, TRUE))
  expect_identical(flags$high_score2, c(TRUE, FALSE, TRUE))
})

test_that("flag_respondents handles unnamed expressions using deparse", {
  ind <- data.frame(
    id = 1:2,
    x = c(1, 10),
    stringsAsFactors = FALSE
  )

  flags <- flag_respondents(ind, x > 5)
  expect_named(flags, c("id", "x > 5"))
  expect_identical(flags[["x > 5"]], c(FALSE, TRUE))
})

test_that("flag_respondents preserves column names without syntactic mangling", {
  ind <- data.frame(
    id = 1:2,
    val = c(1, 2)
  )

  flags <- flag_respondents(ind, `high value / raw` = val > 1)
  expect_true("high value / raw" %in% names(flags))
  expect_false("high.value...raw" %in% names(flags))
})

test_that("flag_respondents auto-retains 'id' column if present and id = NULL", {
  ind_with_id <- data.frame(id = 1:3, x = c(1, 2, 3))
  res1 <- flag_respondents(ind_with_id, f = x > 1)
  expect_named(res1, c("id", "f"))

  ind_no_id <- data.frame(subj = 1:3, x = c(1, 2, 3))
  res2 <- flag_respondents(ind_no_id, f = x > 1)
  expect_named(res2, c("f"))
})

test_that("flag_respondents retains specified id column at front", {
  ind <- data.frame(resp_id = c("r1", "r2"), score = c(5, 10), stringsAsFactors = FALSE)
  res <- flag_respondents(ind, flag_score = score >= 10, id = "resp_id")
  expect_named(res, c("resp_id", "flag_score"))
  expect_identical(res$resp_id, c("r1", "r2"))
})

test_that("flag_respondents preserves NA in logical evaluations", {
  ind <- data.frame(
    id = 1:3,
    score = c(10, NA, 5)
  )

  flags <- flag_respondents(ind, flag = score >= 8)
  expect_identical(flags$flag, c(TRUE, NA, FALSE))
})

test_that("flag_respondents strictly rejects non-logical evaluation results", {
  ind <- data.frame(id = 1:3, x = c(1, 2, 3), str = c("a", "b", "c"), stringsAsFactors = FALSE)

  # Numeric result (no truthy conversion)
  expect_error(flag_respondents(ind, x), "must evaluate to a logical vector")
  # Character result
  expect_error(flag_respondents(ind, str), "must evaluate to a logical vector")
})

test_that("flag_respondents strictly rejects length mismatch (no length-1 recycling)", {
  ind <- data.frame(id = 1:3, x = c(1, 2, 3))

  # Length 1 scalar logical
  expect_error(flag_respondents(ind, TRUE), "evaluated to length 1, but must have length 3")
  # Length 2 vector
  expect_error(flag_respondents(ind, c(TRUE, FALSE)), "evaluated to length 2, but must have length 3")
})

test_that("flag_respondents validates arguments and flags uniqueness", {
  ind <- data.frame(id = 1:2, x = c(1, 2))

  # Non-data.frame
  expect_error(flag_respondents(matrix(1:4, 2, 2), x > 1), "must be a data.frame")
  # Empty dots
  expect_error(flag_respondents(ind), "At least one condition must be provided")

  # Duplicate flag names
  expect_error(flag_respondents(ind, f = x > 1, f = x > 0), "Duplicate flag name detected")

  # Collision with ID column name
  ind_two <- data.frame(id = 1:2, my_id = c("a", "b"), x = c(1, 2))
  expect_error(flag_respondents(ind_two, my_id = x > 1, id = "my_id"), "conflicts with the ID column name")
  expect_error(flag_respondents(ind, my_id = x > 1, id = "my_id"), "Specified ID column 'my_id' was not found")

  # ID column not found
  expect_error(flag_respondents(ind, f = x > 1, id = "nonexistent"), "not found in 'indicators'")
  # Invalid ID format
  expect_error(flag_respondents(ind, f = x > 1, id = 123), "single non-empty character string")
  expect_error(flag_respondents(ind, f = x > 1, id = c("a", "b")), "single non-empty character string")
})

test_that("flag_respondents handles 0-row data.frame correctly", {
  ind_empty <- data.frame(id = character(0), score = numeric(0), stringsAsFactors = FALSE)
  flags_empty <- flag_respondents(ind_empty, flag_score = score >= 10)

  expect_equal(nrow(flags_empty), 0L)
  expect_named(flags_empty, c("id", "flag_score"))
  expect_type(flags_empty$id, "character")
  expect_type(flags_empty$flag_score, "logical")
})

test_that("flag_respondents output conforms to resquin::flag_resp fixture shape", {
  # A data.frame with id and logical columns
  ind <- data.frame(id = c(101, 102), speeder = c(15, 35))
  flags <- flag_respondents(ind, flag_speed = speeder < 20)

  expect_s3_class(flags, "data.frame")
  expect_equal(colnames(flags), c("id", "flag_speed"))
  expect_type(flags$flag_speed, "logical")
})
