#' Filter Respondents Based on Satisficing Flags
#'
#' Filters respondent data based on flag indicators using three-valued logic
#' aggregation strategies (\code{"any"}, \code{"all"}, or \code{"at_least"}),
#' requiring explicit respondent ID matching and producing an audit log.
#'
#' @details
#' \code{filter_respondents} requires an explicit respondent identifier to ensure
#' safe, unambiguous alignment between survey response data and quality flags.
#' Row-order joining without ID alignment is strictly prohibited.
#'
#' ID values in both \code{data} and \code{flags} must be non-missing, unique
#' one-dimensional atomic vectors of identical type and class, with exactly
#' matching ID sets. Flags are aligned to the row order of \code{data} by ID.
#'
#' Respondent exclusion is evaluated using three-valued logic (Kleene logic)
#' across all flag columns before applying \code{na_action}:
#' \itemize{
#'   \item \code{"any"}: Exclude if any flag is \code{TRUE}; retain if all flags
#'     are \code{FALSE}; evaluate to \code{NA} if all non-missing flags are
#'     \code{FALSE} and at least one flag is \code{NA}.
#'   \item \code{"all"}: Retain if any flag is \code{FALSE}; exclude if all flags
#'     are \code{TRUE}; evaluate to \code{NA} if all non-missing flags are
#'     \code{TRUE} and at least one flag is \code{NA}.
#'   \item \code{"at_least"}: Exclude if the number of \code{TRUE} flags is
#'     \eqn{\ge n}; retain if the sum of \code{TRUE} and \code{NA} flags is
#'     \eqn{< n}; evaluate to \code{NA} otherwise. Requires integer \code{n}
#'     between 1 and the number of flag columns.
#' }
#'
#' The \code{na_action} parameter determines the resolution for respondents whose
#' aggregated exclusion decision is \code{NA}:
#' \itemize{
#'   \item \code{"error"} (default): Throws an error if any respondent has an
#'     indeterminate (\code{NA}) exclusion decision.
#'   \item \code{"keep"}: Treats indeterminate decisions as \code{FALSE} (retained).
#'   \item \code{"exclude"}: Treats indeterminate decisions as \code{TRUE} (excluded).
#' }
#'
#' The audit table generated in \code{$audit} contains fixed metadata columns:
#' \code{row_index}, \code{n_flagged}, \code{n_missing_flags}, \code{decision},
#' \code{strategy}, \code{n_required}, \code{na_action}, and \code{excluded}.
#' To prevent unintended overwriting of audit information, neither the selected ID
#' column name nor any flag column name in \code{flags} may match any of these
#' reserved column names.
#'
#' \strong{Methodological Note}: Respondent filtering decisions can materially impact
#' study conclusions. Researchers should report filtering criteria transparently and
#' conduct sensitivity analyses comparing results with and without flagged respondents.
#'
#' @param data A data frame of survey responses.
#' @param flags A data frame containing an ID column and one or more logical flag columns.
#'   Flag column names must not conflict with reserved audit column names (\code{"row_index"},
#'   \code{"n_flagged"}, \code{"n_missing_flags"}, \code{"decision"}, \code{"strategy"},
#'   \code{"n_required"}, \code{"na_action"}, \code{"excluded"}).
#' @param strategy Character string specifying the aggregation strategy:
#'   \code{"any"}, \code{"all"}, or \code{"at_least"}.
#' @param n An integer specifying the minimum number of flags required for exclusion
#'   when \code{strategy = "at_least"}. Must be \code{NULL} for other strategies.
#' @param id Optional character string specifying the ID column name present in both
#'   \code{data} and \code{flags}. If \code{NULL} (default), an existing column named
#'   \code{"id"} present in both data frames is used automatically. The ID column name
#'   must not conflict with reserved audit column names (\code{"row_index"},
#'   \code{"n_flagged"}, \code{"n_missing_flags"}, \code{"decision"}, \code{"strategy"},
#'   \code{"n_required"}, \code{"na_action"}, \code{"excluded"}).
#' @param na_action Character string specifying how to handle indeterminate (\code{NA})
#'   exclusion decisions: \code{"error"} (default), \code{"keep"}, or \code{"exclude"}.
#'
#' @return A named list with three elements:
#' \itemize{
#'   \item \code{data}: Data frame of retained respondents, preserving original columns,
#'     column order, and row values.
#'   \item \code{excluded}: Data frame of excluded respondents, preserving original columns,
#'     column order, and row values.
#'   \item \code{audit}: Data frame containing audit records for all respondents in the
#'     order of \code{data}, with fixed columns: ID, \code{row_index}, each flag column,
#'     \code{n_flagged}, \code{n_missing_flags}, \code{decision}, \code{strategy},
#'     \code{n_required}, \code{na_action}, and \code{excluded}.
#' }
#'
#' @export
#' @examples
#' survey <- data.frame(id = 1:4, q1 = c(1, 2, 3, 4), q2 = c(5, 4, 3, 2))
#' flags <- data.frame(
#'   id = 1:4,
#'   flag1 = c(FALSE, TRUE, FALSE, NA),
#'   flag2 = c(FALSE, FALSE, TRUE, FALSE)
#' )
#' filter_respondents(survey, flags, strategy = "any", na_action = "keep")
filter_respondents <- function(data,
                               flags,
                               strategy = c("any", "all", "at_least"),
                               n = NULL,
                               id = NULL,
                               na_action = c("error", "keep", "exclude")) {
  # 1. Validate data and flags data.frames
  if (!is.data.frame(data)) {
    stop("'data' must be a data.frame.", call. = FALSE)
  }
  if (!is.data.frame(flags)) {
    stop("'flags' must be a data.frame.", call. = FALSE)
  }

  data_names <- names(data)
  flags_names <- names(flags)

  if (is.null(data_names) || any(is.na(data_names)) || any(data_names == "")) {
    stop("'data' must have valid, non-missing column names.", call. = FALSE)
  }
  if (anyDuplicated(data_names) > 0L) {
    stop("Column names in 'data' must be unique.", call. = FALSE)
  }
  if (is.null(flags_names) || any(is.na(flags_names)) || any(flags_names == "")) {
    stop("'flags' must have valid, non-missing column names.", call. = FALSE)
  }
  if (anyDuplicated(flags_names) > 0L) {
    stop("Column names in 'flags' must be unique.", call. = FALSE)
  }

  # 2. Determine and validate ID column
  id_col <- NULL
  if (is.null(id)) {
    if ("id" %in% data_names && "id" %in% flags_names) {
      id_col <- "id"
    } else {
      stop("No common 'id' column found between 'data' and 'flags'. Explicit 'id' matching is required.",
           call. = FALSE)
    }
  } else {
    if (!is.character(id) || length(id) != 1L || is.na(id) || id == "") {
      stop("'id' must be a single non-empty character string or NULL.", call. = FALSE)
    }
    if (!id %in% data_names) {
      stop(sprintf("Specified ID column '%s' was not found in 'data'.", id), call. = FALSE)
    }
    if (!id %in% flags_names) {
      stop(sprintf("Specified ID column '%s' was not found in 'flags'.", id), call. = FALSE)
    }
    id_col <- id
  }

  # Validate ID column against reserved audit table column names
  reserved_audit_cols <- c("row_index", "n_flagged", "n_missing_flags",
                           "decision", "strategy", "n_required",
                           "na_action", "excluded")
  if (id_col %in% reserved_audit_cols) {
    stop(sprintf("ID column name '%s' conflicts with reserved audit table column name.", id_col), call. = FALSE)
  }

  # 3. Validate ID values
  data_id <- data[[id_col]]
  flags_id <- flags[[id_col]]

  if (!is.atomic(data_id) || is.list(data_id) || !is.null(dim(data_id))) {
    stop(sprintf("ID column '%s' in 'data' must be a one-dimensional atomic vector.", id_col), call. = FALSE)
  }
  if (!is.atomic(flags_id) || is.list(flags_id) || !is.null(dim(flags_id))) {
    stop(sprintf("ID column '%s' in 'flags' must be a one-dimensional atomic vector.", id_col), call. = FALSE)
  }

  if (any(is.na(data_id))) {
    stop(sprintf("ID column '%s' in 'data' contains missing (NA) values.", id_col), call. = FALSE)
  }
  if (any(is.na(flags_id))) {
    stop(sprintf("ID column '%s' in 'flags' contains missing (NA) values.", id_col), call. = FALSE)
  }

  if (anyDuplicated(data_id) > 0L) {
    stop(sprintf("ID column '%s' in 'data' contains duplicate values.", id_col), call. = FALSE)
  }
  if (anyDuplicated(flags_id) > 0L) {
    stop(sprintf("ID column '%s' in 'flags' contains duplicate values.", id_col), call. = FALSE)
  }

  if (typeof(data_id) != typeof(flags_id)) {
    stop(sprintf("Type mismatch in ID column '%s': 'data' is '%s', but 'flags' is '%s'.",
                 id_col, typeof(data_id), typeof(flags_id)), call. = FALSE)
  }
  if (!identical(class(data_id), class(flags_id))) {
    stop(sprintf("Class mismatch in ID column '%s': 'data' is '%s', but 'flags' is '%s'.",
                 id_col, paste(class(data_id), collapse = "/"), paste(class(flags_id), collapse = "/")),
         call. = FALSE)
  }

  if (length(data_id) != length(flags_id) || !setequal(data_id, flags_id)) {
    stop("ID sets in 'data' and 'flags' do not match exactly.", call. = FALSE)
  }

  # Align flags to data's ID order
  match_idx <- match(data_id, flags_id)
  flags_aligned <- flags[match_idx, , drop = FALSE]

  # 4. Validate flag columns
  flag_cols <- setdiff(flags_names, id_col)
  if (length(flag_cols) == 0L) {
    stop("'flags' must contain at least one logical flag column besides the ID column.", call. = FALSE)
  }
  flag_conflicts <- intersect(flag_cols, reserved_audit_cols)
  if (length(flag_conflicts) > 0L) {
    stop(sprintf("Flag column name(s) conflict with reserved audit table column name(s): %s.",
                 paste(sprintf("'%s'", flag_conflicts), collapse = ", ")), call. = FALSE)
  }
  for (col in flag_cols) {
    if (!is.logical(flags[[col]])) {
      stop(sprintf("Column '%s' in 'flags' is not a logical column.", col), call. = FALSE)
    }
  }

  # 5. Validate strategy and n
  strategy <- match.arg(strategy, c("any", "all", "at_least"))

  n_flags <- length(flag_cols)
  if (strategy == "at_least") {
    if (is.null(n) || !is.numeric(n) || length(n) != 1L || is.na(n) || !is.finite(n) ||
        n < 1 || n > n_flags || n != floor(n)) {
      stop(sprintf("'n' must be a single integer between 1 and %d when strategy = 'at_least'.", n_flags),
           call. = FALSE)
    }
    n <- as.integer(n)
    n_required <- n
  } else {
    if (!is.null(n)) {
      stop("'n' must only be specified when strategy = 'at_least'.", call. = FALSE)
    }
    n_required <- if (strategy == "any") 1L else as.integer(n_flags)
  }

  # 6. Validate na_action
  na_action <- match.arg(na_action, c("error", "keep", "exclude"))

  # 7. Evaluate Three-Valued Logic Aggregation
  n_rows <- nrow(data)
  if (n_rows == 0L) {
    n_flagged <- integer(0)
    n_missing_flags <- integer(0)
    decision <- logical(0)
    excluded_vec <- logical(0)
  } else {
    flags_matrix <- as.matrix(flags_aligned[, flag_cols, drop = FALSE])
    # Counts per row
    t_counts <- rowSums(flags_matrix == TRUE, na.rm = TRUE)
    f_counts <- rowSums(flags_matrix == FALSE, na.rm = TRUE)
    m_counts <- rowSums(is.na(flags_matrix))

    n_flagged <- as.integer(t_counts)
    n_missing_flags <- as.integer(m_counts)

    decision <- rep(NA, n_rows)

    if (strategy == "any") {
      # TRUE if any TRUE; FALSE if all FALSE; else NA
      decision[t_counts > 0L] <- TRUE
      decision[f_counts == n_flags] <- FALSE
    } else if (strategy == "all") {
      # FALSE if any FALSE; TRUE if all TRUE; else NA
      decision[f_counts > 0L] <- FALSE
      decision[t_counts == n_flags] <- TRUE
    } else if (strategy == "at_least") {
      # TRUE if t >= n; FALSE if t + m < n; else NA
      decision[t_counts >= n] <- TRUE
      decision[(t_counts + m_counts) < n] <- FALSE
    }

    # Handle na_action
    na_decisions <- is.na(decision)
    if (any(na_decisions)) {
      if (na_action == "error") {
        stop(sprintf("Aggregated exclusion decision is NA for %d respondent(s) under strategy '%s'. Resolve NAs or specify 'na_action'.",
                     sum(na_decisions), strategy), call. = FALSE)
      } else if (na_action == "keep") {
        excluded_vec <- ifelse(na_decisions, FALSE, decision)
      } else if (na_action == "exclude") {
        excluded_vec <- ifelse(na_decisions, TRUE, decision)
      }
    } else {
      excluded_vec <- decision
    }
  }

  # 8. Assemble audit table
  # Fixed column order: ID, row_index, each flag column, n_flagged, n_missing_flags, decision, strategy, n_required, na_action, excluded
  audit_list <- list()
  audit_list[[id_col]] <- data_id
  audit_list[["row_index"]] <- seq_len(n_rows)
  for (col in flag_cols) {
    audit_list[[col]] <- if (n_rows == 0L) logical(0) else flags_aligned[[col]]
  }
  audit_list[["n_flagged"]] <- n_flagged
  audit_list[["n_missing_flags"]] <- n_missing_flags
  audit_list[["decision"]] <- decision
  audit_list[["strategy"]] <- rep(strategy, n_rows)
  audit_list[["n_required"]] <- rep(n_required, n_rows)
  audit_list[["na_action"]] <- rep(na_action, n_rows)
  audit_list[["excluded"]] <- excluded_vec

  audit_df <- as.data.frame(audit_list, stringsAsFactors = FALSE, check.names = FALSE)
  row.names(audit_df) <- NULL

  # 9. Split retained and excluded data rows
  if (n_rows == 0L) {
    retained_data <- data
    excluded_data <- data
  } else {
    retained_data <- data[!excluded_vec, , drop = FALSE]
    excluded_data <- data[excluded_vec, , drop = FALSE]
  }

  list(
    data = retained_data,
    excluded = excluded_data,
    audit = audit_df
  )
}
