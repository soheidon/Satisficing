# Ported from the R package 'careless' version 1.2.2
# Original Authors: Richard Yentes, Francisco Wilhelm
# Upstream URL: https://github.com/ryentes/careless
# CRAN URL: https://cloud.r-project.org/package=careless
# License: MIT (see inst/licenses/careless-MIT.txt and inst/COPYRIGHTS)

#' Identifies the longest string of identical consecutive responses for each observation
#'
#' Takes a matrix of item responses and, beginning with the second column (i.e., second item)
#' compares each column with the previous one to check for matching responses.
#' For each observation, the length of the maximum uninterrupted string of
#' identical responses is returned. Additionally, can return the average length of uninterrupted string of identical responses.
#' Ported from the \pkg{careless} package (version 1.2.2).
#'
#' @param x a matrix or data frame of data (e.g. item responses)
#' @param avg logical indicating whether to additionally return the average length of identical consecutive responses
#' @return If \code{avg = FALSE}, a vector of lengths of the longest uninterrupted string of identical responses.
#'   If \code{avg = TRUE}, a data frame containing \code{longstr} and \code{avgstr}.
#' @author Richard Yentes \email{ryentes@gmail.com}, Francisco Wilhelm \email{franciscowilhelm@gmail.com}
#' @references
#' Johnson, J. A. (2005). Ascertaining the validity of individual protocols
#' from web-based personality inventories. \emph{Journal of Research in Personality, 39}, 103-129. \doi{10.1016/j.jrp.2004.09.009}
#' @export
#' @examples
#' careless_long <- longstring(careless_dataset, avg = FALSE)
#' careless_avg <- longstring(careless_dataset, avg = TRUE)
#' boxplot(careless_avg$longstr) #produce a boxplot of the longstring index
#' boxplot(careless_avg$avgstr)
longstring <- function(x, avg = FALSE) {

  # subfunction that calculates the length of consecutive identical responses
  rle_string <- function(x) {
    rle_list <- rle(x)
    longstr <- max(rle_list$lengths)
    avgstr <- mean(rle_list$lengths)
    return(cbind(longstr, avgstr))
  }

  # apply the subfunctions to each row (case, subject)
  output <- apply(x, 1, rle_string)
  output <- data.frame(t(output))
  colnames(output) <- (c('longstr','avgstr'))

  if(avg == TRUE) {
    return(output)
  } else {
    return(output[,'longstr'])
  }
}
