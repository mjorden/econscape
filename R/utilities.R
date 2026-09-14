#' Check that a value is a single number strictly inside (0, 1)
#' @noRd
check_unit_interval <- function(x, arg = rlang::caller_arg(x)) {
  if (!is.numeric(x) || length(x) != 1L || !is.finite(x) || x <= 0 || x >= 1) {
    cli::cli_abort("{.arg {arg}} must be a single number strictly between 0 and 1.")
  }
  x
}

#' Numerical derivative of a one-argument function
#'
#' Same conditioning rules as [mrs.default()]: a step proportional to the
#' coordinate, floored near zero, and the backward point clamped at zero.
#'
#' @param f A function of one argument.
#' @param h Relative step.
#' @param h_min Absolute floor on the step. Leave at zero for a smooth
#'   closed-form `f`; raise it when `f` is itself the output of a numerical
#'   solver, whose tolerance would otherwise swamp a tiny difference.
#' @return A function of `x`.
#' @noRd
numeric_derivative <- function(f, h = 1e-6, h_min = 0) {
  function(x) {
    h_x <- pmax(h * pmax(abs(x), 1e-8), h_min)
    x_lo <- pmax(x - h_x, 0)
    (f(x + h_x) - f(x_lo)) / (x + h_x - x_lo)
  }
}

#' Recycle two vectors to a common length
#' @noRd
recycle2 <- function(x, y) {
  n <- max(length(x), length(y))
  list(x = rep_len(x, n), y = rep_len(y, n))
}

#' Constant elasticity of substitution (CES) functions
#'
#' Builds \eqn{f(x, y) = A \left(\alpha x^{\rho} + (1 - \alpha) y^{\rho}\right)^{1/\rho}}.
#' The single parameter \eqn{\rho \le 1} sets how easily one good stands in for
#' the other, through the elasticity of substitution
#' \eqn{\sigma = 1 / (1 - \rho)}:
#'
#' * \eqn{\rho = 1} is perfect substitutes (linear contours) --
#'   [perfect_substitutes()] gives the same thing directly.
#' * \eqn{\rho \to 0} is Cobb-Douglas; use [cobb_douglas()] for that limit, as
#'   the formula is undefined at exactly zero.
#' * \eqn{\rho \to -\infty} is perfect complements -- [leontief()].
#'
#' Like [cobb_douglas()], the result is a callable function that carries its
#' parameters, so contours, demand and the MRS use closed forms.
#'
#' @param rho Substitution parameter, at most 1 and not 0.
#' @param alpha Share parameter on `x`, strictly between 0 and 1.
#' @param A Scale factor. Positive.
#' @param kind `"utility"` or `"production"`.
#'
#' @return A function of `x` and `y` of class `ces`, with `rho`, `alpha`,
#'   `A`, `sigma` and `kind` as attributes.
#'
#' @examples
#' u <- ces(rho = 0.5, alpha = 0.4)
#' u
#' optimal_bundle(u, budget(100, 2, 5))
#'
#' # Close to Cobb-Douglas when rho is small:
#' optimal_bundle(ces(rho = 1e-4, alpha = 0.3), budget(100, 2, 5))
#' optimal_bundle(cobb_douglas(0.3), budget(100, 2, 5))
#' @export
ces <- function(rho, alpha = 0.5, A = 1, kind = c("utility", "production")) {
  if (!is.numeric(rho) || length(rho) != 1L || !is.finite(rho) || rho > 1) {
    cli::cli_abort("{.arg rho} must be a single number no greater than 1.")
  }
  if (rho == 0) {
    cli::cli_abort(c(
      "{.arg rho} = 0 is the Cobb-Douglas limit, where the CES formula is undefined.",
      "i" = "Use {.fn cobb_douglas} for that case."
    ))
  }
  check_unit_interval(alpha)
  check_positive(A)
  kind <- match.arg(kind)

  f <- function(x, y) {
    A * (alpha * x^rho + (1 - alpha) * y^rho)^(1 / rho)
  }
  structure(
    f,
    class = c("ces", "function"),
    rho = rho, alpha = alpha, A = A, sigma = 1 / (1 - rho), kind = kind
  )
}

#' @export
print.ces <- function(x, ...) {
  cat(
    sprintf("<CES %s function>\n", attr(x, "kind")),
    sprintf("  f(x, y) = %s * (%s * x^%s + %s * y^%s)^(1/%s)\n",
            format(attr(x, "A")), format(attr(x, "alpha")), format(attr(x, "rho")),
            format(1 - attr(x, "alpha")), format(attr(x, "rho")), format(attr(x, "rho"))),
    sprintf("  elasticity of substitution sigma = %s\n", format(attr(x, "sigma"))),
    sep = ""
  )
  invisible(x)
}

#' @rdname indifference_curve
#' @export
indifference_curve.ces <- function(u, level, x, ...) {
  rho <- attr(u, "rho")
  alpha <- attr(u, "alpha")
  A <- attr(u, "A")
  rows <- lapply(level, function(lv) {
    inner <- ((lv / A)^rho - alpha * x^rho) / (1 - alpha)
    y <- inner^(1 / rho)
    # Outside the positive orthant, or where the level is unattainable at
    # this x (the inner term goes non-positive), there is no contour point.
    y[x < 0 | lv <= 0 | !is.finite(inner) | inner <= 0 | !is.finite(y)] <- NA_real_
    data.frame(x = x, y = y, level = lv)
  })
  do.call(rbind, rows)
}

#' @rdname optimal_bundle
#' @export
optimal_bundle.ces <- function(u, b, ...) {
  alpha <- attr(u, "alpha")
  sigma <- attr(u, "sigma")
  if (!is.finite(sigma)) {
    # rho = 1: perfect substitutes. The tangency formula degenerates
    # (k = ratio^Inf, then Inf * 0), so use the corner logic directly.
    return(optimal_bundle(as_perfect_substitutes(u), b))
  }
  # Tangency MRS = px / py gives the ratio y / x in closed form; the budget
  # then pins the level.
  k <- ((b$px * (1 - alpha)) / (b$py * alpha))^sigma
  x <- b$income / (b$px + b$py * k)
  y <- k * x
  data.frame(x = x, y = y, utility = u(x, y))
}

#' The perfect-substitutes function a CES with rho = 1 is
#' @noRd
as_perfect_substitutes <- function(u) {
  perfect_substitutes(a = attr(u, "alpha"), b = 1 - attr(u, "alpha"),
                      A = attr(u, "A"), kind = attr(u, "kind"))
}

#' @rdname mrs
#' @export
mrs.ces <- function(u, x, y, ...) {
  alpha <- attr(u, "alpha")
  rho <- attr(u, "rho")
  (alpha / (1 - alpha)) * (y / x)^(1 - rho)
}

#' Perfect complements (Leontief) functions
#'
#' Builds \eqn{f(x, y) = A \min(x / a, y / b)}: the goods are only useful in
#' the fixed proportion \eqn{a : b}, so the contours are L-shaped with the
#' kink on the ray \eqn{x / a = y / b}. The consumer always chooses the kink,
#' whatever the prices.
#'
#' The MRS is not a single number here. Below the ray (`x / a < y / b`) `x` is
#' the scarce good and the consumer would give up any amount of `y` for it, so
#' [mrs()] returns `Inf`; above the ray it returns `0`; on the ray itself the
#' curve has a corner and the MRS is undefined, returned as `NA`.
#'
#' @param a,b Units of `x` and `y` needed per unit of output. Positive.
#' @param A Scale factor. Positive.
#' @param kind `"utility"` or `"production"`.
#'
#' @return A function of `x` and `y` of class `leontief`, with `a`, `b`, `A`
#'   and `kind` as attributes.
#'
#' @examples
#' u <- leontief(a = 1, b = 2)   # one x for every two y
#' u(3, 6)
#' optimal_bundle(u, budget(100, 2, 5))
#' mrs(u, c(1, 3, 5), 6)          # Inf below the ray, NA on it, 0 above
#' @export
leontief <- function(a = 1, b = 1, A = 1, kind = c("utility", "production")) {
  check_positive(a)
  check_positive(b)
  check_positive(A)
  kind <- match.arg(kind)

  f <- function(x, y) {
    A * pmin(x / a, y / b)
  }
  structure(f, class = c("leontief", "function"), a = a, b = b, A = A, kind = kind)
}

#' @export
print.leontief <- function(x, ...) {
  cat(
    sprintf("<Leontief %s function>\n", attr(x, "kind")),
    sprintf("  f(x, y) = %s * min(x / %s, y / %s)\n",
            format(attr(x, "A")), format(attr(x, "a")), format(attr(x, "b"))),
    sprintf("  fixed proportion x : y = %s : %s\n", format(attr(x, "a")), format(attr(x, "b"))),
    sep = ""
  )
  invisible(x)
}

#' @rdname indifference_curve
#' @export
indifference_curve.leontief <- function(u, level, x, ...) {
  a <- attr(u, "a")
  b <- attr(u, "b")
  A <- attr(u, "A")
  rows <- lapply(level, function(lv) {
    x_kink <- a * lv / A
    # Left of the kink the level is unattainable at any y; from the kink
    # rightwards the smallest y that reaches it is the horizontal arm.
    y <- ifelse(x >= x_kink & lv > 0, b * lv / A, NA_real_)
    data.frame(x = x, y = y, level = lv)
  })
  do.call(rbind, rows)
}

#' @rdname optimal_bundle
#' @export
optimal_bundle.leontief <- function(u, b, ...) {
  a <- attr(u, "a")
  bb <- attr(u, "b")
  t <- b$income / (a * b$px + bb * b$py)
  x <- a * t
  y <- bb * t
  data.frame(x = x, y = y, utility = u(x, y))
}

#' @rdname mrs
#' @export
mrs.leontief <- function(u, x, y, ...) {
  v <- recycle2(x, y)
  r <- v$x / attr(u, "a") - v$y / attr(u, "b")
  tol <- 1e-10 * pmax(1, abs(v$x), abs(v$y))
  ifelse(abs(r) <= tol, NA_real_, ifelse(r < 0, Inf, 0))
}

#' Perfect substitutes (linear) functions
#'
#' Builds \eqn{f(x, y) = A (a x + b y)}: straight-line contours with constant
#' MRS \eqn{a / b}. The consumer spends everything on whichever good gives more
#' utility per unit of money, so the optimum is a corner unless
#' \eqn{a / p_x = b / p_y} exactly, when every point on the budget line is
#' equally good. In that knife-edge case [optimal_bundle()] returns the
#' midpoint of the budget line and flags the result with an `indeterminate`
#' attribute set to `TRUE`.
#'
#' @param a,b Marginal utility of `x` and `y`. Positive.
#' @param A Scale factor. Positive.
#' @param kind `"utility"` or `"production"`.
#'
#' @return A function of `x` and `y` of class `perfect_substitutes`, with `a`,
#'   `b`, `A` and `kind` as attributes.
#'
#' @examples
#' u <- perfect_substitutes(a = 1, b = 2)   # y is worth twice x
#' optimal_bundle(u, budget(100, 1, 1))     # all y
#' optimal_bundle(u, budget(100, 1, 3))     # all x
#' attr(optimal_bundle(u, budget(100, 1, 2)), "indeterminate")
#' @export
perfect_substitutes <- function(a = 1, b = 1, A = 1, kind = c("utility", "production")) {
  check_positive(a)
  check_positive(b)
  check_positive(A)
  kind <- match.arg(kind)

  f <- function(x, y) {
    A * (a * x + b * y)
  }
  structure(f, class = c("perfect_substitutes", "function"), a = a, b = b, A = A, kind = kind)
}

#' @export
print.perfect_substitutes <- function(x, ...) {
  cat(
    sprintf("<Perfect-substitutes %s function>\n", attr(x, "kind")),
    sprintf("  f(x, y) = %s * (%s * x + %s * y)\n",
            format(attr(x, "A")), format(attr(x, "a")), format(attr(x, "b"))),
    sprintf("  constant MRS = %s\n", format(attr(x, "a") / attr(x, "b"))),
    sep = ""
  )
  invisible(x)
}

#' @rdname indifference_curve
#' @export
indifference_curve.perfect_substitutes <- function(u, level, x, ...) {
  a <- attr(u, "a")
  b <- attr(u, "b")
  A <- attr(u, "A")
  rows <- lapply(level, function(lv) {
    y <- (lv / A - a * x) / b
    y[x < 0 | lv <= 0 | y < 0] <- NA_real_
    data.frame(x = x, y = y, level = lv)
  })
  do.call(rbind, rows)
}

#' @rdname optimal_bundle
#' @export
optimal_bundle.perfect_substitutes <- function(u, b, ...) {
  per_dollar_x <- attr(u, "a") / b$px
  per_dollar_y <- attr(u, "b") / b$py
  indeterminate <- isTRUE(all.equal(per_dollar_x, per_dollar_y))
  if (indeterminate) {
    x <- b$x_max / 2
    y <- b$y_max / 2
  } else if (per_dollar_x > per_dollar_y) {
    x <- b$x_max
    y <- 0
  } else {
    x <- 0
    y <- b$y_max
  }
  out <- data.frame(x = x, y = y, utility = u(x, y))
  attr(out, "indeterminate") <- indeterminate
  out
}

#' @rdname mrs
#' @export
mrs.perfect_substitutes <- function(u, x, y, ...) {
  n <- max(length(x), length(y))
  rep_len(attr(u, "a") / attr(u, "b"), n)
}

#' Quasi-linear utility
#'
#' Builds \eqn{u(x, y) = f(x) + y} for a concave `f`: utility is linear in `y`,
#' so `y` absorbs all income effects and the demand for `x` depends on prices
#' alone (as long as the consumer can afford the interior optimum). The
#' textbook case is `f = log`.
#'
#' Demand solves \eqn{f'(x) = p_x / p_y}. Pass `f_prime` if you have it;
#' otherwise it is approximated numerically and the root is found with
#' [stats::uniroot()]. Either way the corners are checked: if even the first
#' unit of `x` is not worth its price the consumer buys none, and if the last
#' affordable unit still is, the consumer buys nothing but `x`.
#'
#' @param f A concave function of one argument.
#' @param f_prime Its derivative, or `NULL` to approximate numerically.
#'
#' @return A function of `x` and `y` of class `quasilinear`, with `f`,
#'   `f_prime` and `kind = "utility"` as attributes.
#'
#' @examples
#' u <- quasilinear(log, f_prime = function(x) 1 / x)
#' optimal_bundle(u, budget(100, 2, 5))
#' optimal_bundle(u, budget(500, 2, 5))   # same x: no income effect
#' @export
quasilinear <- function(f, f_prime = NULL) {
  if (!is.function(f)) {
    cli::cli_abort("{.arg f} must be a function of one argument.")
  }
  if (!is.null(f_prime) && !is.function(f_prime)) {
    cli::cli_abort("{.arg f_prime} must be a function of one argument, or NULL.")
  }
  if (is.null(f_prime)) {
    f_prime <- numeric_derivative(f)
  }
  u <- function(x, y) {
    f(x) + y
  }
  structure(u, class = c("quasilinear", "function"), f = f, f_prime = f_prime,
            kind = "utility")
}

#' @export
print.quasilinear <- function(x, ...) {
  cat(
    "<Quasi-linear utility function>\n",
    "  u(x, y) = f(x) + y\n",
    "  linear in y: no income effect on x at an interior optimum\n",
    sep = ""
  )
  invisible(x)
}

#' @rdname indifference_curve
#' @export
indifference_curve.quasilinear <- function(u, level, x, ...) {
  f <- attr(u, "f")
  rows <- lapply(level, function(lv) {
    y <- lv - f(x)
    y[x < 0 | !is.finite(y) | y < 0] <- NA_real_
    data.frame(x = x, y = y, level = lv)
  })
  do.call(rbind, rows)
}

#' @rdname optimal_bundle
#' @export
optimal_bundle.quasilinear <- function(u, b, ...) {
  f_prime <- attr(u, "f_prime")
  target <- b$px / b$py
  x_max <- b$x_max
  g <- function(x) f_prime(x) - target

  # Corners first: the marginal utility of x is falling, so if it is already
  # below the price ratio at (almost) zero the consumer buys no x, and if it
  # is still above it at the last affordable unit the consumer buys only x.
  lo <- x_max * 1e-9
  x <- if (g(x_max) >= 0) {
    x_max
  } else if (g(lo) <= 0) {
    0
  } else {
    stats::uniroot(g, interval = c(lo, x_max), tol = 1e-10)$root
  }
  y <- (b$income - b$px * x) / b$py
  data.frame(x = x, y = y, utility = u(x, y))
}

#' @rdname mrs
#' @export
mrs.quasilinear <- function(u, x, y, ...) {
  v <- recycle2(x, y)
  attr(u, "f_prime")(v$x)
}
