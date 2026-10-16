#' Individual-Level Straightlining Indicators
#'
#' Calculates individual-level indicators of straightlining across a specified set of
#' columns in a survey data frame (Kim et al., 2019).
#'
#' @param x A data frame or tibble containing survey responses.
#' @param varnames A vector of variable names or column indices to be analyzed. If \code{NULL}
#'   (default), all columns of \code{x} are used.
#' @param measures A character vector of the measures to compute. Valid options are:
#'   \itemize{
#'     \item \code{"mrp"}: Mean Root of Pairs (\code{\link{meanRootPairs}}).
#'     \item \code{"mir"}: Maximum Identical Rating (\code{\link{maxIdenticalRating}}).
#'     \item \code{"qsd"}: Battery Standard Deviation (\code{\link{question_sd}}).
#'     \item \code{"spv"}: Scale Point Variation (\code{\link{scale_point_variation}}).
#'     \item \code{"nondiff"}: Simple Nondifferentiation (\code{\link{nondiff}}).
#'   }
#'   Defaults to \code{c("mrp", "mir", "qsd", "spv", "nondiff")}.
#' @param keep_original Logical; if \code{TRUE}, returns the original data frame with the
#'   computed straightlining indicator columns appended on the right. If \code{FALSE}
#'   (default), returns only the requested straightlining measures as a data frame.
#'
#' @return A data frame containing one column per requested measure. If \code{keep_original = TRUE},
#'   all original columns in \code{x} are also included.
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
#' straightlining(survey, varnames = paste0("item", 1:4),
#'                measures = c("mir", "qsd", "spv", "nondiff"))
straightlining <- function(x, varnames = NULL,
                           measures = c("mrp", "mir", "qsd", "spv", "nondiff"),
                           keep_original = FALSE) {
  if (is.null(varnames)) {
    varnames <- names(x)
  }
  df <- x[varnames]
  df <- convert_data(df)

  res_list <- list()

  if ("mrp" %in% measures) {
    res_list$mrp <- meanRootPairs(df, verbose = FALSE, clean_data = FALSE)
  }
  if ("mir" %in% measures) {
    res_list$mir <- maxIdenticalRating(df, verbose = FALSE, clean_data = FALSE)
  }
  if ("qsd" %in% measures) {
    res_list$qsd <- question_sd(df, verbose = FALSE, clean_data = FALSE)
  }
  if ("spv" %in% measures) {
    res_list$spv <- scale_point_variation(df, verbose = FALSE, clean_data = FALSE)
  }
  if ("nondiff" %in% measures) {
    res_list$nondiff <- nondiff(df, verbose = FALSE, clean_data = FALSE)
  }

  fixed_order <- c("mrp", "mir", "qsd", "spv", "nondiff")
  ordered_names <- fixed_order[fixed_order %in% names(res_list)]
  if (length(ordered_names) == 0L) {
    res_df <- as.data.frame(matrix(nrow = nrow(x), ncol = 0L))
  } else {
    res_df <- as.data.frame(res_list[ordered_names])
  }

  if (keep_original) {
    cbind(x, res_df)
  } else {
    res_df
  }
}
