test_that("canonical straightliner functions handle clean_data, column indices, and options", {
  # When clean_data = TRUE, factor levels should be consistent across columns
  levs <- c("1", "2", "3", "4", "5")
  df <- data.frame(
    id = 1:4,
    item1 = factor(c("5", "5", "3", "4"), levels = levs),
    item2 = factor(c("5", "5", "3", "4"), levels = levs),
    item3 = factor(c("5", "5", "3", "1"), levels = levs)
  )

  # suppressWarnings because straightliner's convert_data always emits warning when converting factors
  mir_res <- suppressWarnings(maxIdenticalRating(df, varnames = c("item1", "item2", "item3"), clean_data = TRUE, verbose = FALSE))
  expect_equal(mir_res, c(1.0, 1.0, 1.0, 2/3), tolerance = 1e-10)

  spv_res <- suppressWarnings(scale_point_variation(df, varnames = c("item1", "item2", "item3"), clean_data = TRUE, verbose = FALSE))
  expect_equal(spv_res, c(0.0, 0.0, 0.0, 1 - ((2/3)^2 + (1/3)^2)), tolerance = 1e-10)

  qsd_res <- suppressWarnings(question_sd(df, varnames = c("item1", "item2", "item3"), clean_data = TRUE, verbose = FALSE))
  expect_equal(qsd_res[1:3], c(0, 0, 0), tolerance = 1e-10)
  expect_true(qsd_res[4] > 0)

  nd_res <- suppressWarnings(nondiff(df, varnames = c("item1", "item2", "item3"), clean_data = TRUE, verbose = FALSE))
  expect_identical(nd_res, c(TRUE, TRUE, TRUE, FALSE))

  # Column indices instead of names
  nd_idx <- suppressWarnings(nondiff(df, varnames = 2:4, clean_data = TRUE, verbose = FALSE))
  expect_identical(nd_idx, nd_res)

  # straightlining with keep_original
  sl_keep <- suppressWarnings(straightlining(df, varnames = 2:4, measures = c("mir", "nondiff"), keep_original = TRUE))
  expect_equal(ncol(sl_keep), ncol(df) + 2L)
  expect_named(sl_keep, c(names(df), "mir", "nondiff"))

  sl_nokeep <- suppressWarnings(straightlining(df, varnames = 2:4, measures = c("mir", "nondiff"), keep_original = FALSE))
  expect_equal(ncol(sl_nokeep), 2L)
  expect_named(sl_nokeep, c("mir", "nondiff"))

  # reverse measure order tests (Round 13)
  sl_rev <- suppressWarnings(straightlining(df, varnames = 2:4, measures = c("spv", "mir"), keep_original = FALSE))
  expect_equal(ncol(sl_rev), 2L)
  expect_identical(names(sl_rev), c("mir", "spv"))
  expect_equal(sl_rev$mir, mir_res, tolerance = 1e-10)
  expect_equal(sl_rev$spv, spv_res, tolerance = 1e-10)

  sl_rev_keep <- suppressWarnings(straightlining(df, varnames = 2:4, measures = c("spv", "mir"), keep_original = TRUE))
  expect_equal(ncol(sl_rev_keep), ncol(df) + 2L)
  expect_identical(names(sl_rev_keep), c(names(df), "mir", "spv"))
  expect_equal(sl_rev_keep$mir, mir_res, tolerance = 1e-10)
  expect_equal(sl_rev_keep$spv, spv_res, tolerance = 1e-10)

  # 4-measure reverse order test
  sl_rev4 <- suppressWarnings(straightlining(df, varnames = 2:4, measures = c("nondiff", "spv", "qsd", "mir"), keep_original = FALSE))
  expect_identical(names(sl_rev4), c("mir", "qsd", "spv", "nondiff"))
  expect_equal(sl_rev4$mir, mir_res, tolerance = 1e-10)
  expect_equal(sl_rev4$qsd, qsd_res, tolerance = 1e-10)
  expect_equal(sl_rev4$spv, spv_res, tolerance = 1e-10)
  expect_identical(sl_rev4$nondiff, nd_res)

  # Oracle comparison with straightliner reference if available
  ref_lib <- file.path(rprojroot::find_root(rprojroot::is_r_package), "tmp", "v0.3.0", "straightliner_lib")
  if (dir.exists(ref_lib) && "straightliner" %in% rownames(installed.packages(lib.loc = ref_lib))) {
    sl_ns <- tryCatch(loadNamespace("straightliner", lib.loc = ref_lib), error = function(e) NULL)
    if (!is.null(sl_ns)) {
      ref_sl <- get("straightlining", envir = sl_ns)
      ref_rev <- suppressWarnings(ref_sl(df, varnames = 2:4, measures = c("spv", "mir"), keep_original = FALSE))
      expect_identical(names(sl_rev), names(ref_rev))
      expect_equal(sl_rev$mir, ref_rev$mir, tolerance = 1e-10)
      expect_equal(sl_rev$spv, ref_rev$spv, tolerance = 1e-10)

      ref_rev_keep <- suppressWarnings(ref_sl(df, varnames = 2:4, measures = c("spv", "mir"), keep_original = TRUE))
      expect_identical(names(sl_rev_keep), names(ref_rev_keep))
      expect_equal(sl_rev_keep$mir, ref_rev_keep$mir, tolerance = 1e-10)
      expect_equal(sl_rev_keep$spv, ref_rev_keep$spv, tolerance = 1e-10)
    }
  }

  # straightlining_qset
  bats <- list(bat1 = c("item1", "item2"), bat2 = c(3, 4))
  qset <- suppressWarnings(straightlining_qset(df, variable_list = bats, measures = c("mir", "qsd", "spv", "nondiff"), round_digits = 3, verbose = TRUE))
  expect_s3_class(qset, "straightliner")
  expect_equal(nrow(qset), 2L)
  expect_named(qset, c("mir", "qsd", "spv", "nondiff", "spv_max"))

  # print.straightliner method
  out <- utils::capture.output(print(qset))
  expect_true(any(grepl("bat1", out)))
  expect_true(any(grepl("bat2", out)))

  # Validation errors
  expect_error(straightlining_qset(df, variable_list = "not_a_list"), "supposed to be a named list")
  expect_error(straightlining_qset(df, variable_list = list(c(2, 3))), "supposed to be a named list")
})
