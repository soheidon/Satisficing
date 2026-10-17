#' Scale Point Variation
#'
#' Computes the Scale Point Variation measure capturing response diversity across
#' questions for each respondent (Kim et al., 2019).
#'
#' @param x A data frame or tibble containing survey responses.
#' @param varnames A vector of variable names or column indices. If \code{NULL} (default),
#'   all columns of \code{x} are used.
#' @param verbose Logical; if \code{TRUE} (default), outputs informational messages,
#'   including the battery-level statistic and handling of missing data.
#' @param clean_data Logical; should non-numeric columns be converted to numeric?
#'   Defaults to \code{TRUE}.
#' @param round_digits A numeric value specifying digits for rounding informational messages.
#'
#' @return A numeric vector of length \code{nrow(x)} with Scale Point Variation scores.
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
#' scale_point_variation(survey, varnames = c("item1", "item4"), verbose = FALSE)
scale_point_variation <- function(x, varnames = NULL, verbose = TRUE,
                                  clean_data = TRUE, round_digits = 2) {
  if (is.null(varnames)) {
    varnames <- names(x)
  }
  df <- x[varnames]

  if (clean_data) {
    df <- convert_data(df)
  }

  no_vars <- ncol(df)
  uniques <- apply(df, 1, unique, simplify = FALSE)
  spv <- rep(NA_real_, nrow(df))

  for (i in seq_len(nrow(df))) {
    u_vals <- uniques[[i]]
    number_items <- length(u_vals)
    props <- numeric(number_items)

    for (l in seq_len(number_items)) {
      if (is.na(u_vals[l])) {
        props[l] <- sum(is.na(df[i, ])) / no_vars
      } else {
        props[l] <- sum(df[i, ] == u_vals[l], na.rm = TRUE) / no_vars
      }
    }
    spv[i] <- 1 - sum(props^2)
  }

  spv_battery <- mean(spv, na.rm = TRUE)
  maxval <- 1 - (1 / no_vars)^2 * no_vars

  if (verbose) {
    if (sum(stats::complete.cases(df)) < nrow(df)) {
      message("scale_point variation: There are missing values in your Data. This function treats NA as a response category of its own\n")
    }
    cat(paste0("The scale point variation measure for this battery of questions is ", round(spv_battery, round_digits), ". \n\n"))
    cat(paste0("The highest possible value of scale point variation for a given respondent is ", round(maxval, round_digits), "\n\n"))
  }

  unname(spv)
}
