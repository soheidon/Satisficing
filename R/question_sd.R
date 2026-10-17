#' Standard Deviation across Question Battery
#'
#' Computes the intra-individual standard deviation across a set of questions
#' for each respondent (Kim et al., 2019).
#'
#' @param x A data frame or tibble containing survey responses.
#' @param varnames A vector of variable names or column indices. If \code{NULL} (default),
#'   all columns of \code{x} are used.
#' @param verbose Logical; if \code{TRUE} (default), outputs informational messages
#'   regarding missing data handling.
#' @param clean_data Logical; should non-numeric columns be converted to numeric?
#'   Defaults to \code{TRUE}.
#' @param round_digits A numeric value specifying digits for rounding (kept for API compatibility).
#'
#' @return A numeric vector of standard deviations for each respondent across the
#'   specified questions.
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
#' question_sd(survey, varnames = c("item1", "item3", "item4"), verbose = FALSE)
question_sd <- function(x, varnames = NULL, verbose = TRUE,
                        clean_data = TRUE, round_digits = 2) {
  if (is.null(varnames)) {
    varnames <- names(x)
  }
  df <- x[varnames]

  if (clean_data) {
    df <- convert_data(df)
  }

  if (verbose && any(!stats::complete.cases(df))) {
    message("question_sd: There are missing values in your Data.This function ignores NAs.\n")
  }

  sd_score <- apply(df, 1, stats::sd, na.rm = TRUE)
  unname(sd_score)
}
