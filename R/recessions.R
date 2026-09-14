#' US recession dates from the NBER
#'
#' Peak and trough months of every US business cycle contraction dated by the
#' National Bureau of Economic Research, from the contraction that began in
#' June 1857 to the one that began in February 2020.
#'
#' The NBER dates turning points to a month, not a day. Each date here is the
#' first day of the dated month: `peak` is the last month of the expansion and
#' `trough` the last month of the contraction, which is the convention behind
#' the shaded bands on FRED's own charts.
#'
#' The table is a static copy, so a newly dated recession will not appear until
#' the package is updated. [fred_recessions()] reads the same turning points
#' live from FRED and is the one to use if that matters.
#'
#' @format A data frame with 34 rows and 3 columns:
#' \describe{
#'   \item{peak}{`Date`. First day of the peak month.}
#'   \item{trough}{`Date`. First day of the trough month.}
#'   \item{months}{`integer`. Approximate length of the contraction.}
#' }
#' @source National Bureau of Economic Research, US Business Cycle Expansions
#'   and Contractions,
#'   <https://www.nber.org/research/data/us-business-cycle-expansions-and-contractions>
"nber_recessions"

#' Shade recession bands behind a time series
#'
#' Returns a rectangle annotation spanning the full height of the panel for
#' each recession, to be added before the data layers so the shading sits
#' underneath them.
#'
#' @param data A data frame of recession intervals with `peak` and `trough`
#'   date columns. Defaults to [nber_recessions]; pass the result of
#'   [fred_recessions()] for a live copy.
#' @param from,to Optional window. Recessions that do not overlap it are
#'   dropped, which keeps the x-axis from stretching back to 1857 when the
#'   series starts in 1990.
#' @param fill Band colour. `NULL` follows the current style ([set_style()]).
#' @param alpha Band opacity.
#'
#' @return A ggplot2 annotation layer, or a zero-row layer if nothing overlaps
#'   the window.
#'
#' @examples
#' library(ggplot2)
#' ggplot(economics, aes(date, uempmed)) +
#'   annotate_recessions(from = min(economics$date), to = max(economics$date)) +
#'   geom_line(colour = econ_colours("blue"), linewidth = 0.7) +
#'   scale_x_econ_date() +
#'   scale_y_econ() +
#'   labs_econ(
#'     title = "The long wait",
#'     subtitle = "United States, median duration of unemployment, weeks",
#'     note = "Shaded areas are NBER-dated recessions",
#'     source = "FRED, Federal Reserve Bank of St Louis"
#'   ) +
#'   theme_econ()
#' @export
annotate_recessions <- function(data = nber_recessions,
                                from = NULL,
                                to = NULL,
                                fill = NULL,
                                alpha = 0.35) {
  if (!is.data.frame(data) || !all(c("peak", "trough") %in% names(data))) {
    cli::cli_abort("{.arg data} must be a data frame with {.field peak} and {.field trough} columns.")
  }
  fill <- fill %||% style_colour("band")
  bands <- clip_recessions(data, from = from, to = to)

  ggplot2::annotate(
    "rect",
    xmin = bands$peak,
    xmax = bands$trough,
    ymin = -Inf,
    ymax = Inf,
    fill = fill,
    alpha = alpha
  )
}

#' Trim recession intervals to a window
#'
#' Split out from [annotate_recessions()] so the interval logic can be tested
#' directly. An interval is kept when it overlaps the window at all, and is
#' then clipped to it.
#'
#' @param data Recession intervals.
#' @param from,to Window bounds, or `NULL` for unbounded.
#' @return A data frame of clipped intervals, possibly with zero rows.
#' @noRd
clip_recessions <- function(data, from = NULL, to = NULL) {
  from <- if (is.null(from)) NULL else as.Date(from)
  to <- if (is.null(to)) NULL else as.Date(to)
  if (!is.null(from) && !is.null(to) && from > to) {
    cli::cli_abort("{.arg from} must not be later than {.arg to}.")
  }

  keep <- rep(TRUE, nrow(data))
  if (!is.null(to)) {
    keep <- keep & data$peak <= to
  }
  if (!is.null(from)) {
    keep <- keep & data$trough >= from
  }
  out <- data[keep, c("peak", "trough"), drop = FALSE]

  if (!is.null(from)) {
    out$peak <- pmax(out$peak, from)
  }
  if (!is.null(to)) {
    out$trough <- pmin(out$trough, to)
  }
  out
}

#' Fetch recession dates live from FRED
#'
#' Downloads `USREC`, the NBER-based recession indicator (1 during a
#' contraction, 0 otherwise), and collapses each run of ones into a
#' peak/trough interval. Use this instead of the bundled [nber_recessions] when
#' you need the current dating, including any recession called since this
#' package was last released.
#'
#' @inheritParams fred_series
#'
#' @return A data frame with `peak` and `trough` `Date` columns, in the same
#'   shape [annotate_recessions()] expects.
#'
#' @examplesIf econscape::fred_has_key()
#' tail(fred_recessions(), 3)
#' @export
fred_recessions <- function(key = fred_key()) {
  obs <- fred_series("USREC", key = key)
  runs_to_intervals(obs$date, obs$value)
}

#' Collapse a 0/1 indicator into intervals
#'
#' Each maximal run of ones becomes one row. The trough is the last month of
#' the run, matching how the NBER dates a trough (and how [nber_recessions] is
#' stored), rather than the first month of the following expansion.
#'
#' @param date Dates, assumed sorted ascending.
#' @param value Indicator values; `NA` is treated as 0.
#' @return A data frame with `peak` and `trough` columns.
#' @noRd
runs_to_intervals <- function(date, value) {
  empty <- data.frame(
    peak = as.Date(character(0)),
    trough = as.Date(character(0)),
    stringsAsFactors = FALSE
  )
  if (length(date) == 0L) {
    return(empty)
  }

  flag <- !is.na(value) & value > 0
  if (!any(flag)) {
    return(empty)
  }

  # A run starts where the flag turns on and ends where it turns off.
  starts <- which(flag & !c(FALSE, utils::head(flag, -1)))
  ends <- which(flag & !c(utils::tail(flag, -1), FALSE))

  data.frame(
    peak = date[starts],
    trough = date[ends],
    stringsAsFactors = FALSE
  )
}
