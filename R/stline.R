#' Check for Straight-Line Responses Across Specified Columns
#'
#' Evaluates each row across specified columns in a data frame to identify
#' straight-line responses (identical answers across items).
#'
#' @param data A data frame. Must not contain duplicate column names.
#' @param columns A non-empty character vector of unique column names existing in \code{data}.
#' @param result_column_name A non-empty character string specifying the name of the result column.
#'   Defaults to \code{"straight_line"}. Must not conflict with existing columns in \code{data}.
#' @param exclude_values An optional atomic vector of values to exclude from straight-line detection.
#'   If identical values match any value in \code{exclude_values}, the result is 0. Defaults to \code{NULL}.
#'
#' @return The input data frame with an additional integer column indicating whether the row
#'   is a straight-line response:
#'   \itemize{
#'     \item \code{1L}: At least two non-missing values are identical and not excluded.
#'     \item \code{0L}: Non-missing values vary across columns, or identical values match \code{exclude_values}.
#'     \item \code{NA_integer_}: The row has 0 or 1 non-missing value.
#'   }
#' @export
#' @examples
#' df <- data.frame(
#'   q1 = c(1, 1, 1, 2, NA),
#'   q2 = c(1, 1, 2, 2, NA),
#'   q3 = c(1, 2, 3, 2, 1)
#' )
#' stline(df, c("q1", "q2", "q3"))
stline <- function(data, columns, result_column_name = "straight_line", exclude_values = NULL) {
  if (!is.data.frame(data)) {
    stop("'data' must be a data frame.")
  }

  if (anyDuplicated(names(data))) {
    stop("'data' contains duplicate column names, which causes ambiguous column selection.")
  }

  if (!is.character(columns) || length(columns) == 0L || any(is.na(columns)) || any(!nzchar(columns))) {
    stop("'columns' must be a non-empty character vector.")
  }

  if (anyDuplicated(columns)) {
    stop("'columns' must contain unique column names.")
  }

  if (!all(columns %in% names(data))) {
    stop("One or more specified columns do not exist in 'data'.")
  }

  if (!is.character(result_column_name) || length(result_column_name) != 1L ||
      is.na(result_column_name) || !nzchar(result_column_name)) {
    stop("'result_column_name' must be a non-empty character string of length 1.")
  }

  if (result_column_name %in% names(data)) {
    stop(sprintf("Column '%s' already exists in 'data'.", result_column_name))
  }

  sub_cols <- data[columns]

  classify_column <- function(col) {
    if (is.list(col) || is.complex(col) || is.raw(col)) {
      stop("Unsupported column type: list, complex, and raw columns are not supported.")
    }
    if (is.factor(col)) {
      return("factor")
    }
    if (is.logical(col)) {
      if (!identical(class(col), "logical")) {
        stop("Unsupported column class.")
      }
      return("logical")
    }
    if (is.numeric(col)) {
      if (!all(class(col) %in% c("integer", "numeric"))) {
        stop("Unsupported column class for numeric column.")
      }
      return("numeric")
    }
    if (is.character(col)) {
      if (!identical(class(col), "character")) {
        stop("Unsupported column class for character column.")
      }
      return("character")
    }
    stop("Columns must be of type logical, numeric (integer/double), character, or factor.")
  }

  col_types <- vapply(sub_cols, classify_column, character(1L))
  if (length(unique(col_types)) > 1L) {
    stop("All specified columns must belong to the same type group (logical, numeric, character, or factor).")
  }

  type_group <- col_types[1L]

  if (type_group == "factor") {
    first_levels <- levels(sub_cols[[1L]])
    first_ordered <- is.ordered(sub_cols[[1L]])
    for (col in sub_cols[-1L]) {
      if (!identical(levels(col), first_levels) || !identical(is.ordered(col), first_ordered)) {
        stop("All factor columns must have identical levels and ordered attributes.")
      }
    }
  }

  if (!is.null(exclude_values)) {
    if (!is.atomic(exclude_values)) {
      stop("'exclude_values' must be an atomic vector or NULL.")
    }
    valid_compat <- switch(
      type_group,
      numeric = is.numeric(exclude_values),
      character = is.character(exclude_values),
      logical = is.logical(exclude_values),
      factor = is.factor(exclude_values) || is.character(exclude_values),
      FALSE
    )
    if (!valid_compat) {
      stop("'exclude_values' must be compatible with the type of the specified columns.")
    }
  }

  n_rows <- nrow(data)
  if (n_rows == 0L) {
    data[[result_column_name]] <- integer(0L)
    return(data)
  }

  if (type_group == "factor") {
    lvl <- levels(sub_cols[[1L]])
    int_mat <- do.call(cbind, lapply(sub_cols, as.integer))
    res <- vapply(seq_len(n_rows), function(i) {
      row_int <- int_mat[i, ]
      non_na <- row_int[!is.na(row_int)]
      if (length(non_na) < 2L) {
        NA_integer_
      } else if (all(non_na == non_na[1L])) {
        val <- lvl[non_na[1L]]
        if (!is.null(exclude_values) && (val %in% as.character(exclude_values))) {
          0L
        } else {
          1L
        }
      } else {
        0L
      }
    }, integer(1L))
  } else if (type_group == "numeric") {
    num_mat <- do.call(cbind, lapply(sub_cols, as.double))
    res <- vapply(seq_len(n_rows), function(i) {
      row_num <- num_mat[i, ]
      non_na <- row_num[!is.na(row_num)]
      if (length(non_na) < 2L) {
        NA_integer_
      } else if (all(non_na == non_na[1L])) {
        if (!is.null(exclude_values) && (non_na[1L] %in% exclude_values)) {
          0L
        } else {
          1L
        }
      } else {
        0L
      }
    }, integer(1L))
  } else if (type_group == "character") {
    chr_mat <- do.call(cbind, sub_cols)
    res <- vapply(seq_len(n_rows), function(i) {
      row_chr <- chr_mat[i, ]
      non_na <- row_chr[!is.na(row_chr)]
      if (length(non_na) < 2L) {
        NA_integer_
      } else if (all(non_na == non_na[1L])) {
        if (!is.null(exclude_values) && (non_na[1L] %in% exclude_values)) {
          0L
        } else {
          1L
        }
      } else {
        0L
      }
    }, integer(1L))
  } else if (type_group == "logical") {
    log_mat <- do.call(cbind, lapply(sub_cols, as.logical))
    res <- vapply(seq_len(n_rows), function(i) {
      row_log <- log_mat[i, ]
      non_na <- row_log[!is.na(row_log)]
      if (length(non_na) < 2L) {
        NA_integer_
      } else if (all(non_na == non_na[1L])) {
        if (!is.null(exclude_values) && (non_na[1L] %in% exclude_values)) {
          0L
        } else {
          1L
        }
      } else {
        0L
      }
    }, integer(1L))
  }

  data[[result_column_name]] <- res
  return(data)
}
