#' Aggregate Straightlining Measures for Question Batteries
#'
#' Computes aggregate (battery-level) straightlining measures across multiple sets
#' of questions (Kim et al., 2019).
#'
#' @param x A data frame or tibble containing survey responses.
#' @param variable_list A named list where each element is a vector containing the
#'   column names or column indices for one battery of questions.
#' @param measures A character vector of the measures to compute. Valid options are:
#'   \code{"mrp"}, \code{"mir"}, \code{"qsd"}, \code{"spv"}, and \code{"nondiff"}.
#'   Defaults to \code{c("mrp", "mir", "qsd", "spv", "nondiff")}.
#' @param round_digits A numeric value specifying digits for rounding the printed summary table.
#'   Defaults to \code{2}.
#' @param verbose Logical; if \code{TRUE}, outputs progress messages per battery. Defaults to \code{FALSE}.
#'
#' @return A data frame of class \code{c("straightliner", "data.frame")} containing the battery-level
#'   means for each requested measure (and the maximum SPV \code{"spv_max"} if \code{"spv"} is requested),
#'   returned invisibly.
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
#'   item1 = c(5, 5, 3),
#'   item2 = c(5, 5, 2),
#'   item3 = c(5, 5, 1),
#'   item4 = c(5, 1, 4)
#' )
#' batteries <- list(first_two = c("item1", "item2"), second_two = c(3, 4))
#' straightlining_qset(survey, variable_list = batteries,
#'                    measures = c("mir", "qsd", "spv", "nondiff"))
straightlining_qset <- function(x,
                                variable_list = NULL,
                                measures = c("mrp", "mir", "qsd", "spv", "nondiff"),
                                round_digits = 2,
                                verbose = FALSE) {
  if (!is.list(variable_list) || is.null(names(variable_list))) {
    stop("variable_list is supposed to be a named list")
  }

  col_names <- measures
  if ("spv" %in% measures) {
    col_names <- c(col_names, "spv_max")
  }

  results_tab <- as.data.frame(matrix(NA_real_, nrow = length(variable_list), ncol = length(col_names)))
  rownames(results_tab) <- names(variable_list)
  names(results_tab) <- col_names

  for (i in seq_along(variable_list)) {
    bat_name <- names(variable_list)[i]
    if (verbose) {
      cat("Battery: \n")
      cat(bat_name, "\n")
    }

    df <- x[variable_list[[i]]]
    df <- convert_data(df)

    if ("mrp" %in% measures) {
      mrp_val <- meanRootPairs(df, verbose = verbose, clean_data = FALSE, round_digits = round_digits)
      results_tab[i, "mrp"] <- mean(mrp_val, na.rm = TRUE)
    }
    if ("mir" %in% measures) {
      mir_val <- maxIdenticalRating(df, verbose = verbose, clean_data = FALSE, round_digits = round_digits)
      results_tab[i, "mir"] <- mean(mir_val, na.rm = TRUE)
    }
    if ("qsd" %in% measures) {
      qsd_val <- question_sd(df, verbose = verbose, clean_data = FALSE, round_digits = round_digits)
      results_tab[i, "qsd"] <- mean(qsd_val, na.rm = TRUE)
    }
    if ("spv" %in% measures) {
      spv_val <- scale_point_variation(df, verbose = verbose, clean_data = FALSE, round_digits = round_digits)
      results_tab[i, "spv"] <- mean(spv_val, na.rm = TRUE)
      results_tab[i, "spv_max"] <- max(spv_val, na.rm = TRUE)
    }
    if ("nondiff" %in% measures) {
      nd_val <- nondiff(df, verbose = verbose, clean_data = FALSE, round_digits = round_digits)
      results_tab[i, "nondiff"] <- mean(nd_val, na.rm = TRUE)
    }
  }

  class(results_tab) <- c("straightliner", class(results_tab))
  print(results_tab, digits = round_digits)
  invisible(results_tab)
}

#' Print Method for straightliner Objects
#'
#' @param x An object of class \code{straightliner}.
#' @param digits Number of decimal places for rounding output.
#' @param ... Additional arguments passed to \code{print}.
#'
#' @export
print.straightliner <- function(x, digits = 2, ...) {
  class(x) <- setdiff(class(x), "straightliner")
  cat("\n")
  print(round(x, digits = digits), ...)
  cat("\n")
  invisible(x)
}
