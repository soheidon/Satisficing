#' Simple Nondifferentiation Indicator
#'
#' Evaluates whether a respondent exhibits complete nondifferentiation across
#' a battery of questions (Kim et al., 2019).
#'
#' @param x A data frame or tibble containing survey responses.
#' @param varnames A vector of variable names or column indices. If \code{NULL} (default),
#'   all columns of \code{x} are used.
#' @param verbose Logical; if \code{TRUE} (default), prints the proportion of nondifferentiation.
#' @param clean_data Logical; should non-numeric columns be converted to numeric?
#'   Defaults to \code{TRUE}.
#' @param round_digits A numeric value specifying digits for rounding printed output.
#'
#' @return A logical vector indicating whether each respondent gave identical answers
#'   to all specified questions (\code{TRUE}) or not (\code{FALSE}).
#'
#' @details
#' In accordance with straightliner conventions, \code{nondiff()} evaluates whether
#' \code{length(unique(row)) == 1L}. If a row consists entirely of missing values (\code{NA}),
#' \code{unique()} has length 1, evaluating to \code{TRUE}. If a row has both observed values
#' and \code{NA}, \code{unique()} has length greater than 1, evaluating to \code{FALSE}.
#'
#' Note that this differs from \code{\link{stline}}, which returns an integer flag (\code{1L},
#' \code{0L}, or \code{NA_integer_}) and evaluates whether all non-missing values are identical
#' when at least 2 non-missing responses are present.
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
#' nondiff(survey, varnames = c("item1", "item4"), verbose = FALSE)
nondiff <- function(x, varnames = NULL, verbose = TRUE,
                    clean_data = TRUE, round_digits = 2) {
  if (is.null(varnames)) {
    varnames <- names(x)
  }
  df <- x[varnames]

  if (clean_data) {
    df <- convert_data(df)
  }

  nd <- apply(df, 1, function(row) length(unique(row)) == 1L)

  if (verbose) {
    perc <- sum(nd) / nrow(df)
    cat(paste0("The proportion of nondifferentiation is ", round(perc, round_digits)), "\n")
  }

  unname(nd)
}
