#' Flag Respondents Based on Logical Criteria
#'
#' Evaluates one or more user-defined logical conditions within the context of
#' survey quality indicators, returning a data frame of logical flags.
#'
#' @details
#' Each expression in \code{...} is evaluated using data-masking within \code{indicators},
#' falling back to the calling environment. Expressions must evaluate strictly to
#' a logical vector of length equal to \code{nrow(indicators)}. Length-1 recycling
#' and implicit type coercion (such as numeric truthy evaluation) are not permitted.
#' Missing values (\code{NA}) in condition results are preserved.
#'
#' Resulting flag columns are named after the argument names in \code{...} if provided,
#' or derived from the deparsed expressions. Column names are preserved without
#' automatic syntactic conversion (\code{check.names = FALSE}). Duplicate flag names,
#' empty names, or collisions with the retained ID column name result in an error.
#'
#' If \code{id = NULL} and a column named \code{"id"} exists in \code{indicators},
#' it is automatically retained at the beginning of the returned data frame.
#' If \code{id} is explicitly specified, that column is retained at the beginning.
#' Row order of \code{indicators} is always preserved.
#'
#' \strong{Methodological Note}: Quality flags indicate respondent patterns that
#' meet researcher-specified screening rules; they do not definitively establish
#' careless or invalid responding. Screening thresholds should be justified and
#' supported by sensitivity analysis.
#'
#' @param indicators A data frame containing respondent-level survey indicators.
#'   Column names must be unique.
#' @param ... One or more logical expressions to evaluate within \code{indicators}.
#'   At least one expression must be provided.
#' @param id Optional character string specifying the column name in \code{indicators}
#'   that uniquely identifies respondents. If \code{NULL} (default), an existing
#'   column named \code{"id"} is retained automatically if present.
#'
#' @return A data frame containing the retained ID column (if present or specified)
#'   and one or more logical flag columns.
#'
#' @export
#' @examples
#' df <- data.frame(
#'   id = 1:4,
#'   longstring = c(12, 5, 15, 3),
#'   inconsistency = c(0.8, 0.2, 0.9, 0.1)
#' )
#' flag_respondents(
#'   df,
#'   flag_long = longstring >= 10,
#'   flag_inc = inconsistency >= 0.75
#' )
flag_respondents <- function(indicators, ..., id = NULL) {
  # 1. Validate indicators
  if (!is.data.frame(indicators)) {
    stop("'indicators' must be a data.frame.", call. = FALSE)
  }
  ind_names <- names(indicators)
  if (is.null(ind_names) || any(is.na(ind_names)) || any(ind_names == "")) {
    stop("'indicators' must have valid, non-missing column names.", call. = FALSE)
  }
  if (anyDuplicated(ind_names) > 0L) {
    stop("Column names in 'indicators' must be unique.", call. = FALSE)
  }

  n_resp <- nrow(indicators)

  # 2. Capture and validate ... expressions
  dots <- as.list(substitute(list(...)))[-1L]
  if (length(dots) == 0L) {
    stop("At least one condition must be provided in '...'.", call. = FALSE)
  }

  # 3. Determine and validate ID column to retain
  retained_id_col <- NULL
  if (is.null(id)) {
    if ("id" %in% ind_names) {
      retained_id_col <- "id"
    }
  } else {
    if (!is.character(id) || length(id) != 1L || is.na(id) || id == "") {
      stop("'id' must be a single non-empty character string or NULL.", call. = FALSE)
    }
    if (!id %in% ind_names) {
      stop(sprintf("Specified ID column '%s' was not found in 'indicators'.", id), call. = FALSE)
    }
    retained_id_col <- id
  }

  # 4. Resolve flag column names
  dot_names <- names(dots)
  flag_names <- character(length(dots))
  for (i in seq_along(dots)) {
    if (!is.null(dot_names) && !is.na(dot_names[i]) && nzchar(dot_names[i])) {
      flag_names[i] <- dot_names[i]
    } else {
      flag_names[i] <- paste(deparse(dots[[i]]), collapse = " ")
    }
  }

  if (any(is.na(flag_names)) || any(flag_names == "")) {
    stop("Flag column names cannot be empty or NA.", call. = FALSE)
  }
  dup_flag <- anyDuplicated(flag_names)
  if (dup_flag > 0L) {
    stop(sprintf("Duplicate flag name detected: '%s'.", flag_names[dup_flag]), call. = FALSE)
  }
  if (!is.null(retained_id_col) && retained_id_col %in% flag_names) {
    stop(sprintf("Flag name '%s' conflicts with the ID column name.", retained_id_col), call. = FALSE)
  }

  # 5. Evaluate expressions with data-mask + caller-environment
  caller_env <- parent.frame()
  flag_vals <- vector("list", length(dots))
  for (i in seq_along(dots)) {
    val <- eval(dots[[i]], indicators, caller_env)

    if (!is.logical(val)) {
      stop(sprintf("Condition '%s' must evaluate to a logical vector, but returned type '%s'.",
                   flag_names[i], typeof(val)), call. = FALSE)
    }
    if (length(val) != n_resp) {
      stop(sprintf("Condition '%s' evaluated to length %d, but must have length %d (matching nrow(indicators)).",
                   flag_names[i], length(val), n_resp), call. = FALSE)
    }
    flag_vals[[i]] <- val
  }

  # 6. Assemble result data.frame
  result_list <- list()
  if (!is.null(retained_id_col)) {
    result_list[[retained_id_col]] <- indicators[[retained_id_col]]
  }
  for (i in seq_along(dots)) {
    result_list[[flag_names[i]]] <- flag_vals[[i]]
  }

  res_df <- as.data.frame(result_list, stringsAsFactors = FALSE, check.names = FALSE)
  row.names(res_df) <- NULL
  res_df
}
