# Tests for Kim et al. (2019) Straightlining Measures Compatibility and straightliner API
# Reference: Kim, Y., Dykema, J., Stevenson, J., Black, P., & Moberg, D. P. (2019).
# Straightlining: Overview of Measurement, Comparison of Indicators, and Effects in Mail–Web Mixed-Mode Surveys.
# Social Science Computer Review, 37(2), 214–233. DOI: 10.1177/0894439317752406
#
# Reference oracle snapshot: mweylandt/straightliner (commit 2873384c8bc54aec48abb54e9543c408723fbe0a)
# Archive URL: https://github.com/mweylandt/straightliner/archive/2873384c8bc54aec48abb54e9543c408723fbe0a.zip
# Archive SHA-256: 936B49347FE7E02A8B30CFF3C1F7BA6A754F57F797F9B389F6190F5275E2B2C4
#
# Canonical functions aligned with straightliner:
#   - maxIdenticalRating
#   - scale_point_variation
#   - question_sd
#   - nondiff
#   - straightlining
#   - straightlining_qset
#   - meanRootPairs (Kim paper formula, reference commit code-level comparison unverified due to known bugs)
#
# Legacy compatibility functions:
#   - mir (wraps maxIdenticalRating in data frame return)
#   - spv (wraps scale_point_variation in data frame return)
#   - mrp (wraps meanRootPairs in data frame return)
#   - stline (original integer flag API preserved)
#   - irv (original SD API preserved)

test_that("BFI-35 style 35-item batteries evaluate expected values across straightlining measures", {
  # 1. Complete identical: all 3s
  row1 <- rep(3, 35)
  # 2. 20 of 3, 15 of 4 (block)
  row2 <- c(rep(3, 20), rep(4, 15))
  # 3. Alternating 3 and 4 with same total frequencies (20 of 3, 15 of 4)
  row3 <- as.vector(rbind(rep(3, 15), rep(4, 15)))
  row3 <- c(row3, rep(3, 5))
  # 4. 30 of 3, plus 1, 2, 4, 5, 5
  row4 <- c(rep(3, 30), 1, 2, 4, 5, 5)
  # 5. Equal usage: 7 of each 1, 2, 3, 4, 5
  row5 <- c(rep(1, 7), rep(2, 7), rep(3, 7), rep(4, 7), rep(5, 7))
  # 6. Partial missing: 30 of 3, 5 NAs
  row6 <- c(rep(3, 30), rep(NA_real_, 5))
  # 7. 1 valid response: 1 of 3, 34 NAs
  row7 <- c(3, rep(NA_real_, 34))
  # 8. All NAs
  row8 <- rep(NA_real_, 35)

  df_bfi <- as.data.frame(rbind(row1, row2, row3, row4, row5, row6, row7, row8))
  names(df_bfi) <- paste0("q", 1:35)
  cols <- names(df_bfi)

  # 1. stline vs nondiff
  res_st <- stline(df_bfi, cols)$straight_line
  expect_identical(res_st, c(1L, 0L, 0L, 0L, 0L, 1L, NA_integer_, NA_integer_))

  res_nd <- nondiff(df_bfi, cols, verbose = FALSE)
  expect_identical(res_nd, c(TRUE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, TRUE))

  # 2. maxIdenticalRating and mir
  res_mir_vec <- maxIdenticalRating(df_bfi, cols, verbose = FALSE)
  res_mir_df <- mir(df_bfi, cols)$mir
  expect_equal(res_mir_vec, res_mir_df, tolerance = 1e-10)

  expect_equal(res_mir_vec[1], 1.0, tolerance = 1e-10)
  expect_equal(res_mir_vec[2], 20 / 35, tolerance = 1e-10)
  expect_equal(res_mir_vec[3], 20 / 35, tolerance = 1e-10)
  expect_equal(res_mir_vec[4], 30 / 35, tolerance = 1e-10)
  expect_equal(res_mir_vec[5], 7 / 35, tolerance = 1e-10)
  expect_equal(res_mir_vec[6], 30 / 35, tolerance = 1e-10)
  expect_equal(res_mir_vec[7], 1 / 35, tolerance = 1e-10)
  expect_true(is.na(res_mir_vec[8]))

  # 3. scale_point_variation and spv
  res_spv_vec <- scale_point_variation(df_bfi, cols, verbose = FALSE)
  res_spv_df <- spv(df_bfi, cols)$spv
  expect_equal(res_spv_vec, res_spv_df, tolerance = 1e-10)

  expect_equal(res_spv_vec[1], 0.0, tolerance = 1e-10)
  expect_equal(res_spv_vec[2], 1 - ((20/35)^2 + (15/35)^2), tolerance = 1e-10)
  expect_equal(res_spv_vec[3], 1 - ((20/35)^2 + (15/35)^2), tolerance = 1e-10)
  expect_equal(res_spv_vec[5], 1 - 5 * (7/35)^2, tolerance = 1e-10) # 0.8
  expect_equal(res_spv_vec[6], 1 - ((30/35)^2 + (5/35)^2), tolerance = 1e-10)
  expect_equal(res_spv_vec[7], 1 - ((1/35)^2 + (34/35)^2), tolerance = 1e-10)
  expect_equal(res_spv_vec[8], 0.0, tolerance = 1e-10)

  # 4. question_sd and irv
  res_qsd <- question_sd(df_bfi, cols, verbose = FALSE)
  res_irv <- unname(irv(df_bfi, na.rm = TRUE))
  expect_equal(res_qsd, res_irv, tolerance = 1e-10)
  expect_equal(res_qsd[1], 0.0, tolerance = 1e-10)
  expect_equal(res_qsd[2], stats::sd(row2), tolerance = 1e-10)
  expect_equal(res_qsd[3], stats::sd(row3), tolerance = 1e-10)
  expect_equal(res_qsd[6], 0.0, tolerance = 1e-10)
  expect_true(is.na(res_qsd[7]))
  expect_true(is.na(res_qsd[8]))

  # 5. meanRootPairs and mrp
  res_mrp_vec <- meanRootPairs(df_bfi, cols, verbose = FALSE)
  res_mrp_df <- mrp(df_bfi, cols)$mrp
  expect_equal(res_mrp_vec, res_mrp_df, tolerance = 1e-10)
  expect_equal(res_mrp_vec[1], 1.0, tolerance = 1e-10) # complete straightlining = 1.0 (max)
  expect_equal(res_mrp_vec[2], res_mrp_vec[3], tolerance = 1e-10)
  expect_equal(res_mrp_vec[5], 0.0, tolerance = 1e-10) # maximum differentiation = 0.0 (min)
  expect_equal(res_mrp_vec[6], 1.0, tolerance = 1e-10)
  expect_true(is.na(res_mrp_vec[7]))
  expect_true(is.na(res_mrp_vec[8]))
})

test_that("straightliner commit 2873384 oracle values match Satisficing canonical and legacy functions", {
  # Oracle generated directly from mweylandt/straightliner commit 2873384c8bc54aec48abb54e9543c408723fbe0a
  # on careless_dataset[1:10, 1:10]
  data("careless_dataset", package = "Satisficing")
  sub_df <- careless_dataset[1:10, 1:10]
  cols <- names(sub_df)

  oracle_mir <- c(0.5, 0.3, 0.4, 0.4, 0.5, 0.4, 0.4, 0.5, 0.6, 0.3)
  oracle_spv <- c(0.62, 0.74, 0.72, 0.7, 0.68, 0.74, 0.66, 0.64, 0.56, 0.76)
  oracle_sd <- c(
    0.737864787372622, 1.26929551764398, 1.15950180872841, 0.948683298050514,
    1.22927259430572, 1.49443411809733, 0.994428926011753, 1.08012344973464,
    1.83787316694536, 1.34989711542111
  )
  oracle_nondiff <- rep(FALSE, 10)

  # Check canonical functions
  expect_equal(maxIdenticalRating(sub_df, verbose = FALSE), oracle_mir, tolerance = 1e-10)
  expect_equal(scale_point_variation(sub_df, verbose = FALSE), oracle_spv, tolerance = 1e-10)
  expect_equal(question_sd(sub_df, verbose = FALSE), oracle_sd, tolerance = 1e-10)
  expect_identical(nondiff(sub_df, verbose = FALSE), oracle_nondiff)

  # Check legacy compatibility wrappers
  expect_equal(mir(sub_df, cols)$mir, oracle_mir, tolerance = 1e-10)
  expect_equal(spv(sub_df, cols)$spv, oracle_spv, tolerance = 1e-10)
  expect_equal(unname(irv(sub_df, na.rm = TRUE)), oracle_sd, tolerance = 1e-10)
  expect_identical(stline(sub_df, cols)$straight_line, as.integer(oracle_nondiff))

  # Check straightlining()
  sl_res <- straightlining(sub_df, measures = c("mir", "qsd", "spv", "nondiff"))
  expect_named(sl_res, c("mir", "qsd", "spv", "nondiff"))
  expect_equal(sl_res$mir, oracle_mir, tolerance = 1e-10)
  expect_equal(sl_res$qsd, oracle_sd, tolerance = 1e-10)
  expect_equal(sl_res$spv, oracle_spv, tolerance = 1e-10)
  expect_identical(sl_res$nondiff, oracle_nondiff)

  # Check straightlining_qset()
  bset <- list(b1 = 1:5, b2 = 6:10)
  qset_res <- straightlining_qset(sub_df, variable_list = bset,
                                 measures = c("mir", "qsd", "spv", "nondiff"),
                                 verbose = FALSE)
  expect_s3_class(qset_res, "straightliner")
  expect_equal(rownames(qset_res), c("b1", "b2"))
  expect_equal(qset_res$mir, c(0.46, 0.52), tolerance = 1e-10)
  expect_equal(qset_res$qsd, c(1.29776226, 1.03828238), tolerance = 1e-6)
  expect_equal(qset_res$spv, c(0.632, 0.584), tolerance = 1e-10)
  expect_equal(qset_res$nondiff, c(0, 0), tolerance = 1e-10)
  expect_equal(qset_res$spv_max, c(0.72, 0.72), tolerance = 1e-10)
})

test_that("meanRootPairs adheres to Kim et al. (2019) paper formula; straightliner commit 2873384 code-level comparison is unverified due to known flaws", {
  # In mweylandt/straightliner commit 2873384c8bc54aec48abb54e9543c408723fbe0a:
  # 1. R/MRP.R line 74 calls mrp_t = sqrt(sums)/length(vars), where 'vars' is undefined
  #    in function scope (evaluating to length(dplyr::vars) = 1 in package namespace,
  #    or failing with 'object vars not found' when sourced standalone).
  # 2. R/MRP.R calculates sqrt(sums), which takes the square root of the sum of pairwise differences,
  #    deviating from Kim et al. (2019, p. 217) and straightliner's own README:
  #      T_i = (2 / (n_i * (n_i - 1))) * sum_{j < k} sqrt(|x_ij - x_ik|)
  #    i.e. the sum of square roots of absolute differences.
  # Due to these flaws, code-level numerical comparison with straightliner's MRP implementation is unverified.
  #
  # Satisficing's meanRootPairs() strictly implements Kim et al. (2019) paper formula:
  df_hand <- data.frame(
    q1 = c(3, 1, 1),
    q2 = c(3, 1, 1),
    q3 = c(4, 1, 1),
    q4 = c(4, 1, 2)
  )
  # Row 1: x = (3, 3, 4, 4), pairwise sqrt diffs: (0, 1, 1, 1, 1, 0) -> sum = 4, 6 pairs -> T_1 = 4/6 = 2/3
  # Row 2: x = (1, 1, 1, 1), all diffs 0 -> T_2 = 0
  # Row 3: x = (1, 1, 1, 2), diffs: (0, 0, 1, 0, 1, 1) -> sum = 3, 6 pairs -> T_3 = 3/6 = 0.5
  # Normalization: min(T) = 0, max(T) = 2/3
  # Row 1: (2/3 - 2/3) / (2/3 - 0) = 0.0
  # Row 2: (2/3 - 0)   / (2/3 - 0) = 1.0 (complete straightlining / max MRP)
  # Row 3: (2/3 - 0.5) / (2/3 - 0) = 0.25
  res_hand <- meanRootPairs(df_hand, verbose = FALSE)
  expect_equal(res_hand, c(0.0, 1.0, 0.25), tolerance = 1e-10)

  # Check column permutation invariance
  res_perm <- meanRootPairs(df_hand, varnames = c("q4", "q1", "q3", "q2"), verbose = FALSE)
  expect_equal(res_perm, res_hand, tolerance = 1e-10)

  # Constant sample returns NA
  df_const <- data.frame(q1 = c(2, 2), q2 = c(2, 2))
  expect_identical(meanRootPairs(df_const, verbose = FALSE), c(NA_real_, NA_real_))
})

test_that("nondiff and stline difference on partial missing and return types are documented", {
  df_part <- data.frame(
    q1 = c(1, 1, NA),
    q2 = c(1, 1, NA),
    q3 = c(1, NA, NA)
  )

  # nondiff returns logical vector:
  # Row 1: unique(1, 1, 1) -> length 1 -> TRUE
  # Row 2: unique(1, 1, NA) -> length 2 -> FALSE
  # Row 3: unique(NA, NA, NA) -> length 1 -> TRUE
  expect_identical(nondiff(df_part, verbose = FALSE), c(TRUE, FALSE, TRUE))

  # stline returns integer flag:
  # Row 1: 3 identical -> 1L
  # Row 2: 2 observed identical -> 1L (partial missing allows 1L if observed >= 2 identical)
  # Row 3: 0 observed -> NA_integer_
  expect_identical(stline(df_part, c("q1", "q2", "q3"))$straight_line, c(1L, 1L, NA_integer_))
})

test_that("Satisficing does not depend on or load straightliner", {
  desc_path <- testthat::test_path("../../DESCRIPTION")
  if (!file.exists(desc_path)) {
    desc_path <- system.file("DESCRIPTION", package = "Satisficing")
  }
  desc_deps <- read.dcf(desc_path)
  imports <- if ("Imports" %in% colnames(desc_deps)) desc_deps[1, "Imports"] else ""
  depends <- if ("Depends" %in% colnames(desc_deps)) desc_deps[1, "Depends"] else ""
  suggests <- if ("Suggests" %in% colnames(desc_deps)) desc_deps[1, "Suggests"] else ""

  expect_false(grepl("straightliner", imports))
  expect_false(grepl("straightliner", depends))
  expect_false(grepl("straightliner", suggests))
})
