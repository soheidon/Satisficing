# Ported from the R package 'careless' version 1.2.2
# Original Authors: Richard Yentes, Francisco Wilhelm
# Upstream URL: https://github.com/ryentes/careless
# CRAN URL: https://cloud.r-project.org/package=careless
# License: MIT (see inst/licenses/careless-MIT.txt and inst/COPYRIGHTS)

#' Simulated dataset with insufficient effort responses.
#'
#' A simulated dataset mimicking insufficient effort responding. Contains three types of responses:
#' (a) Normal responses with answers centering around a trait/attitude value
#' (80 percent probability per simulated observation),
#' (b) Straightlining responses (10 percent probability per simulated observation),
#' (c) Random responses (10 percent probability per simulated observation).
#' Simulated are 10 subscales of 5 items each (= 50 variables).
#' Ported from the \pkg{careless} package (version 1.2.2).
#'
#' @format A data frame with 200 observations (rows) and 50 variables (columns).
#' @author Richard Yentes \email{ryentes@gmail.com}, Francisco Wilhelm \email{franciscowilhelm@gmail.com}
"careless_dataset"
