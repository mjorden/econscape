econ <- ggplot2::economics
econ$unemp_rate <- 100 * econ$unemploy / econ$pop

## ols() ---------------------------------------------------------------------

test_that("ols() with classical errors reproduces lm()", {
  fit <- ols(psavert ~ unemp_rate + uempmed, econ)
  ref <- stats::lm(psavert ~ unemp_rate + uempmed, econ)
  expect_s3_class(fit, "econ_fit")
  expect_equal(coef(fit), coef(ref))
  expect_equal(vcov(fit), vcov(ref))
  tab <- coef_table(fit)
  s <- summary(ref)$coefficients
  expect_equal(tab$std_error, unname(s[, "Std. Error"]))
  expect_equal(tab$statistic, unname(s[, "t value"]))
  expect_equal(tab$p_value, unname(s[, "Pr(>|t|)"]))
  ci <- stats::confint(ref)
  expect_equal(tab$conf_low, unname(ci[, 1]))
  expect_equal(tab$conf_high, unname(ci[, 2]))
  expect_identical(nobs(fit), nrow(econ))
  expect_equal(residuals(fit), residuals(ref))
  expect_equal(fitted(fit), fitted(ref))
})

test_that("HC1 matches the sandwich computed by hand", {
  fit <- ols(psavert ~ unemp_rate, econ, se = "hc1")
  X <- stats::model.matrix(fit$fit)
  e <- stats::residuals(fit$fit)
  n <- nrow(X); k <- ncol(X)
  bread <- solve(t(X) %*% X)
  meat <- matrix(0, k, k)
  for (i in seq_len(n)) meat <- meat + e[i]^2 * (X[i, ] %*% t(X[i, ]))
  expect_equal(unname(fit$vcov), unname(n / (n - k) * bread %*% meat %*% bread))
  # Robust and classical differ, as they should on real data.
  expect_false(isTRUE(all.equal(fit$vcov, ols(psavert ~ unemp_rate, econ)$vcov)))
})

test_that("Newey-West HAC matches the Bartlett-weighted sum computed by hand", {
  fit <- ols(psavert ~ unemp_rate, econ, se = "hac", lags = 3)
  expect_identical(fit$lags, 3L)
  X <- stats::model.matrix(fit$fit)
  e <- stats::residuals(fit$fit)
  n <- nrow(X); k <- ncol(X)
  u <- X * e
  S <- matrix(0, k, k)
  for (t in seq_len(n)) S <- S + u[t, ] %*% t(u[t, ])
  for (l in 1:3) {
    w <- 1 - l / 4
    G <- matrix(0, k, k)
    for (t in (l + 1):n) G <- G + u[t, ] %*% t(u[t - l, ])
    S <- S + w * (G + t(G))
  }
  bread <- solve(t(X) %*% X)
  expect_equal(unname(fit$vcov), unname(bread %*% S %*% bread))
})

test_that("HAC with zero lags is HC0, and the default bandwidth follows the rule of thumb", {
  hac0 <- ols(psavert ~ unemp_rate, econ, se = "hac", lags = 0)
  hc1 <- ols(psavert ~ unemp_rate, econ, se = "hc1")
  n <- nrow(econ); k <- 2
  expect_equal(hac0$vcov, hc1$vcov * (n - k) / n)
  auto <- ols(psavert ~ unemp_rate, econ, se = "hac")
  expect_identical(auto$lags, as.integer(floor(4 * (n / 100)^(2 / 9))))
  expect_null(hc1$lags)
})

test_that("serial correlation makes HAC errors larger here, as expected", {
  cl <- coef_table(ols(psavert ~ unemp_rate, econ))
  hac <- coef_table(ols(psavert ~ unemp_rate, econ, se = "hac"))
  expect_true(hac$std_error[2] > cl$std_error[2])
  expect_equal(hac$estimate, cl$estimate)
})

test_that("ols() validates and prints", {
  expect_error(ols(psavert ~ unemp_rate, "econ"), "data frame")
  expect_error(ols(y ~ x, data.frame(y = 1:2, x = 3:4)), "more observations")
  expect_error(ols(psavert ~ unemp_rate, econ, se = "hac", lags = -1), "non-negative")
  expect_error(coef_table(lm(psavert ~ 1, econ)), "econ_fit")
  expect_error(coef_table(ols(psavert ~ 1, econ), level = 1.5), "between 0 and 1")
  expect_output(print(ols(psavert ~ unemp_rate, econ, se = "hac")), "Newey-West HAC")
  expect_output(summary(ols(psavert ~ unemp_rate, econ, se = "hc1")), "HC1")
  expect_output(print(ols(psavert ~ unemp_rate, econ)), "R-squared")
})

## hp_filter() ---------------------------------------------------------------

test_that("the HP trend reproduces a linear series exactly and its cycle averages zero", {
  y <- 3 + 0.5 * seq_len(60)
  hp <- hp_filter(y, lambda = 1600)
  expect_s3_class(hp, "trend_cycle")
  expect_equal(hp$trend, y)
  expect_equal(hp$cycle, rep(0, 60))
  set.seed(7)
  noisy <- y + rnorm(60)
  hp2 <- hp_filter(noisy, lambda = 1600)
  expect_equal(sum(hp2$cycle), 0, tolerance = 1e-8)
  # Smoother than the data: the trend's second differences are tiny.
  expect_true(sum(diff(hp2$trend, differences = 2)^2) < sum(diff(noisy, differences = 2)^2) / 100)
})

test_that("the HP filter satisfies its own first-order conditions", {
  set.seed(3)
  y <- cumsum(rnorm(80))
  lambda <- 100
  hp <- hp_filter(y, lambda = lambda)
  n <- length(y)
  K <- matrix(0, n - 2, n)
  for (i in seq_len(n - 2)) K[i, i:(i + 2)] <- c(1, -2, 1)
  lhs <- (diag(n) + lambda * t(K) %*% K) %*% hp$trend
  expect_equal(as.numeric(lhs), y)
})

test_that("lambda follows the frequency convention and can be overridden", {
  y <- cumsum(rnorm(40))
  expect_equal(attr(hp_filter(y), "lambda"), 1600)
  expect_equal(attr(hp_filter(y, frequency = "annual"), "lambda"), 100)
  expect_equal(attr(hp_filter(y, frequency = "monthly"), "lambda"), 14400)
  expect_equal(attr(hp_filter(y, lambda = 6.25), "lambda"), 6.25)
  # Larger lambda: smoother trend, bigger cycle.
  expect_true(var(hp_filter(y, lambda = 1e5)$cycle) > var(hp_filter(y, lambda = 10)$cycle))
})

test_that("filters accept a fred_series-shaped frame and keep the dates", {
  u <- data.frame(series_id = "U", date = econ$date, value = econ$unemp_rate)
  hp <- hp_filter(u, frequency = "monthly")
  expect_named(hp, c("date", "value", "trend", "cycle"))
  expect_identical(hp$date, econ$date)
  expect_output(print(hp), "Hodrick-Prescott")
  two <- rbind(u, transform(u, series_id = "V"))
  expect_error(hp_filter(two), "one at a time")
  expect_error(hp_filter(data.frame(x = 1)), "value")
  expect_error(hp_filter(c(1, NA, 3, 4)), "missing")
  expect_error(hp_filter(1:3), "at least 4")
  expect_error(hp_filter("a"), "numeric")
})

## hamilton_filter() ---------------------------------------------------------

test_that("the Hamilton filter is the h-step-ahead regression residual", {
  set.seed(11)
  y <- cumsum(rnorm(120))
  hm <- hamilton_filter(y, h = 8, p = 4)
  expect_identical(attr(hm, "method"), "hamilton")
  expect_true(all(is.na(hm$cycle[1:11])))
  expect_false(anyNA(hm$cycle[12:120]))
  # Rebuild the regression by hand.
  t_idx <- 12:120
  X <- cbind(1, y[t_idx - 8], y[t_idx - 9], y[t_idx - 10], y[t_idx - 11])
  ref <- stats::lm.fit(X, y[t_idx])
  expect_equal(hm$cycle[t_idx], unname(ref$residuals))
  expect_equal(hm$trend[t_idx] + hm$cycle[t_idx], y[t_idx])
  expect_equal(mean(hm$cycle, na.rm = TRUE), 0, tolerance = 1e-10)   # regression has a constant
  expect_output(print(hm), "Hamilton, h = 8, p = 4")
})

test_that("the Hamilton filter needs enough data and validates h, p", {
  expect_error(hamilton_filter(rnorm(10), h = 8, p = 4), "more than")
  expect_error(hamilton_filter(rnorm(50), h = 0), "positive")
  # n = 14 passed the old guard and returned an all-zero cycle from a
  # rank-deficient regression (5 parameters on 3 rows).
  expect_error(hamilton_filter(cumsum(rnorm(14)), h = 8, p = 4), "more than 18")
  ok <- hamilton_filter(cumsum(rnorm(19)), h = 8, p = 4)
  expect_true(any(abs(ok$cycle) > 0, na.rm = TRUE))
})

## adf_test() ----------------------------------------------------------------

test_that("adf_test() rejects for a stationary AR(1) and not for a random walk", {
  set.seed(2024)
  stationary <- as.numeric(stats::arima.sim(list(ar = 0.5), 300))
  walk <- cumsum(rnorm(300))
  a <- adf_test(stationary)
  w <- adf_test(walk)
  expect_s3_class(a, "adf_test")
  expect_true(a$reject[["5%"]])
  expect_true(a$statistic < a$critical[["1%"]])
  expect_false(w$reject[["5%"]])
  expect_true(w$statistic > w$critical[["10%"]])
  expect_output(print(a), "reject unit root")
  expect_output(print(w), "cannot reject")
})

test_that("the ADF statistic is the t ratio on the lagged level", {
  set.seed(5)
  y <- cumsum(rnorm(150))
  a <- adf_test(y, lags = 2, type = "drift")
  expect_identical(a$lags, 2L)
  dy <- diff(y)
  t_idx <- 4:150
  df <- data.frame(dy = dy[t_idx - 1], y_lag = y[t_idx - 1],
                   dy1 = dy[t_idx - 2], dy2 = dy[t_idx - 3])
  ref <- summary(stats::lm(dy ~ y_lag + dy1 + dy2, df))$coefficients
  expect_equal(a$statistic, unname(ref["y_lag", "t value"]))
  expect_equal(a$gamma, unname(ref["y_lag", "Estimate"]))
  expect_identical(a$nobs, length(t_idx))
})

test_that("critical values follow the MacKinnon response surfaces", {
  set.seed(8)
  y <- cumsum(rnorm(120))
  a <- adf_test(y, lags = 0, type = "trend")
  m <- a$nobs
  expect_equal(unname(a$critical[["5%"]]), -3.4126 - 4.039 / m - 17.83 / m^2)
  d <- adf_test(y, lags = 0, type = "drift")
  expect_equal(unname(d$critical[["1%"]]), -3.4336 - 5.999 / m - 29.25 / m^2)
  n0 <- adf_test(y, lags = 0, type = "none")
  expect_equal(unname(n0$critical[["10%"]]), -1.6156 - 0.181 / m)
  # Trend critical values are the most negative, none the least.
  expect_true(a$critical[["5%"]] < d$critical[["5%"]])
  expect_true(d$critical[["5%"]] < n0$critical[["5%"]])
})

test_that("adf_test() picks lags by AIC over a common sample and validates", {
  set.seed(9)
  y <- cumsum(rnorm(200))
  a <- adf_test(y)
  expect_true(a$lags >= 0 && a$lags <= floor(12 * (200 / 100)^0.25))
  expect_error(adf_test(rnorm(10)), "at least 20")
  expect_error(adf_test(y, lags = -1), "non-negative")
  expect_error(adf_test(y, type = "quadratic"))
})

## transform_series() --------------------------------------------------------

test_that("transform_series() matches the FRED definitions", {
  df <- data.frame(series_id = "X",
                   date = seq(as.Date("2020-01-01"), by = "quarter", length.out = 8),
                   value = c(100, 102, 105, 103, 110, 112, 115, 120))
  v <- df$value
  expect_equal(transform_series(df, "lin")$value, v)
  expect_equal(transform_series(df, "chg")$value, c(NA, diff(v)))
  expect_equal(transform_series(df, "ch1")$value, c(rep(NA, 4), v[5:8] - v[1:4]))
  expect_equal(transform_series(df, "pch")$value, c(NA, 100 * (v[-1] / v[-8] - 1)))
  expect_equal(transform_series(df, "pc1")$value, c(rep(NA, 4), 100 * (v[5:8] / v[1:4] - 1)))
  expect_equal(transform_series(df, "pca")$value, c(NA, 100 * ((v[-1] / v[-8])^4 - 1)))
  expect_equal(transform_series(df, "cch")$value, c(NA, 100 * diff(log(v))))
  expect_equal(transform_series(df, "cca")$value, c(NA, 400 * diff(log(v))))
  expect_equal(transform_series(df, "log")$value, log(v))
  expect_equal(transform_series(df, "index")$value, 100 * v / 100)
  expect_identical(nrow(transform_series(df, "pc1")), 8L)
})

test_that("transform_series() infers the frequency or takes it, and works per series", {
  monthly <- data.frame(date = econ$date, value = econ$pce)
  expect_equal(infer_frequency(monthly$date), 12L)
  expect_equal(infer_frequency(seq(as.Date("2000-01-01"), by = "year", length.out = 5)), 1L)
  expect_equal(infer_frequency(seq(as.Date("2000-01-01"), by = "week", length.out = 5)), 52L)
  yoy <- transform_series(monthly, "pc1")
  expect_true(all(is.na(yoy$value[1:12])))
  expect_equal(yoy$value[13], 100 * (econ$pce[13] / econ$pce[1] - 1))
  forced <- transform_series(monthly, "pc1", frequency = 4)
  expect_equal(forced$value[5], 100 * (econ$pce[5] / econ$pce[1] - 1))

  two <- rbind(data.frame(series_id = "A", date = monthly$date[1:5], value = 1:5),
               data.frame(series_id = "B", date = monthly$date[1:5], value = c(2, 4, 8, 16, 32)))
  out <- transform_series(two, "pch", frequency = 12)
  expect_equal(out$value[out$series_id == "B"], c(NA, 100, 100, 100, 100))
  expect_equal(out$value[out$series_id == "A"][2], 100)

  expect_error(transform_series(data.frame(x = 1), "log"), "date")
  expect_error(transform_series(monthly, "pc1", frequency = 7), "observations per year")
  expect_error(transform_series(monthly, "sqrt"))
})

## plots ---------------------------------------------------------------------

test_that("plot_coefficients() builds, drops the intercept, and colours by significance", {
  fit <- ols(psavert ~ unemp_rate + uempmed, econ, se = "hac")
  p <- plot_coefficients(fit)
  built <- ggplot2::ggplot_build(p)
  expect_s3_class(built, "ggplot_built")
  expect_identical(nrow(built$data[[3]]), 2L)          # two points, no intercept
  expect_identical(nrow(ggplot2::ggplot_build(plot_coefficients(fit, intercept = TRUE))$data[[3]]), 3L)
  one <- plot_coefficients(fit, terms = "uempmed")
  expect_identical(nrow(ggplot2::ggplot_build(one)$data[[3]]), 1L)
  expect_match(p$labels$subtitle, "Newey-West")
  expect_error(plot_coefficients(fit, terms = "nope"), "Unknown term")
  expect_error(plot_coefficients(fit, terms = "(Intercept)"), "excluded by")
  expect_identical(nrow(ggplot2::ggplot_build(plot_coefficients(fit, terms = "(Intercept)", intercept = TRUE))$data[[3]]), 1L)
  expect_error(plot_coefficients(ols(psavert ~ 1, econ)), "Nothing to plot")
})

test_that("plot_trend_cycle() builds with and without dates", {
  u <- data.frame(date = econ$date, value = econ$unemp_rate)
  p <- plot_trend_cycle(hp_filter(u, frequency = "monthly"))
  expect_s3_class(ggplot2::ggplot_build(p), "ggplot_built")
  expect_match(p$labels$subtitle, "Hodrick-Prescott")
  expect_match(p$labels$caption, "NBER")
  q <- plot_trend_cycle(hamilton_filter(econ$unemp_rate, h = 24, p = 12), recessions = TRUE)
  expect_s3_class(ggplot2::ggplot_build(q), "ggplot_built")
  expect_null(q$labels$caption)
  expect_error(plot_trend_cycle(data.frame(a = 1)), "hp_filter")
})


## Review follow-ups (2026-09-14) ----------------------------------------------

test_that("ols() accepts weights and computes weighted sandwiches", {
  set.seed(4)
  d <- data.frame(x = rnorm(80), w = runif(80, 0.5, 2))
  d$y <- 1 + 2 * d$x + rnorm(80) / sqrt(d$w)
  fit <- ols(y ~ x, d, weights = w)
  ref <- stats::lm(y ~ x, d, weights = w)
  expect_equal(coef(fit), coef(ref))
  expect_equal(vcov(fit), vcov(ref))                       # classical = lm's own
  expect_equal(coef_table(fit)$std_error, unname(summary(ref)$coefficients[, 2]))
  expect_output(print(fit), "weighted OLS")
  # HC1 by hand with weights: bread (X'WX)^-1, meat sum (w e)^2 x x'
  hc <- ols(y ~ x, d, weights = w, se = "hc1")
  X <- model.matrix(ref); e <- residuals(ref); w <- d$w; n <- nrow(X); k <- ncol(X)
  bread <- solve(t(X) %*% diag(w) %*% X)
  meat <- matrix(0, k, k)
  for (i in seq_len(n)) meat <- meat + (w[i] * e[i])^2 * (X[i, ] %*% t(X[i, ]))
  expect_equal(unname(hc$vcov), unname(n / (n - k) * bread %*% meat %*% bread))
  # subset still works through the constructed call
  sub <- ols(y ~ x, d, subset = x > 0)
  expect_identical(nobs(sub), sum(d$x > 0))
  # and so does calling from inside a function with a local data frame
  f <- function() { dd <- d; ols(y ~ x, dd, weights = w, se = "hac") }
  expect_equal(coef(f()), coef(ref))
})

test_that("econ_fit supports confint(), predict(), model.matrix() and formula()", {
  fit <- ols(psavert ~ unemp_rate + uempmed, econ, se = "hac")
  ci <- confint(fit)
  tab <- coef_table(fit)
  expect_equal(unname(ci[, 1]), tab$conf_low)
  expect_equal(unname(ci[, 2]), tab$conf_high)
  expect_identical(rownames(ci), tab$term)
  expect_equal(unname(confint(fit, "uempmed", level = 0.9)[1, ]),
               unlist(coef_table(fit, 0.9)[3, c("conf_low", "conf_high")], use.names = FALSE))
  nd <- data.frame(unemp_rate = c(3, 5), uempmed = c(8, 12))
  expect_equal(predict(fit, nd), predict(fit$fit, nd))
  expect_equal(dim(model.matrix(fit)), c(nrow(econ), 3L))
  expect_identical(formula(fit), psavert ~ unemp_rate + uempmed)
})

test_that("adf_test() refuses a regression with no residual degrees of freedom", {
  set.seed(6)
  y <- cumsum(rnorm(20))
  expect_error(adf_test(y, lags = 8, type = "trend"), "Too few observations")
  # The automatic search skips the saturated candidates and still answers.
  a <- adf_test(y, type = "trend")
  expect_true(is.finite(a$statistic))
  expect_true(a$lags <= 5)
  expect_true(all(!is.na(a$reject)))
})

test_that("the banded HP solve equals the dense solve", {
  set.seed(12)
  y <- cumsum(rnorm(60))
  lambda <- 1600
  n <- length(y)
  K <- matrix(0, n - 2, n)
  for (i in seq_len(n - 2)) K[i, i:(i + 2)] <- c(1, -2, 1)
  dense <- as.numeric(solve(diag(n) + lambda * crossprod(K), y))
  expect_equal(hp_filter(y, lambda = lambda)$trend, dense, tolerance = 1e-10)
  expect_equal(hp_filter(y, lambda = 6.25)$trend,
               as.numeric(solve(diag(n) + 6.25 * crossprod(K), y)), tolerance = 1e-10)
  # Long series are now feasible at all (this used to take minutes).
  long <- hp_filter(cumsum(rnorm(20000)), lambda = 14400)
  expect_identical(nrow(long), 20000L)
  expect_equal(sum(long$cycle), 0, tolerance = 1e-6)
})

test_that("fred_recessions() collapses the USREC indicator into intervals", {
  months <- seq(as.Date("2007-01-01"), by = "month", length.out = 36)
  flag <- as.numeric(months >= as.Date("2007-12-01") & months <= as.Date("2009-06-01"))
  testthat::local_mocked_bindings(
    fred_series = function(series_id, ..., key) data.frame(series_id = series_id, date = months, value = flag)
  )
  out <- fred_recessions(key = strrep("a", 32))
  expect_identical(nrow(out), 1L)
  expect_identical(out$peak, as.Date("2007-12-01"))
  expect_identical(out$trough, as.Date("2009-06-01"))
})


test_that("transform_series() keeps the caller's row order", {
  dates <- seq(as.Date("2020-01-01"), by = "month", length.out = 4)
  # Interleaved series, dates out of order.
  df <- data.frame(series_id = rep(c("A", "B"), 4), date = rep(dates[c(3, 1, 2, 4)], each = 2),
                   value = c(30, 300, 10, 100, 20, 200, 40, 400))
  out <- transform_series(df, "chg", frequency = 12)
  expect_identical(out$series_id, df$series_id)
  expect_identical(out$date, df$date)
  expect_equal(out$value, c(10, 100, NA, NA, 10, 100, 10, 100))
  expect_identical(nrow(out), 8L)
  # No series_id column at all
  one <- transform_series(data.frame(date = dates[c(2, 1, 3, 4)], value = c(2, 1, 4, 8)), "pch", frequency = 12)
  expect_equal(one$value, c(100, NA, 100, 100))
})

test_that("a trend_cycle survives row subsetting and degrades honestly", {
  hp <- hp_filter(cumsum(rnorm(50)), lambda = 100)
  rows <- hp[1:10, ]
  expect_s3_class(rows, "trend_cycle")
  expect_equal(attr(rows, "lambda"), 100)
  expect_output(print(rows), "10 observations")
  cols <- hp[, c("value", "trend")]
  expect_false(inherits(cols, "trend_cycle"))
  expect_s3_class(cols, "data.frame")
  broken <- structure(data.frame(value = 1:3), class = c("trend_cycle", "data.frame"))
  expect_error(print(broken), "not a complete")
  expect_error(plot_trend_cycle(broken), "not a complete")
  expect_s3_class(ggplot2::ggplot_build(plot_trend_cycle(rows)), "ggplot_built")
})
