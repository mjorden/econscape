#' Trend-cycle decompositions
#'
#' Two ways of splitting a series into a slow-moving trend and the cycle
#' around it.
#'
#' `hp_filter()` is Hodrick and Prescott (1997): the trend minimises
#' \eqn{\sum (y_t - \tau_t)^2 + \lambda \sum (\Delta^2 \tau_t)^2}, a
#' pentadiagonal linear system solved directly. The smoothing parameter is
#' usually set by data frequency; the defaults are the conventional
#' 100 / 1600 / 14400 for annual / quarterly / monthly data. (Ravn and Uhlig
#' 2002 argue for 6.25 / 1600 / 129600; pass `lambda` to use them.)
#'
#' `hamilton_filter()` is Hamilton (2018), who argues the HP filter invents
#' spurious cycles: regress \eqn{y_{t+h}} on the current value and `p - 1`
#' lags, and call the residual the cycle -- the part of the series `h`
#' periods ahead that could not be forecast from its recent past. The first
#' `h + p - 1` observations have no cycle value. Defaults `h = 8, p = 4` are
#' the paper's quarterly recommendation; use `h = 24, p = 12` for monthly
#' data.
#'
#' @param x A numeric vector, or a data frame from [fred_series()] with
#'   `date` and `value` columns (a single series).
#' @param lambda Smoothing parameter. Overrides `frequency`.
#' @param frequency `"annual"`, `"quarterly"` or `"monthly"`, used to pick
#'   `lambda` when it is not given.
#' @param h Forecast horizon.
#' @param p Number of lags in the forecasting regression (including the
#'   current value).
#'
#' @return An object of class `trend_cycle`: a data frame with columns
#'   `date` (if `x` had one), `value`, `trend` and `cycle`, plus attributes
#'   `method` and the tuning parameters. [plot_trend_cycle()] draws it.
#'
#' @references
#' Hodrick, R. J. and Prescott, E. C. (1997). Postwar U.S. business cycles:
#' an empirical investigation. *Journal of Money, Credit and Banking* 29(1).
#'
#' Hamilton, J. D. (2018). Why you should never use the Hodrick-Prescott
#' filter. *Review of Economics and Statistics* 100(5).
#'
#' Ravn, M. O. and Uhlig, H. (2002). On adjusting the Hodrick-Prescott filter
#' for the frequency of observations. *Review of Economics and Statistics*
#' 84(2).
#'
#' @examples
#' econ <- ggplot2::economics
#' u <- data.frame(date = econ$date, value = 100 * econ$unemploy / econ$pop)
#'
#' hp <- hp_filter(u, frequency = "monthly")
#' head(hp)
#'
#' hm <- hamilton_filter(u, h = 24, p = 12)
#' range(hm$cycle, na.rm = TRUE)
#' @name trend_cycle
NULL

#' Coerce filter input to (date, value)
#' @noRd
as_series <- function(x, arg = rlang::caller_arg(x)) {
  if (is.data.frame(x)) {
    if (!"value" %in% names(x)) {
      cli::cli_abort("{.arg {arg}} must have a {.field value} column.")
    }
    if ("series_id" %in% names(x) && length(unique(x$series_id)) > 1L) {
      cli::cli_abort("{.arg {arg}} holds {length(unique(x$series_id))} series; filter one at a time.")
    }
    date <- if ("date" %in% names(x)) x$date else NULL
    value <- x$value
  } else {
    if (!is.numeric(x)) {
      cli::cli_abort("{.arg {arg}} must be a numeric vector or a data frame with a {.field value} column.")
    }
    date <- NULL
    value <- x
  }
  if (anyNA(value)) {
    cli::cli_abort("{.arg {arg}} contains missing values; drop or fill them first.")
  }
  list(date = date, value = as.numeric(value))
}

#' @noRd
new_trend_cycle <- function(s, trend, cycle, method, ...) {
  out <- data.frame(value = s$value, trend = trend, cycle = cycle)
  if (!is.null(s$date)) {
    out <- cbind(date = s$date, out)
  }
  structure(out, class = c("trend_cycle", "data.frame"), method = method, ...)
}

#' @rdname trend_cycle
#' @export
hp_filter <- function(x, lambda = NULL, frequency = c("quarterly", "annual", "monthly")) {
  s <- as_series(x)
  if (is.null(lambda)) {
    frequency <- match.arg(frequency)
    lambda <- c(annual = 100, quarterly = 1600, monthly = 14400)[[frequency]]
  } else {
    check_positive(lambda)
  }
  n <- length(s$value)
  if (n < 4L) {
    cli::cli_abort("Need at least 4 observations; got {n}.")
  }
  # K is the (n-2) x n second-difference operator; the trend solves
  # (I + lambda K'K) tau = y.
  K <- matrix(0, n - 2, n)
  for (i in seq_len(n - 2)) {
    K[i, i:(i + 2)] <- c(1, -2, 1)
  }
  A <- diag(n) + lambda * crossprod(K)
  trend <- as.numeric(solve(A, s$value))
  new_trend_cycle(s, trend, s$value - trend, method = "hp", lambda = lambda)
}

#' @rdname trend_cycle
#' @export
hamilton_filter <- function(x, h = 8L, p = 4L) {
  s <- as_series(x)
  h <- as.integer(check_positive(h))
  p <- as.integer(check_positive(p))
  y <- s$value
  n <- length(y)
  if (n <= h + p + 1L) {
    cli::cli_abort("Need more than {h + p + 1} observations for h = {h}, p = {p}; got {n}.")
  }
  # Rows t = h + p, ..., n: y[t] on y[t-h], y[t-h-1], ..., y[t-h-p+1].
  t_idx <- (h + p):n
  X <- cbind(1, vapply(0:(p - 1), function(j) y[t_idx - h - j], numeric(length(t_idx))))
  fit <- stats::lm.fit(X, y[t_idx])
  trend <- rep(NA_real_, n)
  cycle <- rep(NA_real_, n)
  trend[t_idx] <- fit$fitted.values
  cycle[t_idx] <- fit$residuals
  new_trend_cycle(s, trend, cycle, method = "hamilton", h = h, p = p)
}

#' @export
print.trend_cycle <- function(x, ...) {
  method <- attr(x, "method")
  desc <- if (method == "hp") {
    sprintf("Hodrick-Prescott, lambda = %s", format(attr(x, "lambda")))
  } else {
    sprintf("Hamilton, h = %d, p = %d", attr(x, "h"), attr(x, "p"))
  }
  cat(sprintf("<Trend-cycle decomposition: %s; %d observations>\n", desc, nrow(x)))
  print(utils::head(as.data.frame(x), 6), ...)
  if (nrow(x) > 6) cat(sprintf("  ... %d more rows\n", nrow(x) - 6))
  invisible(x)
}

#' Draw a trend-cycle decomposition
#'
#' Two panels in the house style: the series with its trend, and the cycle
#' below it around zero. With dates present, NBER recessions are shaded.
#'
#' @param tc A `trend_cycle` from [hp_filter()] or [hamilton_filter()].
#' @param title,subtitle,source Passed to [labs_econ()]; sensible defaults
#'   are filled in.
#' @param recessions Shade NBER recessions? Only possible when `tc` has a
#'   `date` column.
#' @param panel Passed to [theme_econ()].
#'
#' @return A ggplot object. Add [econ_masthead()] last if you want the block.
#'
#' @examples
#' econ <- ggplot2::economics
#' u <- data.frame(date = econ$date, value = 100 * econ$unemploy / econ$pop)
#' plot_trend_cycle(hp_filter(u, frequency = "monthly"),
#'                  title = "Unemployment and its trend")
#' @export
plot_trend_cycle <- function(tc, title = NULL, subtitle = NULL, source = NULL,
                             recessions = TRUE, panel = NULL) {
  if (!inherits(tc, "trend_cycle")) {
    cli::cli_abort("{.arg tc} must come from {.fn hp_filter} or {.fn hamilton_filter}.")
  }
  has_date <- "date" %in% names(tc)
  x <- if (has_date) tc$date else seq_len(nrow(tc))
  method <- attr(tc, "method")

  if (is.null(title)) title <- "Trend and cycle"
  if (is.null(subtitle)) {
    subtitle <- if (method == "hp") {
      sprintf("Hodrick-Prescott filter, lambda = %s", format(attr(tc, "lambda")))
    } else {
      sprintf("Hamilton filter, h = %d, p = %d", attr(tc, "h"), attr(tc, "p"))
    }
  }

  level <- rbind(
    data.frame(x = x, y = tc$value, series = "Series", panel = "Level"),
    data.frame(x = x, y = tc$trend, series = "Trend", panel = "Level")
  )
  cycle <- data.frame(x = x, y = tc$cycle, series = "Cycle", panel = "Cycle")
  long <- rbind(level, cycle)
  long <- long[!is.na(long$y), , drop = FALSE]
  long$panel <- factor(long$panel, levels = c("Level", "Cycle"))

  p <- ggplot2::ggplot()
  if (recessions && has_date) {
    p <- p + annotate_recessions(from = min(x), to = max(x))
  }
  p +
    ggplot2::geom_hline(
      data = data.frame(panel = factor("Cycle", levels = c("Level", "Cycle")), y = 0),
      ggplot2::aes(yintercept = .data$y), colour = econ_surface(panel)$muted, linewidth = 0.3
    ) +
    ggplot2::geom_line(
      data = long,
      ggplot2::aes(x = .data$x, y = .data$y, colour = .data$series),
      linewidth = 0.7
    ) +
    ggplot2::scale_colour_manual(
      values = c(Series = style_colour("primary"), Trend = style_colour("secondary"),
                 Cycle = style_colour("tertiary")),
      breaks = c("Series", "Trend", "Cycle")
    ) +
    ggplot2::facet_wrap(~panel, ncol = 1, scales = "free_y") +
    (if (has_date) scale_x_econ_date() else ggplot2::scale_x_continuous(expand = ggplot2::expansion(0))) +
    scale_y_econ(expand = ggplot2::expansion(mult = 0.05)) +
    labs_econ(title = title, subtitle = subtitle, source = source,
              note = if (recessions && has_date) "Shaded areas are NBER-dated recessions" else NULL) +
    theme_econ(panel = panel)
}
