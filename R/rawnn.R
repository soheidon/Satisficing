#' Print Column Names with Indices
#'
#' Prints the column names of a data frame along with their respective 1-based indices,
#' formatted as \code{'index: column_name'}.
#'
#' @param dataframe A data frame whose column names are to be printed.
#' @return \code{invisible(NULL)}. Called for its side effect of printing.
#' @export
#' @examples
#' rawnn(mtcars)
rawnn <- function(dataframe) {
  if (!is.data.frame(dataframe)) {
    stop("'dataframe' must be a data frame.")
  }
  print(paste(seq_along(dataframe), colnames(dataframe), sep = ": "))
  invisible(NULL)
}
