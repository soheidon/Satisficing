#' Identify Rows Matching a Logical Condition
#'
#' Evaluates a logical condition within the context of a data frame and adds an integer
#' column indicating which rows satisfy the condition.
#'
#' @param data A data frame.
#' @param condition An expression to evaluate within \code{data}. Must evaluate to a logical
#'   vector whose length is exactly \code{nrow(data)}.
#' @param result_col A non-empty character string specifying the name of the result column.
#'   Defaults to \code{"match"}. Must not conflict with existing columns in \code{data}.
#'
#' @return The input data frame with an additional integer column indicating whether each row
#'   satisfies the condition:
#'   \itemize{
#'     \item \code{1L}: The condition evaluated to \code{TRUE}.
#'     \item \code{0L}: The condition evaluated to \code{FALSE}.
#'     \item \code{NA_integer_}: The condition evaluated to \code{NA}.
#'   }
#' @export
#' @examples
#' df <- data.frame(ID = c(1, 2, 3, 4), Value = c(10, 20, 30, 40))
#' matching(df, Value > 20)
matching <- function(data, condition, result_col = "match") {
  if (!is.data.frame(data)) {
    stop("'data' must be a data frame.")
  }

  if (!is.character(result_col) || length(result_col) != 1L || is.na(result_col) || !nzchar(result_col)) {
    stop("'result_col' must be a non-empty character string of length 1.")
  }

  if (result_col %in% names(data)) {
    stop(sprintf("Column '%s' already exists in 'data'.", result_col))
  }

  cond_expr <- substitute(condition)
  cond_val <- eval(cond_expr, data, parent.frame())

  if (!is.logical(cond_val)) {
    stop("'condition' must evaluate to a logical vector.")
  }

  if (length(cond_val) != nrow(data)) {
    stop(sprintf(
      "Length of condition result (%d) must match number of rows in 'data' (%d).",
      length(cond_val), nrow(data)
    ))
  }

  data[[result_col]] <- as.integer(cond_val)
  return(data)
}
