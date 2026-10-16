# Ported from the R package 'careless' version 1.2.2
# Original Authors: Francisco Wilhelm
# Upstream URL: https://github.com/ryentes/careless
# CRAN URL: https://cloud.r-project.org/package=careless
# License: MIT (see inst/licenses/careless-MIT.txt and inst/COPYRIGHTS)

#' Compute the correlations between all possible item pairs and order them by the magnitude of the correlation
#'
#' A function intended to help finding adequate critical values for \code{psychsyn} and \code{psychant}.
#' Takes a matrix of item responses and returns a data frame giving the correlations of all item pairs ordered by the magnitude of the correlation.
#' Ported from the \pkg{careless} package (version 1.2.2).
#'
#' @param x a matrix or data frame of item responses.
#' @param anto ordered by the largest positive correlation, or, if \code{anto = TRUE}, the largest negative correlation.
#' @return A data frame with columns \code{var1}, \code{var2}, and \code{cor}, sorted by correlation magnitude.
#' @author Francisco Wilhelm \email{franciscowilhelm@gmail.com}
#' @export
#' @seealso after determining an adequate critical value, continue with \code{\link{psychsyn}} and/or \code{\link{psychant}}
#' @examples
#' psychsyn_cor <- psychsyn_critval(careless_dataset)
#' psychsyn_cor <- psychsyn_critval(careless_dataset, anto = TRUE)
psychsyn_critval <- function(x, anto = FALSE) {
  correlations <- stats::cor(x, use = "pairwise.complete.obs")
  correlations[upper.tri(correlations, diag=TRUE)] <- NA
  correlations <- as.data.frame(as.table(correlations))

  if(anto == FALSE) {
    correlations <- correlations[order(correlations$Freq, decreasing = TRUE),]
  }
  else {
  correlations <- correlations[order(correlations$Freq, decreasing = FALSE),]
  }
  names(correlations) <- c("var1","var2","cor")

  return(correlations)
}
