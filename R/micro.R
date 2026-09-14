#' Check that a value is a single positive finite number
#' @noRd
check_positive <- function(x, arg = rlang::caller_arg(x), zero_ok = FALSE) {
  ok <- is.numeric(x) && length(x) == 1L && is.finite(x) &&
    (if (zero_ok) x >= 0 else x > 0)
  if (!ok) {
    cli::cli_abort(
      "{.arg {arg}} must be a single {if (zero_ok) 'non-negative' else 'positive'} number."
    )
  }
  x
}

#' Cobb-Douglas utility and production functions
#'
#' Builds the function \eqn{f(x, y) = A x^{\alpha} y^{\beta}} as a callable R
#' function that also remembers its parameters, so the closed-form results
#' (indifference curves, demand, marginal rate of substitution) can be read
#' straight off it rather than re-derived numerically.
#'
#' The same object serves as a utility function over two goods or a production
#' function over two inputs; the maths is identical, only the vocabulary
#' changes (indifference curve vs isoquant, budget line vs isocost). `kind`
#' records which reading is intended and drives the labels that
#' [plot_consumer_choice()] and [print()] use.
#'
#' @param alpha Exponent on `x`. Must be positive.
#' @param beta Exponent on `y`. Defaults to `1 - alpha`, which gives a
#'   homogeneous-of-degree-one function; any positive value is allowed.
#' @param A Scale factor (total factor productivity, for a production
#'   function). Must be positive.
#' @param kind `"utility"` or `"production"`.
#'
#' @return A function of two arguments `x` and `y`, of class `cobb_douglas`,
#'   carrying `alpha`, `beta`, `A` and `kind` as attributes.
#'
#' @seealso [indifference_curve()], [optimal_bundle()], [mrs()], [budget()].
#'
#' @examples
#' u <- cobb_douglas(alpha = 0.3)
#' u
#' u(x = 4, y = 9)
#'
#' f <- cobb_douglas(alpha = 0.6, beta = 0.6, A = 2, kind = "production")
#' f
#' @export
cobb_douglas <- function(alpha, beta = 1 - alpha, A = 1,
                         kind = c("utility", "production")) {
  check_positive(alpha)
  check_positive(beta)
  check_positive(A)
  kind <- match.arg(kind)

  f <- function(x, y) {
    A * x^alpha * y^beta
  }
  structure(
    f,
    class = c("cobb_douglas", "function"),
    alpha = alpha,
    beta = beta,
    A = A,
    kind = kind
  )
}

#' Pull the parameters off a cobb_douglas object
#' @noRd
cd_params <- function(u) {
  list(
    alpha = attr(u, "alpha"),
    beta = attr(u, "beta"),
    A = attr(u, "A"),
    kind = attr(u, "kind")
  )
}

#' @export
print.cobb_douglas <- function(x, ...) {
  p <- cd_params(x)
  degree <- p$alpha + p$beta
  scale <- if (isTRUE(all.equal(degree, 1))) {
    "constant"
  } else if (degree > 1) {
    "increasing"
  } else {
    "decreasing"
  }
  cat(
    sprintf("<Cobb-Douglas %s function>\n", p$kind),
    sprintf("  f(x, y) = %s * x^%s * y^%s\n",
            format(p$A), format(p$alpha), format(p$beta)),
    sprintf("  %s returns to scale (degree %s)\n", scale, format(degree)),
    sep = ""
  )
  invisible(x)
}

#' A budget constraint
#'
#' Describes the set of bundles affordable at income `income` when the two
#' goods cost `px` and `py`: every \eqn{(x, y)} with
#' \eqn{p_x x + p_y y \le I}. For a producer the same object is an isocost
#' line, with `income` read as total outlay and the prices as input prices.
#'
#' @param income Income, or total outlay. Positive.
#' @param px,py Prices of `x` and `y`. Positive.
#'
#' @return A list of class `budget` with the inputs plus the derived
#'   `x_max` (`income / px`), `y_max` (`income / py`) and `slope` (`-px / py`).
#'
#' @seealso [budget_line()] to get plottable coordinates, [optimal_bundle()]
#'   to solve against a utility function.
#'
#' @examples
#' b <- budget(income = 100, px = 2, py = 5)
#' b
#' b$x_max
#' @export
budget <- function(income, px, py) {
  check_positive(income)
  check_positive(px)
  check_positive(py)
  structure(
    list(
      income = income,
      px = px,
      py = py,
      x_max = income / px,
      y_max = income / py,
      slope = -px / py
    ),
    class = "budget"
  )
}

#' @export
print.budget <- function(x, ...) {
  cat(
    "<Budget constraint>\n",
    sprintf("  %s * x + %s * y <= %s\n",
            format(x$px), format(x$py), format(x$income)),
    sprintf("  intercepts: x = %s, y = %s; slope %s\n",
            format(x$x_max), format(x$y_max), format(x$slope)),
    sep = ""
  )
  invisible(x)
}

#' Coordinates of a budget line
#'
#' @param b A [budget()].
#' @param n_points Number of points. Two is enough for a straight line; more
#'   is useful if you want to attach a colour or size aesthetic along it.
#'
#' @return A data frame with `x` and `y` columns running from the `y`
#'   intercept to the `x` intercept.
#'
#' @examples
#' budget_line(budget(100, 2, 5))
#' @export
budget_line <- function(b, n_points = 2L) {
  if (!inherits(b, "budget")) {
    cli::cli_abort("{.arg b} must be a {.fn budget} object.")
  }
  n_points <- as.integer(n_points)
  if (is.na(n_points) || n_points < 2L) {
    cli::cli_abort("{.arg n_points} must be at least 2.")
  }
  x <- seq(0, b$x_max, length.out = n_points)
  data.frame(x = x, y = (b$income - b$px * x) / b$py)
}

#' Indifference curves and isoquants
#'
#' For each `level`, finds the `y` that gives \eqn{u(x, y) = } `level` at
#' every `x`, i.e. the contour of the function. Functions built by
#' [cobb_douglas()], [ces()], [leontief()], [perfect_substitutes()] and
#' [quasilinear()] use their closed forms (for Cobb-Douglas,
#' \eqn{y = (U / (A x^{\alpha}))^{1/\beta}}); any other
#' function of two arguments is solved numerically by bisection, which
#' requires it to be non-decreasing in `y` ("more is better"). Where a
#' contour is flat in `y` -- perfect complements, for instance -- the
#' smallest `y` that attains the level is returned, which is the point on
#' the L-shaped curve rather than somewhere along its vertical arm.
#'
#' @param u A function of `x` and `y`, typically from [cobb_douglas()].
#' @param level One or more utility (or output) levels.
#' @param x Numeric vector of `x` values at which to evaluate the curve.
#' @param ... Passed on to methods.
#' @param y_range Search interval for the numeric solver. Defaults to a wide
#'   positive range; narrow it if the function is only well-behaved on part of
#'   the plane.
#'
#' @return A data frame with columns `x`, `y` and `level`, one row per `x`
#'   per level, stacked in `level` order. `y` is `NA` where no solution
#'   exists: for the numeric method, where the level is unreachable within
#'   `y_range`; for Cobb-Douglas, at `x <= 0` or `level <= 0`, where the
#'   closed form is undefined. The two methods agree wherever a level is
#'   unattainable and at `x = 0` for any positive level, so a caller can
#'   filter on `is.na(y)` without knowing which one ran. (At `level = 0`
#'   exactly, a Cobb-Douglas contour is the pair of axes; the closed form
#'   reports `NA` rather than pretend that is a curve.)
#'
#' @examples
#' u <- cobb_douglas(alpha = 0.5)
#' indifference_curve(u, level = c(2, 4), x = c(1, 2, 4, 8))
#'
#' # A perfect-complements (Leontief) utility, solved numerically
#' leontief <- function(x, y) pmin(x, y)
#' indifference_curve(leontief, level = 3, x = c(3, 4, 5))
#' @export
indifference_curve <- function(u, level, x, ...) {
  if (!is.function(u)) {
    cli::cli_abort("{.arg u} must be a function of {.arg x} and {.arg y}.")
  }
  if (!is.numeric(level) || length(level) == 0L || any(!is.finite(level))) {
    cli::cli_abort("{.arg level} must be a numeric vector of finite values.")
  }
  if (!is.numeric(x) || length(x) == 0L) {
    cli::cli_abort("{.arg x} must be a numeric vector.")
  }
  UseMethod("indifference_curve")
}

#' @rdname indifference_curve
#' @export
indifference_curve.cobb_douglas <- function(u, level, x, ...) {
  p <- cd_params(u)
  rows <- lapply(level, function(lv) {
    y <- (lv / (p$A * x^p$alpha))^(1 / p$beta)
    # The closed form only means anything on the positive orthant: at x = 0 it
    # divides by zero (Inf) and at level <= 0 it takes a fractional power of a
    # non-positive base (0 or NaN). Both are "no solution", which the generic
    # documents as NA -- and which the numeric method already returns.
    y[x <= 0 | lv <= 0] <- NA_real_
    data.frame(x = x, y = y, level = lv)
  })
  do.call(rbind, rows)
}

#' @rdname indifference_curve
#' @export
indifference_curve.default <- function(u, level, x, ..., y_range = c(1e-9, 1e9)) {
  if (!is.numeric(y_range) || length(y_range) != 2L || y_range[1] >= y_range[2]) {
    cli::cli_abort("{.arg y_range} must be an increasing pair of numbers.")
  }
  # Bisection on the predicate u(x, y) >= level rather than uniroot() on
  # u(x, y) - level: uniroot() is free to return any root, and on a flat
  # contour segment it returns the upper bound of the search interval.
  solve_y <- function(xi, lv) {
    reaches <- function(y) u(xi, y) - lv >= 0
    lo <- y_range[1]
    hi <- y_range[2]
    at_lo <- u(xi, lo) - lv
    at_hi <- u(xi, hi) - lv
    if (!is.finite(at_lo) || !is.finite(at_hi) || at_lo > 0 || at_hi < 0) {
      return(NA_real_)
    }
    if (at_lo == 0) {
      return(lo)
    }
    for (i in seq_len(200L)) {
      mid <- (lo + hi) / 2
      if (reaches(mid)) hi <- mid else lo <- mid
      if (hi - lo <= 1e-10 * max(1, abs(hi))) break
    }
    hi
  }
  rows <- lapply(level, function(lv) {
    data.frame(
      x = x,
      y = vapply(x, solve_y, numeric(1), lv = lv),
      level = lv
    )
  })
  do.call(rbind, rows)
}

#' The bundle a consumer (or producer) chooses
#'
#' Maximises `u` subject to the budget constraint `b`. A Cobb-Douglas
#' consumer spends the fixed share \eqn{\alpha / (\alpha + \beta)} of income
#' on `x`, which gives the closed form
#' \eqn{x^* = \frac{\alpha}{\alpha + \beta} \frac{I}{p_x}}. Any other
#' function is maximised numerically along the budget line with
#' [stats::optimize()], which finds the global optimum only if `u` is
#' quasi-concave -- true for the usual textbook cases.
#'
#' @param u A function of `x` and `y`.
#' @param b A [budget()].
#' @param ... Passed on to methods.
#'
#' @return A one-row data frame with `x`, `y` and `utility` (the value of `u`
#'   at the optimum).
#'
#' @examples
#' u <- cobb_douglas(alpha = 0.3)
#' b <- budget(income = 100, px = 2, py = 5)
#' optimal_bundle(u, b)
#'
#' # Spends 30% of income on x regardless of prices:
#' optimal_bundle(u, budget(100, 4, 5))$x * 4
#' @export
optimal_bundle <- function(u, b, ...) {
  if (!is.function(u)) {
    cli::cli_abort("{.arg u} must be a function of {.arg x} and {.arg y}.")
  }
  if (!inherits(b, "budget")) {
    cli::cli_abort("{.arg b} must be a {.fn budget} object.")
  }
  UseMethod("optimal_bundle")
}

#' @rdname optimal_bundle
#' @export
optimal_bundle.cobb_douglas <- function(u, b, ...) {
  p <- cd_params(u)
  share_x <- p$alpha / (p$alpha + p$beta)
  x <- share_x * b$income / b$px
  y <- (1 - share_x) * b$income / b$py
  data.frame(x = x, y = y, utility = u(x, y))
}

#' @rdname optimal_bundle
#' @export
optimal_bundle.default <- function(u, b, ...) {
  along <- function(x) u(x, (b$income - b$px * x) / b$py)
  opt <- stats::optimize(along, interval = c(0, b$x_max), maximum = TRUE,
                         tol = 1e-10)
  # optimize() cannot land exactly on an endpoint; check both in case the
  # optimum is a corner solution.
  candidates <- data.frame(
    x = c(opt$maximum, 0, b$x_max),
    utility = c(opt$objective, along(0), along(b$x_max))
  )
  best <- candidates[which.max(candidates$utility), ]
  x <- best$x
  y <- (b$income - b$px * x) / b$py
  data.frame(x = x, y = y, utility = best$utility)
}

#' Marginal rate of substitution
#'
#' The slope of the indifference curve at `(x, y)`, expressed as a positive
#' number: how much `y` the consumer would give up for one more unit of `x`.
#' For Cobb-Douglas this is \eqn{\frac{\alpha}{\beta} \frac{y}{x}}; other
#' functions use a central finite difference on each partial derivative. The
#' step is scaled to the coordinate (`h * |x|`, floored at `h * 1e-8`) so the
#' estimate stays well-conditioned from near-axis points to quantities in the
#' millions, and the backward point is never taken below zero -- at a point
#' within a step of an axis the difference becomes one-sided rather than
#' evaluating `u` on a negative quantity, where most utilities return `NaN`.
#'
#' At the optimal bundle the MRS equals the price ratio `px / py` -- the
#' tangency condition -- which is a handy check on [optimal_bundle()].
#'
#' @param u A function of `x` and `y`.
#' @param x,y Coordinates, recycled against each other.
#' @param ... Passed on to methods.
#' @param h Relative step for the finite difference (default method only).
#'
#' @return A numeric vector.
#'
#' @examples
#' u <- cobb_douglas(alpha = 0.3)
#' b <- budget(100, 2, 5)
#' opt <- optimal_bundle(u, b)
#' mrs(u, opt$x, opt$y)   # equals px / py = 0.4
#' @export
mrs <- function(u, x, y, ...) {
  if (!is.function(u)) {
    cli::cli_abort("{.arg u} must be a function of {.arg x} and {.arg y}.")
  }
  UseMethod("mrs")
}

#' @rdname mrs
#' @export
mrs.cobb_douglas <- function(u, x, y, ...) {
  p <- cd_params(u)
  (p$alpha / p$beta) * (y / x)
}

#' @rdname mrs
#' @export
mrs.default <- function(u, x, y, ..., h = 1e-6) {
  check_positive(h)
  # A step proportional to the coordinate keeps the difference well-conditioned
  # at every scale: an absolute 1e-6 is a 100x overshoot at x = 1e-8 (and
  # pushes the backward point negative, where textbook utilities are NaN) and
  # is lost to rounding at x = 1e6. The floor only matters at exactly zero.
  h_x <- h * pmax(abs(x), 1e-8)
  h_y <- h * pmax(abs(y), 1e-8)
  # Quantities are non-negative, so never evaluate u() below zero; the
  # difference is taken over the actual spacing, which turns a clamped point
  # into a one-sided estimate rather than a wrong one.
  x_lo <- pmax(x - h_x, 0)
  y_lo <- pmax(y - h_y, 0)
  mu_x <- (u(x + h_x, y) - u(x_lo, y)) / (x + h_x - x_lo)
  mu_y <- (u(x, y + h_y) - u(x, y_lo)) / (y + h_y - y_lo)
  mu_x / mu_y
}
