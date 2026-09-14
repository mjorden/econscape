#' MacKinnon (2010) response-surface coefficients for the Dickey-Fuller t
#'
#' Critical value = b_inf + b_1 / T + b_2 / T^2, for the test regression with
#' no deterministic terms (`none`), a constant (`drift`), and a constant and
#' trend (`trend`), at the 1, 5 and 10 percent levels. One variable (N = 1).
#' @noRd
adf_response_surface <- list(
  none = rbind(
    `1%`  = c(-2.5658, -1.960, -10.04),
    `5%`  = c(-1.9393, -0.398,   0.00),
    `10%` = c(-1.6156, -0.181,   0.00)
  ),
  drift = rbind(
    `1%`  = c(-3.4336, -5.999, -29.25),
    `5%`  = c(-2.8621, -2.738,  -8.36),
    `10%` = c(-2.5671, -1.438,  -4.48)
  ),
  trend = rbind(
    `1%`  = c(-3.9638, -8.353, -47.44),
    `5%`  = c(-3.4126, -4.039, -17.83),
    `10%` = c(-3.1279, -2.418,  -7.58)
  )
)

#' Augmented Dickey-Fuller test for a unit root
#'
#' Estimates \eqn{\Delta y_t = \alpha + \beta t + \gamma y_{t-1} +
#' \sum_{i=1}^{p} \phi_i \Delta y_{t-i} + \varepsilon_t} and tests
#' \eqn{\gamma = 0} (a unit root) against \eqn{\gamma < 0} (stationarity)
#' with the t statistic on \eqn{\gamma}. Under the null that statistic does
#' not have a t distribution; critical values come from MacKinnon's (2010)
#' response surfaces, which adjust for sample size.
#'
#' Choose `type` by what the series looks like under the alternative:
#' `"drift"` (the default) for a series that fluctuates around a non-zero
#' level, `"trend"` for one that grows, `"none"` only for a series known to
#' be centred on zero. Including deterministic terms the data do not need
#' costs power; leaving out terms it does need makes the test invalid.
#'
#' @param x A numeric vector, or a single-series data frame with a `value`
#'   column.
#' @param lags Number of lagged differences `p`. With `NULL` the lag length
#'   is chosen by AIC over `0:max_lags`, skipping any candidate that would
#'   leave fewer than three residual degrees of freedom.
#' @param type Deterministic terms: `"drift"`, `"trend"` or `"none"`.
#' @param max_lags Upper bound for the AIC search. Defaults to Schwert's
#'   \eqn{\lfloor 12 (T/100)^{1/4} \rfloor}.
#'
#' @return An object of class `adf_test`: a list with `statistic`,
#'   `critical` (named vector at 1, 5 and 10 percent), `reject` (logical, per
#'   level), `lags`, `type`, `nobs` and the fitted `regression`. No p-value
#'   is reported; compare the statistic with the critical values, which is
#'   what the printer does.
#'
#' @references
#' MacKinnon, J. G. (2010). Critical values for cointegration tests. Queen's
#' Economics Department Working Paper 1227.
#'
#' Said, S. E. and Dickey, D. A. (1984). Testing for unit roots in
#' autoregressive-moving average models of unknown order. *Biometrika* 71(3).
#'
#' @examples
#' set.seed(1)
#' rw <- cumsum(rnorm(200))         # a random walk: do not reject
#' adf_test(rw)
#'
#' ar <- as.numeric(stats::arima.sim(list(ar = 0.5), 200))   # stationary: reject
#' adf_test(ar)
#' @export
adf_test <- function(x, lags = NULL, type = c("drift", "trend", "none"), max_lags = NULL) {
  s <- as_series(x)
  type <- match.arg(type)
  y <- s$value
  n <- length(y)
  if (n < 20L) {
    cli::cli_abort("Need at least 20 observations; got {n}.")
  }
  if (is.null(max_lags)) {
    max_lags <- floor(12 * (n / 100)^(1 / 4))
  }
  if (!is.null(lags)) {
    lags <- as.integer(check_positive(lags, zero_ok = TRUE))
  }

  fit_adf <- function(p) {
    # Common sample across candidate lag lengths so AIC values compare.
    start <- max_lags + 2L
    if (!is.null(lags)) start <- p + 2L
    t_idx <- start:n
    dy <- diff(y)
    lhs <- dy[t_idx - 1L]
    X <- cbind(y_lag = y[t_idx - 1L])
    if (p > 0) {
      for (i in seq_len(p)) {
        X <- cbind(X, dy[t_idx - 1L - i])
      }
      colnames(X)[-1] <- paste0("dy_lag", seq_len(p))
    }
    if (type != "none") X <- cbind(X, const = 1)
    if (type == "trend") X <- cbind(X, trend = t_idx)
    fit <- stats::lm.fit(X, lhs)
    rss <- sum(fit$residuals^2)
    m <- length(lhs)
    list(fit = fit, X = X, lhs = lhs, m = m, df = m - ncol(X),
         aic = m * log(rss / m) + 2 * ncol(X))
  }
  # A regression with (almost) no residual degrees of freedom gives a
  # statistic that is NaN or meaningless, not a test; and in the AIC search
  # such a candidate always wins because its residual sum is ~0.
  min_df <- 3L

  if (is.null(lags)) {
    candidates <- lapply(0:max_lags, fit_adf)
    usable <- vapply(candidates, function(cc) cc$df >= min_df, logical(1))
    if (!any(usable)) {
      cli::cli_abort(c(
        "Too few observations ({n}) for an ADF regression with {.arg type} = {.val {type}}.",
        "i" = "Every candidate lag length leaves fewer than {min_df} residual degrees of freedom."
      ))
    }
    aics <- vapply(candidates, function(cc) cc$aic, numeric(1))
    aics[!usable] <- Inf
    lags <- (0:max_lags)[which.min(aics)]
  }
  res <- fit_adf(lags)
  if (res$df < min_df) {
    cli::cli_abort(c(
      "Too few observations ({n}) for {lags} lagged difference{?s} with {.arg type} = {.val {type}}.",
      "i" = "The regression would have {res$df} residual degree{?s} of freedom; need at least {min_df}."
    ))
  }
  fit <- res$fit
  m <- res$m
  k <- ncol(res$X)
  sigma2 <- sum(fit$residuals^2) / (m - k)
  XtX_inv <- solve(crossprod(res$X))
  se_gamma <- sqrt(sigma2 * XtX_inv[1, 1])
  statistic <- unname(fit$coefficients[1] / se_gamma)

  rs <- adf_response_surface[[type]]
  critical <- rs[, 1] + rs[, 2] / m + rs[, 3] / m^2
  names(critical) <- rownames(rs)

  structure(
    list(
      statistic = statistic,
      critical = critical,
      reject = statistic < critical,
      lags = lags,
      type = type,
      nobs = m,
      gamma = unname(fit$coefficients[1]),
      regression = fit
    ),
    class = "adf_test"
  )
}

#' @export
print.adf_test <- function(x, ...) {
  terms <- switch(x$type, none = "no constant", drift = "constant", trend = "constant and trend")
  cat(sprintf("<Augmented Dickey-Fuller test: %s, %d lagged difference%s, %d observations>\n",
              terms, x$lags, if (x$lags == 1) "" else "s", x$nobs))
  cat(sprintf("  statistic %s\n", formatC(x$statistic, digits = 3, format = "f")))
  for (lv in names(x$critical)) {
    cat(sprintf("  %4s critical value %s  %s\n", lv,
                formatC(x$critical[[lv]], digits = 3, format = "f"),
                if (x$reject[[lv]]) "reject unit root" else "cannot reject"))
  }
  invisible(x)
}
