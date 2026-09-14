#' Valid FRED unit transformations
#' @noRd
fred_units_choices <- c(
  "lin", "chg", "ch1", "pch", "pc1", "pca", "cch", "cca", "log"
)

#' Valid FRED frequency codes
#' @noRd
fred_frequency_choices <- c(
  "d", "w", "bw", "m", "q", "sa", "a",
  "wef", "weth", "wew", "wetu", "wem", "wesu", "wesa",
  "bwew", "bwem"
)

#' Valid FRED aggregation methods
#' @noRd
fred_aggregation_choices <- c("avg", "sum", "eop")

#' Download FRED series observations
#'
#' Fetches one or more series from the FRED `series/observations` endpoint and
#' returns them stacked in a single tidy data frame -- one row per series per
#' date -- which is the shape ggplot2 wants for a multi-series chart.
#'
#' FRED encodes a missing observation as the string `"."`; those become `NA`
#' rather than a coercion warning.
#'
#' @param series_id Character vector of FRED series IDs, e.g. `"UNRATE"` or
#'   `c("UNRATE", "GDPC1")`.
#' @param start,end Optional observation window. A `Date`, or anything
#'   [as.Date()] accepts. `NULL` means the full available history.
#' @param units Unit transformation applied by FRED before it returns the data:
#'   `"lin"` (levels, the default), `"chg"` (change), `"ch1"` (change from a
#'   year ago), `"pch"` (percent change), `"pc1"` (percent change from a year
#'   ago), `"pca"` (compounded annual rate of change), `"cch"`, `"cca"` or
#'   `"log"`.
#' @param frequency Optional lower frequency to aggregate to, e.g. `"m"`, `"q"`
#'   or `"a"`. FRED can only aggregate downwards.
#' @param aggregation_method How to aggregate when `frequency` is set: `"avg"`,
#'   `"sum"` or `"eop"` (end of period).
#' @param key A FRED API key. Defaults to [fred_key()].
#'
#' @return A data frame with columns `series_id` (character), `date` (`Date`)
#'   and `value` (numeric), sorted by series then date. A series with no
#'   observations in the requested window contributes no rows.
#'
#' @seealso [fred_series_info()] for the metadata behind a series, and
#'   [fred_search()] to find an ID in the first place.
#'
#' @examplesIf econscape::fred_has_key()
#' fred_series("UNRATE", start = "2000-01-01")
#'
#' # Several series at once, as year-on-year percent change
#' fred_series(c("CPIAUCSL", "PCEPI"), start = "2015-01-01", units = "pc1")
#' @export
fred_series <- function(series_id,
                        start = NULL,
                        end = NULL,
                        units = "lin",
                        frequency = NULL,
                        aggregation_method = "avg",
                        key = fred_key()) {
  if (!is.character(series_id) || length(series_id) == 0L || anyNA(series_id)) {
    cli::cli_abort("{.arg series_id} must be a character vector of FRED IDs.")
  }
  units <- match_code(units, fred_units_choices)
  aggregation_method <- match_code(aggregation_method, fred_aggregation_choices)
  if (!is.null(frequency)) {
    frequency <- match_code(frequency, fred_frequency_choices)
  }

  params <- list(
    observation_start = as_fred_date(start),
    observation_end = as_fred_date(end),
    units = units,
    frequency = frequency,
    aggregation_method = if (is.null(frequency)) NULL else aggregation_method,
    limit = 100000L
  )

  out <- lapply(series_id, function(id) {
    body <- fred_get(
      "series/observations",
      params = c(list(series_id = id), params),
      key = key
    )
    parse_observations(body, series_id = id)
  })

  do.call(rbind, out)
}

#' Turn an observations payload into a data frame
#'
#' Split out from [fred_series()] so the parsing can be tested against a saved
#' payload with no network involved.
#'
#' @param body Parsed JSON body from `series/observations`.
#' @param series_id The ID that was requested; FRED does not repeat it per row.
#' @return A three-column data frame.
#' @noRd
parse_observations <- function(body, series_id) {
  obs <- body[["observations"]]
  if (is.null(obs) || length(obs) == 0L) {
    return(data.frame(
      series_id = character(0),
      date = as.Date(character(0)),
      value = numeric(0),
      stringsAsFactors = FALSE
    ))
  }

  reported <- body[["count"]]
  limit <- body[["limit"]]
  if (!is.null(reported) && !is.null(limit) && reported > limit) {
    cli::cli_warn(c(
      "{.val {series_id}} has {reported} observations but only {limit} came back.",
      "i" = "Narrow the window with {.arg start} / {.arg end}."
    ))
  }

  raw <- vapply(obs, function(o) as.character(o[["value"]] %||% NA), character(1))
  dates <- vapply(obs, function(o) as.character(o[["date"]]), character(1))

  # FRED writes a missing observation as ".", which as.numeric() would turn
  # into NA only alongside a coercion warning.
  raw[raw == "."] <- NA_character_

  df <- data.frame(
    series_id = series_id,
    date = as.Date(dates),
    value = as.numeric(raw),
    stringsAsFactors = FALSE
  )
  df[order(df$date), , drop = FALSE]
}

#' Look up FRED series metadata
#'
#' Returns the title, units, frequency and seasonal-adjustment status of one or
#' more series -- the information needed to label an axis honestly.
#'
#' @inheritParams fred_series
#'
#' @return A data frame with one row per series and columns `series_id`,
#'   `title`, `units`, `units_short`, `frequency`, `seasonal_adjustment`,
#'   `observation_start`, `observation_end`, `last_updated`, `popularity` and
#'   `notes`.
#'
#' @examplesIf econscape::fred_has_key()
#' fred_series_info("UNRATE")$title
#' @export
fred_series_info <- function(series_id, key = fred_key()) {
  if (!is.character(series_id) || length(series_id) == 0L || anyNA(series_id)) {
    cli::cli_abort("{.arg series_id} must be a character vector of FRED IDs.")
  }
  out <- lapply(series_id, function(id) {
    body <- fred_get("series", params = list(series_id = id), key = key)
    parse_series_meta(body)
  })
  do.call(rbind, out)
}

#' Search FRED for series matching free text
#'
#' @param text Search terms, e.g. `"real median household income"`.
#' @param limit Maximum number of results, 1 to 1000.
#' @param order_by Ranking: `"search_rank"`, `"popularity"`,
#'   `"observation_start"`, `"observation_end"` or `"last_updated"`.
#' @param key A FRED API key. Defaults to [fred_key()].
#'
#' @return A data frame in the same shape as [fred_series_info()].
#'
#' @examplesIf econscape::fred_has_key()
#' head(fred_search("unemployment rate", limit = 5)[, c("series_id", "title")])
#' @export
fred_search <- function(text,
                        limit = 25L,
                        order_by = "search_rank",
                        key = fred_key()) {
  if (!is.character(text) || length(text) != 1L || !nzchar(text)) {
    cli::cli_abort("{.arg text} must be a single non-empty string.")
  }
  order_by <- match_code(
    order_by,
    c("search_rank", "popularity", "observation_start",
      "observation_end", "last_updated")
  )
  limit <- as.integer(limit)
  if (is.na(limit) || limit < 1L || limit > 1000L) {
    cli::cli_abort("{.arg limit} must be a whole number between 1 and 1000.")
  }

  body <- fred_get(
    "series/search",
    params = list(
      search_text = text,
      limit = limit,
      order_by = order_by,
      sort_order = if (order_by == "search_rank") "asc" else "desc"
    ),
    key = key
  )
  parse_series_meta(body)
}

#' Fields kept from a `seriess` payload, in output order
#' @noRd
series_meta_fields <- c(
  series_id = "id",
  title = "title",
  units = "units",
  units_short = "units_short",
  frequency = "frequency",
  seasonal_adjustment = "seasonal_adjustment",
  observation_start = "observation_start",
  observation_end = "observation_end",
  last_updated = "last_updated",
  popularity = "popularity",
  notes = "notes"
)

#' Turn a `seriess` payload into a data frame
#'
#' Shared by [fred_series_info()] and [fred_search()], which return the same
#' structure from different endpoints.
#'
#' @param body Parsed JSON body containing a `seriess` array.
#' @return One row per series.
#' @noRd
parse_series_meta <- function(body) {
  ss <- body[["seriess"]]
  if (is.null(ss) || length(ss) == 0L) {
    empty <- as.data.frame(
      stats::setNames(
        rep(list(character(0)), length(series_meta_fields)),
        names(series_meta_fields)
      ),
      stringsAsFactors = FALSE
    )
    empty$popularity <- numeric(0)
    empty$observation_start <- as.Date(character(0))
    empty$observation_end <- as.Date(character(0))
    return(empty)
  }

  cols <- lapply(series_meta_fields, function(field) {
    vapply(ss, function(s) {
      v <- s[[field]]
      if (is.null(v)) NA_character_ else as.character(v)
    }, character(1))
  })
  df <- as.data.frame(cols, stringsAsFactors = FALSE)
  names(df) <- names(series_meta_fields)

  df$popularity <- suppressWarnings(as.numeric(df$popularity))
  df$observation_start <- as.Date(df$observation_start)
  df$observation_end <- as.Date(df$observation_end)
  df
}
