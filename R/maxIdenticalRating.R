#' Maximum Identical Rating
#'
#' Calculates the proportion of answers taken up by the most common response
#' by the respondent to a set of questions (Kim et al., 2019).
#'
#' @param x A data frame or tibble containing survey responses.
#' @param varnames A vector of variable names or column indices. If \code{NULL} (default),
#'   all columns of \code{x} are used.
#' @param verbose Logical; if \code{TRUE} (default), outputs informational messages
#'   such as how missing data are handled.
#' @param clean_data Logical; should non-numeric columns be converted to numeric?
#'   Defaults to \code{TRUE}.
#' @param round_digits A numeric value specifying digits for rounding (kept for API compatibility).
#'
#' @return A numeric vector of the same length as \code{nrow(x)} indicating the proportion
#'   of answers that take the most common value.
#'
#' @references
#' Kim, Y., Dykema, J., Stevenson, J., Black, P., & Moberg, D. P. (2019).
#' Straightlining: Overview of Measurement, Comparison of Indicators, and Effects in Mail–Web Mixed-Mode Surveys.
#' \emph{Social Science Computer Review}, 37(2), 214–233.
#' \doi{10.1177/0894439317752406}
#'
#' @export
#' @examples
#' survey <- data.frame(
#'   item1 = c(5, 5),
#'   item2 = c(5, 5),
#'   item3 = c(5, 5),
#'   item4 = c(5, 1)
#' )
#' maxIdenticalRating(survey, varnames = c("item1", "item4"), verbose = FALSE)
maxIdenticalRating <- function(x, varnames = NULL, verbose = TRUE,
                               clean_data = TRUE, round_digits = 2) {
  if (is.null(varnames)) {
    varnames <- names(x)
  }
  no_vars <- length(varnames)
  df <- x[varnames]

  if (clean_data) {
    df <- convert_data(df)
  }

  if (verbose && any(!stats::complete.cases(df))) {
    message("MaxIdenticalRating: There are missing values in your Data.This function ignores NAs.\n")
  }

  res <- apply(df, 1, function(row) {
    tbl <- table(row)
    if (length(tbl) == 0L) {
      return(NA_real_)
    }
    max_count <- max(tbl)
    mir_val <- max_count / no_vars
    if (mir_val == 0) NA_real_ else mir_val
  })

  unname(res)
}
