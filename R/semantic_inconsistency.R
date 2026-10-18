#' Semantic Inconsistency across Item Pairs
#'
#' Evaluates semantic response inconsistency across user-specified item pairs
#' with expected directional relationships (\code{"same"} or \code{"opposite"}).
#' Inconsistency scores are normalized to the theoretical scale range \eqn{[0, 1]},
#' where 0 represents complete consistency and 1 represents maximal inconsistency.
#'
#' @details
#' For a scale bounded by \eqn{[L, U]} with theoretical range \eqn{R = U - L},
#' the inconsistency between responses \eqn{x_i} and \eqn{x_j} for a valid pair is:
#' \itemize{
#'   \item \strong{Same direction} (\code{"same"}):
#'     \deqn{\frac{|x_i - x_j|}{U - L}}
#'   \item \strong{Opposite direction} (\code{"opposite"}):
#'     \deqn{\frac{|(x_i - L) - (U - x_j)|}{U - L}}
#' }
#' Both formulas are symmetric with respect to item ordering. While algebraically
#' equivalent to \eqn{\frac{|x_i + x_j - (L + U)|}{U - L}}, the centered difference
#' formulation \eqn{\frac{|(x_i - L) - (U - x_j)|}{U - L}} is evaluated directly for numerical stability.
#'
#' When \code{details = FALSE}, the function returns a data frame with one row per respondent
#' containing the following columns in fixed order:
#' \enumerate{
#'   \item \code{mean_inconsistency} (double): Mean of inconsistency scores across valid pairs.
#'   \item \code{max_inconsistency} (double): Maximum inconsistency score among valid pairs.
#'   \item \code{sum_inconsistency} (double): Sum of inconsistency scores across valid pairs.
#'   \item \code{n_valid_pairs} (integer): Number of pairs where both items have non-missing responses.
#'   \item \code{n_missing_pairs} (integer): Number of pairs where at least one item is missing (\code{NA}).
#'   \item \code{n_high_inconsistency} (integer): Number of valid pairs with inconsistency \eqn{\ge} \code{threshold}.
#'   \item \code{prop_high_inconsistency} (double): Proportion of high-inconsistency pairs among valid pairs.
#' }
#' If \code{n_valid_pairs < min_valid_pairs}, the score and threshold columns (1--3, 6--7)
#' are set to \code{NA} of their respective types (\code{NA_real_} or \code{NA_integer_}),
#' while \code{n_valid_pairs} and \code{n_missing_pairs} report the observed counts.
#'
#' When \code{details = TRUE}, the function returns a named list with:
#' \itemize{
#'   \item \code{respondents}: The respondent-level data frame described above.
#'   \item \code{pairs}: A long data frame in row-major order (respondent order of \code{data},
#'     and pair order of \code{pairs} within each respondent) with columns:
#'     \code{respondent_row} (integer), \code{pair_id} (integer), \code{item1} (character),
#'     \code{item2} (character), \code{relation} (character), and \code{inconsistency} (double).
#' }
#'
#' \strong{Methodological Note}: Semantic inconsistency scores indicate pattern divergence
#' from researcher-defined item relationships; they do not definitively establish careless
#' or insufficient-effort responding. Items may be included in multiple pairs, but resulting
#' scores are correlated and should not be treated as independent evidence.
#'
#' @param data A data frame or matrix where rows represent respondents and columns represent survey items.
#' @param pairs A data frame with at least columns \code{item1}, \code{item2}, and \code{relation}.
#'   Each row defines an item pair. \code{relation} must be either \code{"same"} or \code{"opposite"}
#'   (case-sensitive). Self-pairs and duplicate pairs (regardless of item order) are not permitted.
#' @param scale_min A finite numeric scalar indicating the theoretical minimum of the response scale.
#' @param scale_max A finite numeric scalar indicating the theoretical maximum of the response scale
#'   (\code{scale_min < scale_max}).
#' @param threshold A finite numeric scalar in \eqn{[0, 1]} used to classify pairs as highly inconsistent
#'   (inconsistency \eqn{\ge} \code{threshold}). Defaults to \code{0.75} as an illustrative default,
#'   not a validated cutoff.
#' @param min_valid_pairs An integer scalar \eqn{\ge 1} specifying the minimum number of valid pairs
#'   required to compute respondent-level summary scores. Defaults to \code{1L}.
#' @param details Logical scalar; if \code{TRUE}, returns a list containing respondent-level summaries
#'   and detailed pair-level evaluations. Defaults to \code{FALSE}.
#'
#' @return When \code{details = FALSE}, a data frame of respondent-level summaries.
#'   When \code{details = TRUE}, a named list with elements \code{respondents} and \code{pairs}.
#'
#' @export
#' @examples
#' df <- data.frame(
#'   q1 = c(5, 5, 1, 3),
#'   q2 = c(5, 1, 5, 3),
#'   q3 = c(1, 5, 5, 3)
#' )
#' item_pairs <- data.frame(
#'   item1 = c("q1", "q1"),
#'   item2 = c("q2", "q3"),
#'   relation = c("same", "opposite"),
#'   stringsAsFactors = FALSE
#' )
#' semantic_inconsistency(df, item_pairs, scale_min = 1, scale_max = 5)
semantic_inconsistency <- function(data,
                                   pairs,
                                   scale_min,
                                   scale_max,
                                   threshold = 0.75,
                                   min_valid_pairs = 1L,
                                   details = FALSE) {
  # 1. Validate scale_min, scale_max
  if (!is.numeric(scale_min) || length(scale_min) != 1L || !is.finite(scale_min)) {
    stop("'scale_min' must be a single finite numeric value.", call. = FALSE)
  }
  if (!is.numeric(scale_max) || length(scale_max) != 1L || !is.finite(scale_max)) {
    stop("'scale_max' must be a single finite numeric value.", call. = FALSE)
  }
  if (scale_min >= scale_max) {
    stop("'scale_min' must be strictly less than 'scale_max'.", call. = FALSE)
  }
  scale_range <- scale_max - scale_min
  if (!is.finite(scale_range) || scale_range <= 0) {
    stop("Scale range ('scale_max - scale_min') must be finite and positive.", call. = FALSE)
  }

  # 2. Validate threshold
  if (!is.numeric(threshold) || length(threshold) != 1L || !is.finite(threshold) ||
      threshold < 0 || threshold > 1) {
    stop("'threshold' must be a single finite numeric value between 0 and 1.", call. = FALSE)
  }

  # 3. Validate min_valid_pairs
  if (!is.numeric(min_valid_pairs) || length(min_valid_pairs) != 1L ||
      is.na(min_valid_pairs) || !is.finite(min_valid_pairs) ||
      min_valid_pairs < 1 || min_valid_pairs > .Machine$integer.max ||
      min_valid_pairs != floor(min_valid_pairs)) {
    stop("'min_valid_pairs' must be a single integer >= 1 (within integer range).", call. = FALSE)
  }
  min_valid_pairs <- as.integer(min_valid_pairs)

  # 4. Validate details
  if (!is.logical(details) || length(details) != 1L || is.na(details)) {
    stop("'details' must be a single non-missing logical value (TRUE or FALSE).", call. = FALSE)
  }

  # 5. Validate pairs data.frame
  if (!is.data.frame(pairs)) {
    stop("'pairs' must be a data.frame.", call. = FALSE)
  }
  req_cols <- c("item1", "item2", "relation")
  if (!all(req_cols %in% names(pairs))) {
    stop("'pairs' must contain columns 'item1', 'item2', and 'relation'.", call. = FALSE)
  }
  n_pairs <- nrow(pairs)
  if (n_pairs < 1L) {
    stop("'pairs' must contain at least one item pair (nrow >= 1).", call. = FALSE)
  }

  item1 <- pairs$item1
  item2 <- pairs$item2
  relation <- pairs$relation

  if (!is.character(item1) && !is.factor(item1)) {
    stop("'item1' in 'pairs' must be character strings.", call. = FALSE)
  }
  if (!is.character(item2) && !is.factor(item2)) {
    stop("'item2' in 'pairs' must be character strings.", call. = FALSE)
  }
  item1 <- as.character(item1)
  item2 <- as.character(item2)

  if (any(is.na(item1)) || any(item1 == "")) {
    stop("'item1' in 'pairs' cannot contain NA or empty strings.", call. = FALSE)
  }
  if (any(is.na(item2)) || any(item2 == "")) {
    stop("'item2' in 'pairs' cannot contain NA or empty strings.", call. = FALSE)
  }

  # Check self-pairs
  if (any(item1 == item2)) {
    stop("Self-pairs (item1 == item2) are not permitted in 'pairs'.", call. = FALSE)
  }

  # Check relations
  if (!is.character(relation) && !is.factor(relation)) {
    stop("'relation' in 'pairs' must be character strings.", call. = FALSE)
  }
  relation <- as.character(relation)
  valid_relations <- c("same", "opposite")
  if (any(is.na(relation)) || !all(relation %in% valid_relations)) {
    stop("'relation' in 'pairs' must be either 'same' or 'opposite' (case-sensitive).", call. = FALSE)
  }

  # Check duplicate pairs ignoring item order (separator-independent)
  norm_pairs <- data.frame(
    u1 = pmin(item1, item2),
    u2 = pmax(item1, item2),
    stringsAsFactors = FALSE
  )
  dup_idx <- anyDuplicated(norm_pairs)
  if (dup_idx > 0L) {
    stop(sprintf("Duplicate item pair detected in 'pairs': ('%s', '%s').",
                 item1[dup_idx], item2[dup_idx]), call. = FALSE)
  }

  # 6. Validate data
  if (!is.matrix(data) && !is.data.frame(data)) {
    stop("'data' must be a matrix or data.frame.", call. = FALSE)
  }
  data_colnames <- colnames(data)
  if (is.null(data_colnames) || any(is.na(data_colnames)) || any(data_colnames == "")) {
    stop("'data' must have valid, non-missing column names.", call. = FALSE)
  }

  # Check that all items in pairs exist in data
  unique_items <- unique(c(item1, item2))
  missing_items <- setdiff(unique_items, data_colnames)
  if (length(missing_items) > 0L) {
    stop(sprintf("The following items specified in 'pairs' were not found in 'data': %s.",
                 paste(sprintf("'%s'", missing_items), collapse = ", ")), call. = FALSE)
  }

  # Check for duplicate column names among target items in data
  target_matches <- which(data_colnames %in% unique_items)
  if (anyDuplicated(data_colnames[target_matches]) > 0L) {
    dup_names <- unique(data_colnames[target_matches][duplicated(data_colnames[target_matches])])
    stop(sprintf("Duplicate column names found in 'data' for target items: %s.",
                 paste(sprintf("'%s'", dup_names), collapse = ", ")), call. = FALSE)
  }

  n_resp <- nrow(data)

  # Check target column types and values in data
  for (col_name in unique_items) {
    col_data <- if (is.data.frame(data)) data[[col_name]] else data[, col_name]

    # Type check: must be bare numeric (integer or double), not factor/Date/POSIXt/logical/complex/list
    if (is.factor(col_data) || is.logical(col_data) || is.character(col_data) ||
        !is.numeric(col_data) || !typeof(col_data) %in% c("integer", "double") ||
        (!is.null(class(col_data)) && !all(class(col_data) %in% c("numeric", "integer")))) {
      stop(sprintf("Target column '%s' must be a bare numeric (integer or double) column.", col_name),
           call. = FALSE)
    }

    # Check for NaN or Inf
    if (any(is.nan(col_data))) {
      stop(sprintf("Target column '%s' contains NaN values, which are not allowed.", col_name),
           call. = FALSE)
    }
    if (any(is.infinite(col_data))) {
      stop(sprintf("Target column '%s' contains infinite values (Inf or -Inf), which are not allowed.", col_name),
           call. = FALSE)
    }

    # Check scale bounds on non-missing values
    valid_vals <- col_data[!is.na(col_data)]
    if (length(valid_vals) > 0L) {
      if (any(valid_vals < scale_min) || any(valid_vals > scale_max)) {
        stop(sprintf("Target column '%s' contains values outside ['scale_min', 'scale_max'] ([%g, %g]).",
                     col_name, scale_min, scale_max), call. = FALSE)
      }
    }
  }

  # 7. Compute pair inconsistency scores
  # scores_mat: n_resp x n_pairs matrix
  if (n_resp == 0L) {
    scores_mat <- matrix(numeric(0), nrow = 0L, ncol = n_pairs)
  } else {
    scores_mat <- matrix(NA_real_, nrow = n_resp, ncol = n_pairs)
    for (k in seq_len(n_pairs)) {
      x_i <- if (is.data.frame(data)) data[[item1[k]]] else data[, item1[k]]
      x_j <- if (is.data.frame(data)) data[[item2[k]]] else data[, item2[k]]
      rel <- relation[k]

      if (rel == "same") {
        # abs(x_i - x_j) / (U - L)
        scores_mat[, k] <- abs(x_i - x_j) / scale_range
      } else {
        # Numerically stable centered form: abs((x_i - L) - (U - x_j)) / (U - L)
        scores_mat[, k] <- abs((x_i - scale_min) - (scale_max - x_j)) / scale_range
      }
    }
  }

  # 8. Compute respondent-level summary
  if (n_resp == 0L) {
    resp_df <- data.frame(
      mean_inconsistency = numeric(0),
      max_inconsistency = numeric(0),
      sum_inconsistency = numeric(0),
      n_valid_pairs = integer(0),
      n_missing_pairs = integer(0),
      n_high_inconsistency = integer(0),
      prop_high_inconsistency = numeric(0),
      stringsAsFactors = FALSE
    )
  } else {
    valid_mat <- !is.na(scores_mat)
    n_valid <- rowSums(valid_mat)
    n_missing <- n_pairs - n_valid

    sum_inc <- rowSums(scores_mat, na.rm = TRUE)
    mean_inc <- ifelse(n_valid > 0L, sum_inc / n_valid, NA_real_)

    max_inc <- apply(scores_mat, 1L, function(row_vals) {
      obs <- row_vals[!is.na(row_vals)]
      if (length(obs) == 0L) NA_real_ else max(obs)
    })

    high_mat <- valid_mat & (scores_mat >= threshold)
    n_high <- rowSums(high_mat)
    prop_high <- ifelse(n_valid > 0L, n_high / n_valid, NA_real_)

    # Mask summary scores if n_valid < min_valid_pairs
    invalid_mask <- n_valid < min_valid_pairs
    if (any(invalid_mask)) {
      mean_inc[invalid_mask] <- NA_real_
      max_inc[invalid_mask] <- NA_real_
      sum_inc[invalid_mask] <- NA_real_
      n_high[invalid_mask] <- NA_integer_
      prop_high[invalid_mask] <- NA_real_
    }

    resp_df <- data.frame(
      mean_inconsistency = as.numeric(mean_inc),
      max_inconsistency = as.numeric(max_inc),
      sum_inconsistency = as.numeric(sum_inc),
      n_valid_pairs = as.integer(n_valid),
      n_missing_pairs = as.integer(n_missing),
      n_high_inconsistency = as.integer(n_high),
      prop_high_inconsistency = as.numeric(prop_high),
      row.names = NULL,
      stringsAsFactors = FALSE
    )
  }

  if (!details) {
    return(resp_df)
  }

  # 9. Detailed pair-level output
  if (n_resp == 0L) {
    pairs_detail_df <- data.frame(
      respondent_row = integer(0),
      pair_id = integer(0),
      item1 = character(0),
      item2 = character(0),
      relation = character(0),
      inconsistency = numeric(0),
      stringsAsFactors = FALSE
    )
  } else {
    # Row-major order: respondent 1 all pairs, respondent 2 all pairs, ...
    pairs_detail_df <- data.frame(
      respondent_row = rep(seq_len(n_resp), each = n_pairs),
      pair_id = rep(seq_len(n_pairs), times = n_resp),
      item1 = rep(item1, times = n_resp),
      item2 = rep(item2, times = n_resp),
      relation = rep(relation, times = n_resp),
      inconsistency = as.vector(t(scores_mat)),
      row.names = NULL,
      stringsAsFactors = FALSE
    )
  }

  list(
    respondents = resp_df,
    pairs = pairs_detail_df
  )
}
