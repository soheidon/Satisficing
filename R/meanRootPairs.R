#' Mean Root Pairs
#'
#' Computes the sample-normalized Mean Root of Pairs (MRP) straightlining measure
#' for each respondent across a battery of questions (Kim et al., 2019).
#'
#' @param x A data frame or tibble containing survey responses.
#' @param varnames A vector of variable names or column indices. If \code{NULL} (default),
#'   all columns of \code{x} are used.
#' @param verbose Logical; if \code{TRUE} (default), outputs informational messages.
#' @param clean_data Logical; should non-numeric columns be converted to numeric?
#'   Defaults to \code{TRUE}.
#' @param round_digits A numeric value specifying digits for rounding (kept for API compatibility).
#'
#' @return A numeric vector of length \code{nrow(x)} containing the normalized MRP scores,
#'   where higher values represent relatively greater straightlining (lower differentiation).
#'
#' @details
#' \code{meanRootPairs()} strictly implements the mathematical definition from Kim et al. (2019):
#' \deqn{T_i = \frac{2}{n_i(n_i - 1)} \sum_{j < k, j,k \in A_i} \sqrt{|x_{ij} - x_{ik}|}}
#' for respondents with at least 2 valid responses, followed by sample-level normalization:
#' \deqn{\text{MRP}_i = \frac{\max(T) - T_i}{\max(T) - \min(T)}}
#' If fewer than 2 respondents have valid \eqn{T_i} values, or if \eqn{\max(T) == \min(T)},
#' \code{NA_real_} is returned for all rows.
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
#'   item1 = c(1, 1, 3, 1),
#'   item2 = c(1, 2, 4, 1),
#'   item3 = c(1, 3, 5, 2)
#' )
#' meanRootPairs(survey, varnames = c("item1", "item2", "item3"), verbose = FALSE)
meanRootPairs <- function(x, varnames = NULL, verbose = TRUE,
                          clean_data = TRUE, round_digits = 2) {
  if (is.null(varnames)) {
    varnames <- names(x)
  }
  df <- x[varnames]

  if (clean_data) {
    df <- convert_data(df)
  }

  if (!all(vapply(df, is.numeric, logical(1)))) {
    stop("All columns for meanRootPairs must be numeric.")
  }

  n_rows <- nrow(df)
  if (n_rows == 0L) {
    return(numeric(0))
  }

  t_vec <- rep(NA_real_, n_rows)
  mat <- as.matrix(df)

  for (i in seq_len(n_rows)) {
    vals <- mat[i, ]
    valid_vals <- vals[!is.na(vals)]
    n_valid <- length(valid_vals)
    if (n_valid >= 2L) {
      comb <- utils::combn(valid_vals, 2)
      t_vec[i] <- mean(sqrt(abs(comb[1, ] - comb[2, ])))
    }
  }

  valid_t <- t_vec[!is.na(t_vec)]
  if (length(valid_t) < 2L) {
    return(rep(NA_real_, n_rows))
  }

  t_min <- min(valid_t)
  t_max <- max(valid_t)
  if (t_max == t_min) {
    return(rep(NA_real_, n_rows))
  }

  mrp_vec <- (t_max - t_vec) / (t_max - t_min)
  unname(mrp_vec)
}
