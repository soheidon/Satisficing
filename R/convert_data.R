# Internal helper to convert columns if clean_data = TRUE, matching straightliner
convert_data <- function(x) {
  if (ncol(x) < 2L) {
    stop("You need to specify at least two variables.")
  }

  is_num <- vapply(x, function(col) is.numeric(col) && !is.factor(col), logical(1))

  if (all(is_num)) {
    return(x)
  }

  # convert character to factor
  for (j in seq_along(x)) {
    if (is.character(x[[j]])) {
      x[[j]] <- as.factor(x[[j]])
    }
  }

  non_numbers <- which(!is_num)
  level_vector <- vapply(x[non_numbers], nlevels, integer(1))

  warning(
    "Converting some variables to numeric.\n",
    "      This only works if questions with the same number of responses\n",
    "      in the survey have the same number of levels in the dataset.\n",
    "      Here are the numbers of levels present in the data: \n \n",
    paste(names(level_vector), level_vector, sep = ": ", collapse = "\n")
  )

  for (j in non_numbers) {
    x[[j]] <- as.numeric(x[[j]])
  }

  x
}
