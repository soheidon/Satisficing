#' Maximum Identical Rating (MIR)
#'
#' Computes the Maximum Identical Rating (MIR) straightlining measure across specified
#' columns for each row in a data frame, as described by Kim et al. (2019).
#'
#' @details
#' \code{mir()} is a backward-compatibility wrapper around \code{\link{maxIdenticalRating}}.
#' It appends a result column to the input data frame, computing the proportion of answers
#' taking the most common response value across the specified columns.
#'
#' @param data A data frame.
#' @param columns A character vector containing at least 2 unique column names existing in \code{data}.
#'   All specified columns must be numeric (integer/double) or all must be factors.
#' @param result_column_name A non-empty character string of length 1 specifying the name
#'   of the result column to append. Defaults to \code{"mir"}. Must not already exist in \code{data}.
#'
#' @return The original data frame \code{data} with an additional numeric column
#'   named by \code{result_column_name} containing the MIR scores.
#'
#' @references
#' Kim, Y., Dykema, J., Stevenson, J., Black, P., & Moberg, D. P. (2019).
#' Straightlining: Overview of Measurement, Comparison of Indicators, and Effects in Mail–Web Mixed-Mode Surveys.
#' \emph{Social Science Computer Review}, 37(2), 214–233.
#' \doi{10.1177/0894439317752406}
#'
#' @export
#' @examples
#' df <- data.frame(
#'   q1 = c(1, 1, 3),
#'   q2 = c(1, 2, 3),
#'   q3 = c(1, 3, 3)
#' )
#' mir(df, c("q1", "q2", "q3"))
mir <- function(data, columns, result_column_name = "mir") {
  if (!is.data.frame(data)) {
    stop("'data' must be a data frame.")
  }
  if (anyDuplicated(names(data)) > 0L) {
    stop("Column names in 'data' must be unique.")
  }
  if (!is.character(columns)) {
    stop("'columns' must be a character vector.")
  }
  if (length(columns) < 2L) {
    stop("'columns' must contain at least 2 column names.")
  }
  if (any(is.na(columns)) || any(!nzchar(columns))) {
    stop("'columns' must not contain missing or empty column names.")
  }
  if (anyDuplicated(columns) > 0L) {
    stop("'columns' must not contain duplicate column names.")
  }
  if (!all(columns %in% names(data))) {
    stop("One or more specified columns do not exist in 'data'.")
  }
  if (!is.character(result_column_name) || length(result_column_name) != 1L ||
      is.na(result_column_name) || !nzchar(result_column_name)) {
    stop("'result_column_name' must be a non-empty character string of length 1.")
  }
  if (result_column_name %in% names(data)) {
    stop(sprintf("Column '%s' already exists in 'data'.", result_column_name))
  }

  is_num <- vapply(columns, function(col) is.numeric(data[[col]]) && !is.factor(data[[col]]), logical(1L))
  is_fac <- vapply(columns, function(col) is.factor(data[[col]]), logical(1L))

  if (!all(is_num) && !all(is_fac)) {
    stop("All specified 'columns' must be numeric (integer/double), or all must be factors.")
  }

  if (all(is_num)) {
    for (col in columns) {
      v <- data[[col]]
      if (any(is.infinite(v) | is.nan(v))) {
        stop(sprintf("Column '%s' contains non-finite values (Inf, -Inf, or NaN).", col))
      }
    }
  }

  n_rows <- nrow(data)
  if (n_rows == 0L) {
    data[[result_column_name]] <- numeric(0L)
    return(data)
  }

  sub_df <- data[, columns, drop = FALSE]
  res <- maxIdenticalRating(sub_df, verbose = FALSE, clean_data = FALSE)
  data[[result_column_name]] <- res
  data
}
