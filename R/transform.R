#' Periods per year implied by a date vector
#' @noRd
infer_frequency <- function(date) {
  if (length(date) < 3L) {
    cli::cli_abort("Cannot infer the frequency from fewer than 3 dates; pass {.arg frequency}.")
  }
  gap <- stats::median(as.numeric(diff(sort(date))))
  if (gap >= 300) 1L else if (gap >= 80) 4L else if (gap >= 25) 12L else if (gap >= 6) 52L else 260L
}

#' Transform a tidy series the way FRED does
#'
#' [fred_series()] can ask the API for a transformed series through `units`;
#' this applies the same definitions locally, so a frame already downloaded
#' (or one built from any other source) can be reworked without another
#' request. Each series in the frame is transformed separately.
#'
#' The codes match FRED's:
#' * `"lin"` -- levels, unchanged.
#' * `"chg"` -- change from the previous observation.
#' * `"ch1"` -- change from a year ago.
#' * `"pch"` -- percent change from the previous observation.
#' * `"pc1"` -- percent change from a year ago.
#' * `"pca"` -- compounded annual rate of change.
#' * `"cch"` -- continuously compounded rate of change (log difference, in
#'   percent).
#' * `"cca"` -- continuously compounded annual rate of change.
#' * `"log"` -- natural log.
#' * `"index"` -- rescaled so the first non-missing observation is 100.
#'
#' "A year ago" needs the number of observations per year, inferred from the
#' spacing of `date` unless `frequency` is given.
#'
#' @param df A data frame with `date` and `value` columns and optionally
#'   `series_id`, as returned by [fred_series()].
#' @param how One of the codes above.
#' @param frequency Observations per year (1, 4, 12, 52, 260). Inferred from
#'   the dates when `NULL`.
#'
#' @return The same frame with `value` transformed, rows in the order they
#'   arrived. Observations that need an earlier one that does not exist
#'   become `NA` rather than being dropped, so the rows still line up with
#'   the original. "Previous" and "a year ago" are found by date within each
#'   series, so the input need not be sorted.
#'
#' @examples
#' econ <- ggplot2::economics
#' cpi_like <- data.frame(series_id = "PCE", date = econ$date, value = econ$pce)
#' head(transform_series(cpi_like, "pc1"), 14)
#' head(transform_series(cpi_like, "index"))
#' @export
transform_series <- function(df, how = c("lin", "chg", "ch1", "pch", "pc1", "pca",
                                         "cch", "cca", "log", "index"),
                             frequency = NULL) {
  how <- match.arg(how)
  if (!is.data.frame(df) || !all(c("date", "value") %in% names(df))) {
    cli::cli_abort("{.arg df} must have {.field date} and {.field value} columns.")
  }
  if (!is.null(frequency)) {
    if (!frequency %in% c(1, 4, 12, 52, 260)) {
      cli::cli_abort("{.arg frequency} must be 1, 4, 12, 52 or 260 observations per year.")
    }
  }
  groups <- if ("series_id" %in% names(df)) df$series_id else rep("series", nrow(df))
  # Work series by series in date order, but write the results back into the
  # caller's rows so the frame comes back in the order it arrived.
  value <- as.numeric(df$value)
  for (rows in split(seq_len(nrow(df)), groups, drop = TRUE)) {
    rows <- rows[order(df$date[rows])]
    ppy <- frequency %||% infer_frequency(df$date[rows])
    value[rows] <- transform_values(df$value[rows], how, ppy)
  }
  df$value <- value
  df
}

#' @noRd
lag_by <- function(v, k) {
  if (k <= 0) return(v)
  c(rep(NA_real_, k), utils::head(v, -k))
}

#' @noRd
transform_values <- function(v, how, ppy) {
  switch(how,
    lin = v,
    chg = v - lag_by(v, 1),
    ch1 = v - lag_by(v, ppy),
    pch = 100 * (v / lag_by(v, 1) - 1),
    pc1 = 100 * (v / lag_by(v, ppy) - 1),
    pca = 100 * ((v / lag_by(v, 1))^ppy - 1),
    cch = 100 * (log(v) - log(lag_by(v, 1))),
    cca = 100 * ppy * (log(v) - log(lag_by(v, 1))),
    log = log(v),
    index = {
      first <- v[which(!is.na(v))[1]]
      100 * v / first
    }
  )
}
