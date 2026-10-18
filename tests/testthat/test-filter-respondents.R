test_that("filter_respondents requires explicit ID matching and detects common 'id'", {
  survey <- data.frame(id = 1:3, q1 = c(1, 2, 3), q2 = c(4, 5, 6))
  flags  <- data.frame(id = 1:3, flag1 = c(FALSE, TRUE, FALSE))

  res <- filter_respondents(survey, flags, strategy = "any")
  expect_named(res, c("data", "excluded", "audit"))
  expect_equal(nrow(res$data), 2L)
  expect_equal(nrow(res$excluded), 1L)
  expect_identical(res$data$id, c(1L, 3L))
  expect_identical(res$excluded$id, 2L)

  # Custom ID column
  survey_cust <- data.frame(uid = c("x", "y"), q1 = c(1, 2), stringsAsFactors = FALSE)
  flags_cust  <- data.frame(uid = c("x", "y"), f = c(TRUE, FALSE), stringsAsFactors = FALSE)
  res_cust <- filter_respondents(survey_cust, flags_cust, strategy = "any", id = "uid")
  expect_identical(res_cust$data$uid, "y")
  expect_identical(res_cust$excluded$uid, "x")

  # Missing common ID error
  survey_no_id <- data.frame(a = 1:2)
  flags_no_id  <- data.frame(b = 1:2, f = c(TRUE, FALSE))
  expect_error(filter_respondents(survey_no_id, flags_no_id, strategy = "any"), "No common 'id' column found")
})

test_that("filter_respondents aligns flags to data's ID order", {
  # Flags in reverse ID order
  survey <- data.frame(id = c("P1", "P2", "P3"), val = c(10, 20, 30), stringsAsFactors = FALSE)
  flags  <- data.frame(id = c("P3", "P1", "P2"), flag = c(TRUE, FALSE, FALSE), stringsAsFactors = FALSE)

  res <- filter_respondents(survey, flags, strategy = "any")
  # P3 is flagged, P1 and P2 retained
  expect_identical(res$data$id, c("P1", "P2"))
  expect_identical(res$excluded$id, "P3")
  # Audit table must follow survey ID order (P1, P2, P3)
  expect_identical(res$audit$id, c("P1", "P2", "P3"))
  expect_identical(res$audit$flag, c(FALSE, FALSE, TRUE))
  expect_identical(res$audit$excluded, c(FALSE, FALSE, TRUE))
})

test_that("filter_respondents strictly validates ID vector properties", {
  survey <- data.frame(id = 1:3, val = c(1, 2, 3))
  flags  <- data.frame(id = 1:3, flag = c(FALSE, FALSE, FALSE))

  # Missing values in ID
  s_na <- data.frame(id = c(1, NA, 3), val = 1:3)
  expect_error(filter_respondents(s_na, flags, "any"), "contains missing \\(NA\\) values")

  f_na <- data.frame(id = c(1, NA, 3), flag = c(FALSE, FALSE, FALSE))
  expect_error(filter_respondents(survey, f_na, "any"), "contains missing \\(NA\\) values")

  # Duplicates in ID
  s_dup <- data.frame(id = c(1, 1, 3), val = 1:3)
  expect_error(filter_respondents(s_dup, flags, "any"), "contains duplicate values")

  f_dup <- data.frame(id = c(1, 1, 3), flag = c(FALSE, FALSE, FALSE))
  expect_error(filter_respondents(survey, f_dup, "any"), "contains duplicate values")

  # Type mismatch
  f_char <- data.frame(id = c("1", "2", "3"), flag = c(FALSE, FALSE, FALSE), stringsAsFactors = FALSE)
  expect_error(filter_respondents(survey, f_char, "any"), "Type mismatch")

  # ID set mismatch (missing or extra)
  f_diff <- data.frame(id = c(1L, 2L, 4L), flag = c(FALSE, FALSE, FALSE))
  expect_error(filter_respondents(survey, f_diff, "any"), "do not match exactly")

  f_extra <- data.frame(id = 1:4, flag = c(FALSE, FALSE, FALSE, FALSE))
  expect_error(filter_respondents(survey, f_extra, "any"), "do not match exactly")
})

test_that("filter_respondents validates flag columns", {
  survey <- data.frame(id = 1:2, val = 1:2)

  # Flags with only ID (0 flag columns)
  flags_only_id <- data.frame(id = 1:2)
  expect_error(filter_respondents(survey, flags_only_id, "any"), "at least one logical flag column")

  # Flags with non-logical column
  flags_num <- data.frame(id = 1:2, f1 = c(1, 0))
  expect_error(filter_respondents(survey, flags_num, "any"), "not a logical column")
})

test_that("filter_respondents evaluates three-valued logic for strategy = 'any'", {
  survey <- data.frame(id = 1:4, val = 1:4)
  # Row 1: FALSE, FALSE -> FALSE
  # Row 2: TRUE, FALSE  -> TRUE
  # Row 3: TRUE, NA     -> TRUE (definite: at least one TRUE)
  # Row 4: FALSE, NA    -> NA (indeterminate)
  flags <- data.frame(
    id = 1:4,
    f1 = c(FALSE, TRUE, TRUE, FALSE),
    f2 = c(FALSE, FALSE, NA, NA)
  )

  # na_action = "error" should error on row 4
  expect_error(filter_respondents(survey, flags, strategy = "any", na_action = "error"), "decision is NA for 1 respondent")

  # na_action = "keep": row 4 kept (excluded = FALSE)
  res_keep <- filter_respondents(survey, flags, strategy = "any", na_action = "keep")
  expect_identical(res_keep$audit$decision, c(FALSE, TRUE, TRUE, NA))
  expect_identical(res_keep$audit$excluded, c(FALSE, TRUE, TRUE, FALSE))
  expect_identical(res_keep$data$id, c(1L, 4L))
  expect_identical(res_keep$excluded$id, c(2L, 3L))

  # na_action = "exclude": row 4 excluded (excluded = TRUE)
  res_excl <- filter_respondents(survey, flags, strategy = "any", na_action = "exclude")
  expect_identical(res_excl$audit$decision, c(FALSE, TRUE, TRUE, NA))
  expect_identical(res_excl$audit$excluded, c(FALSE, TRUE, TRUE, TRUE))
  expect_identical(res_excl$data$id, 1L)
  expect_identical(res_excl$excluded$id, c(2L, 3L, 4L))
})

test_that("filter_respondents evaluates three-valued logic for strategy = 'all'", {
  survey <- data.frame(id = 1:4, val = 1:4)
  # Row 1: TRUE, TRUE   -> TRUE
  # Row 2: FALSE, TRUE  -> FALSE
  # Row 3: FALSE, NA    -> FALSE (definite: at least one FALSE)
  # Row 4: TRUE, NA     -> NA (indeterminate)
  flags <- data.frame(
    id = 1:4,
    f1 = c(TRUE, FALSE, FALSE, TRUE),
    f2 = c(TRUE, TRUE, NA, NA)
  )

  # na_action = "error" should error on row 4
  expect_error(filter_respondents(survey, flags, strategy = "all", na_action = "error"), "decision is NA for 1 respondent")

  # na_action = "keep": row 4 kept
  res_keep <- filter_respondents(survey, flags, strategy = "all", na_action = "keep")
  expect_identical(res_keep$audit$decision, c(TRUE, FALSE, FALSE, NA))
  expect_identical(res_keep$audit$excluded, c(TRUE, FALSE, FALSE, FALSE))
  expect_identical(res_keep$data$id, c(2L, 3L, 4L))
  expect_identical(res_keep$excluded$id, 1L)

  # na_action = "exclude": row 4 excluded
  res_excl <- filter_respondents(survey, flags, strategy = "all", na_action = "exclude")
  expect_identical(res_excl$audit$decision, c(TRUE, FALSE, FALSE, NA))
  expect_identical(res_excl$audit$excluded, c(TRUE, FALSE, FALSE, TRUE))
  expect_identical(res_excl$data$id, c(2L, 3L))
  expect_identical(res_excl$excluded$id, c(1L, 4L))
})

test_that("filter_respondents evaluates three-valued logic for strategy = 'at_least'", {
  survey <- data.frame(id = 1:5, val = 1:5)
  # 3 flags, n = 2
  # Row 1: TRUE, TRUE, FALSE (t=2, m=0) -> t>=2 -> TRUE
  # Row 2: TRUE, TRUE, NA    (t=2, m=1) -> t>=2 -> TRUE (definite)
  # Row 3: FALSE, FALSE, FALSE (t=0, m=0) -> t+m=0 < 2 -> FALSE
  # Row 4: FALSE, FALSE, NA  (t=0, m=1) -> t+m=1 < 2 -> FALSE (definite)
  # Row 5: TRUE, FALSE, NA   (t=1, m=1) -> t<2 and t+m=2 >= 2 -> NA (indeterminate)
  flags <- data.frame(
    id = 1:5,
    f1 = c(TRUE,  TRUE,  FALSE, FALSE, TRUE),
    f2 = c(TRUE,  TRUE,  FALSE, FALSE, FALSE),
    f3 = c(FALSE, NA,    FALSE, NA,    NA)
  )

  # Error if n is missing or invalid for at_least
  expect_error(filter_respondents(survey, flags, strategy = "at_least"), "'n' must be a single integer")
  expect_error(filter_respondents(survey, flags, strategy = "at_least", n = 0), "between 1 and 3")
  expect_error(filter_respondents(survey, flags, strategy = "at_least", n = 4), "between 1 and 3")
  expect_error(filter_respondents(survey, flags, strategy = "at_least", n = 1.5), "between 1 and 3")

  # Error if n is specified for any or all
  expect_error(filter_respondents(survey, flags, strategy = "any", n = 2), "'n' must only be specified when strategy = 'at_least'")
  expect_error(filter_respondents(survey, flags, strategy = "all", n = 2), "'n' must only be specified when strategy = 'at_least'")

  # na_action = "keep"
  res_keep <- filter_respondents(survey, flags, strategy = "at_least", n = 2, na_action = "keep")
  expect_identical(res_keep$audit$decision, c(TRUE, TRUE, FALSE, FALSE, NA))
  expect_identical(res_keep$audit$excluded, c(TRUE, TRUE, FALSE, FALSE, FALSE))
  expect_identical(res_keep$data$id, c(3L, 4L, 5L))
  expect_identical(res_keep$excluded$id, c(1L, 2L))
})

test_that("audit table adheres strictly to the 10+ column schema and types", {
  survey <- data.frame(id = c("A", "B"), q1 = c(10, 20), stringsAsFactors = FALSE)
  flags  <- data.frame(id = c("A", "B"), flagA = c(TRUE, FALSE), flagB = c(NA, FALSE), stringsAsFactors = FALSE)

  res <- filter_respondents(survey, flags, strategy = "any", na_action = "keep")
  audit <- res$audit

  expected_cols <- c(
    "id", "row_index", "flagA", "flagB",
    "n_flagged", "n_missing_flags", "decision",
    "strategy", "n_required", "na_action", "excluded"
  )
  expect_named(audit, expected_cols)
  expect_identical(audit$row_index, 1:2)
  expect_type(audit$n_flagged, "integer")
  expect_type(audit$n_missing_flags, "integer")
  expect_type(audit$decision, "logical")
  expect_type(audit$strategy, "character")
  expect_type(audit$n_required, "integer")
  expect_type(audit$na_action, "character")
  expect_type(audit$excluded, "logical")

  expect_identical(audit$n_flagged, c(1L, 0L))
  expect_identical(audit$n_missing_flags, c(1L, 0L))
  expect_identical(audit$n_required, c(1L, 1L))
})

test_that("filter_respondents preserves input data objects and handles 0-row data", {
  survey <- data.frame(id = 1:2, v = c("a", "b"), stringsAsFactors = FALSE)
  flags  <- data.frame(id = 1:2, f = c(FALSE, TRUE))

  # Check that input objects are unmodified
  orig_survey <- survey
  orig_flags  <- flags
  res <- filter_respondents(survey, flags, strategy = "any")
  expect_identical(survey, orig_survey)
  expect_identical(flags, orig_flags)

  # 0-row data
  s_empty <- data.frame(id = integer(0), v = character(0), stringsAsFactors = FALSE)
  f_empty <- data.frame(id = integer(0), f = logical(0))
  res_empty <- filter_respondents(s_empty, f_empty, strategy = "any")
  expect_equal(nrow(res_empty$data), 0L)
  expect_equal(nrow(res_empty$excluded), 0L)
  expect_equal(nrow(res_empty$audit), 0L)
  expect_named(res_empty$audit, c(
    "id", "row_index", "f", "n_flagged", "n_missing_flags",
    "decision", "strategy", "n_required", "na_action", "excluded"
  ))
})

test_that("integration workflow chains semantic_inconsistency, flag_respondents, and filter_respondents", {
  survey_data <- data.frame(
    id = 1:5,
    q1 = c(5, 5, 1, 3, 2),
    q2 = c(5, 1, 5, 3, 2),
    q3 = c(1, 5, 5, 3, 4),
    response_time = c(120, 45, 150, 30, 200)
  )

  item_pairs <- data.frame(
    item1 = c("q1", "q1"),
    item2 = c("q2", "q3"),
    relation = c("same", "opposite"),
    stringsAsFactors = FALSE
  )

  # Step 1: Semantic Inconsistency
  sem <- semantic_inconsistency(survey_data, item_pairs, scale_min = 1, scale_max = 5)

  # Step 2: Combine indicators and Flag
  indicators <- data.frame(
    id = survey_data$id,
    speed = survey_data$response_time,
    mean_inc = sem$mean_inconsistency
  )

  flags <- flag_respondents(
    indicators,
    flag_speed = speed < 60,
    flag_inc = mean_inc >= 0.75
  )
  expect_named(flags, c("id", "flag_speed", "flag_inc"))

  # Step 3: Filter respondents
  filtered <- filter_respondents(survey_data, flags, strategy = "any", na_action = "error")
  expect_named(filtered, c("data", "excluded", "audit"))

  # Row 2 (speed=45 < 60, inc=1.0 >= 0.75) -> excluded
  # Row 3 (inc=0.5 < 0.75, speed=150) -> kept
  # Row 4 (speed=30 < 60) -> excluded
  expect_identical(filtered$excluded$id, c(2L, 4L))
  expect_identical(filtered$data$id, c(1L, 3L, 5L))
})

test_that("filter_respondents rejects all reserved audit column names when used as ID column", {
  reserved <- c("row_index", "n_flagged", "n_missing_flags",
                "decision", "strategy", "n_required",
                "na_action", "excluded")
  for (res_name in reserved) {
    survey <- data.frame(val = 1:2)
    survey[[res_name]] <- c(101L, 102L)
    flags <- data.frame(f = c(FALSE, TRUE))
    flags[[res_name]] <- c(101L, 102L)

    expect_error(
      filter_respondents(survey, flags, strategy = "any", id = res_name),
      sprintf("ID column name '%s' conflicts with reserved audit table column name", res_name)
    )
  }
})

test_that("filter_respondents rejects all reserved audit column names when used as flag column", {
  reserved <- c("row_index", "n_flagged", "n_missing_flags",
                "decision", "strategy", "n_required",
                "na_action", "excluded")
  for (res_name in reserved) {
    survey <- data.frame(id = 1:2, val = 1:2)
    flags <- data.frame(id = 1:2)
    flags[[res_name]] <- c(FALSE, TRUE)

    expect_error(
      filter_respondents(survey, flags, strategy = "any"),
      sprintf("Flag column name\\(s\\) conflict with reserved audit table column name\\(s\\): '%s'", res_name)
    )
  }
})

test_that("filter_respondents rejects multiple flag column collisions listing all conflicting names", {
  survey <- data.frame(id = 1:2, val = 1:2)
  flags <- data.frame(
    id = 1:2,
    decision = c(FALSE, TRUE),
    excluded = c(TRUE, FALSE),
    valid_flag = c(FALSE, FALSE)
  )
  expect_error(
    filter_respondents(survey, flags, strategy = "any"),
    "Flag column name\\(s\\) conflict with reserved audit table column name\\(s\\): 'decision', 'excluded'"
  )
})

test_that("filter_respondents preserves schema, column order, and values with standard 'id' and non-reserved flag names", {
  survey <- data.frame(id = c("R1", "R2"), score = c(10, 20), stringsAsFactors = FALSE)
  flags <- data.frame(
    id = c("R1", "R2"),
    flag_speed = c(FALSE, TRUE),
    flag_straightline = c(FALSE, FALSE),
    stringsAsFactors = FALSE
  )

  res <- filter_respondents(survey, flags, strategy = "any", na_action = "error")
  expect_named(res, c("data", "excluded", "audit"))

  # Exact expected audit column names and order
  expected_cols <- c("id", "row_index", "flag_speed", "flag_straightline",
                     "n_flagged", "n_missing_flags", "decision", "strategy",
                     "n_required", "na_action", "excluded")
  expect_identical(colnames(res$audit), expected_cols)

  # Check audit values
  expect_identical(res$audit$id, c("R1", "R2"))
  expect_identical(res$audit$row_index, 1:2)
  expect_identical(res$audit$flag_speed, c(FALSE, TRUE))
  expect_identical(res$audit$flag_straightline, c(FALSE, FALSE))
  expect_identical(res$audit$n_flagged, c(0L, 1L))
  expect_identical(res$audit$n_missing_flags, c(0L, 0L))
  expect_identical(res$audit$decision, c(FALSE, TRUE))
  expect_identical(res$audit$strategy, c("any", "any"))
  expect_identical(res$audit$n_required, c(1L, 1L))
  expect_identical(res$audit$na_action, c("error", "error"))
  expect_identical(res$audit$excluded, c(FALSE, TRUE))
})
