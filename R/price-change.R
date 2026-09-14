#' The expenditure function
#'
#' The least income needed to reach a given utility (or, for a production
#' function, the least outlay needed to produce a given output) at the stated
#' prices. This is the object behind Hicksian compensation and behind the
#' total-cost curve, so every constructor has a dedicated method: closed
#' forms for Cobb-Douglas, CES, Leontief and perfect substitutes, and for
#' quasi-linear utility a single root-find for the first-order condition
#' followed by the closed form. Any other function is solved by finding the
#' income at which [optimal_bundle()] just reaches `level`, using
#' [stats::uniroot()].
#'
#' @param u A function of `x` and `y`.
#' @param px,py Prices.
#' @param level Target utility or output. May be a vector.
#' @param ... Passed on to methods.
#'
#' @return A numeric vector the length of `level`.
#'
#' @examples
#' u <- cobb_douglas(alpha = 0.3)
#' b <- budget(100, 2, 5)
#' u0 <- optimal_bundle(u, b)$utility
#' expenditure(u, 2, 5, u0)   # recovers the income: 100
#'
#' # What the same utility costs after px doubles
#' expenditure(u, 4, 5, u0)
#' @export
expenditure <- function(u, px, py, level, ...) {
  if (!is.function(u)) {
    cli::cli_abort("{.arg u} must be a function of {.arg x} and {.arg y}.")
  }
  px <- as_price(px)
  py <- as_price(py)
  if (!is.numeric(level) || length(level) == 0L || any(!is.finite(level))) {
    cli::cli_abort("{.arg level} must be a numeric vector of finite values.")
  }
  # No closed form survives a price schedule: search over income, which
  # optimal_bundle() already handles for a kinked budget.
  if (inherits(px, "price_schedule") || inherits(py, "price_schedule")) {
    return(expenditure_numeric(u, px, py, level))
  }
  UseMethod("expenditure")
}

#' Least income reaching each level, by search over income
#' @noRd
expenditure_numeric <- function(u, px, py, level) {
  vapply(level, function(lv) {
    g <- function(income) optimal_bundle(u, budget(income, px, py))$utility - lv
    lo <- 1e-12
    if (g(lo) >= 0) {
      return(0)
    }
    # Expand the bracket until the target is affordable.
    hi <- 1
    for (i in seq_len(200L)) {
      if (g(hi) >= 0) break
      hi <- hi * 2
    }
    if (g(hi) < 0) {
      cli::cli_abort("Could not find an income that reaches level {.val {lv}}.")
    }
    stats::uniroot(g, c(lo, hi), tol = 1e-10)$root
  }, numeric(1))
}

#' @rdname expenditure
#' @export
expenditure.cobb_douglas <- function(u, px, py, level, ...) {
  p <- cd_params(u)
  d <- p$alpha + p$beta
  # Invert output = A C^d (alpha / (d px))^alpha (beta / (d py))^beta.
  scale <- (p$alpha / (d * px))^p$alpha * (p$beta / (d * py))^p$beta
  out <- (level / (p$A * scale))^(1 / d)
  out[level <= 0] <- 0
  out
}

#' @rdname expenditure
#' @export
expenditure.ces <- function(u, px, py, level, ...) {
  alpha <- attr(u, "alpha")
  sigma <- attr(u, "sigma")
  A <- attr(u, "A")
  if (!is.finite(sigma)) {
    # rho = 1: perfect substitutes; the price index below collapses to 0^0.
    return(expenditure(as_perfect_substitutes(u), px, py, level))
  }
  price_index <- if (sigma == 1) {
    # Unreachable for a constructed ces() (rho = 0 is refused), kept for safety.
    px^alpha * py^(1 - alpha)
  } else {
    (alpha^sigma * px^(1 - sigma) + (1 - alpha)^sigma * py^(1 - sigma))^(1 / (1 - sigma))
  }
  pmax(level, 0) / A * price_index
}

#' @rdname expenditure
#' @export
expenditure.quasilinear <- function(u, px, py, level, ...) {
  f <- attr(u, "f")
  f_prime <- attr(u, "f_prime")
  target <- px / py
  # Cheapest way to reach a level: buy x up to where f'(x) = px / py (the
  # same first-order condition as demand), then top up with y. If the level
  # is reached before that point, buy only x.
  g <- function(x) f_prime(x) - target
  hi <- 1
  for (i in seq_len(200L)) {
    if (g(hi) <= 0) break
    hi <- hi * 2
  }
  x_star <- if (g(1e-12) <= 0) 0 else stats::uniroot(g, c(1e-12, hi), tol = 1e-10)$root
  f_star <- f(x_star)

  vapply(level, function(lv) {
    y <- lv - f_star
    if (is.finite(y) && y >= 0) {
      return(px * x_star + py * y)
    }
    # Only x: the smallest x with f(x) = level.
    if (x_star <= 0) return(0)
    x <- stats::uniroot(function(x) f(x) - lv, c(1e-12, x_star), tol = 1e-10)$root
    px * x
  }, numeric(1))
}

#' @rdname expenditure
#' @export
expenditure.leontief <- function(u, px, py, level, ...) {
  pmax(level, 0) / attr(u, "A") * (attr(u, "a") * px + attr(u, "b") * py)
}

#' @rdname expenditure
#' @export
expenditure.perfect_substitutes <- function(u, px, py, level, ...) {
  pmax(level, 0) / attr(u, "A") * min(px / attr(u, "a"), py / attr(u, "b"))
}

#' @rdname expenditure
#' @export
expenditure.default <- function(u, px, py, level, ...) {
  expenditure_numeric(u, px, py, level)
}

#' Decompose a price change into substitution and income effects
#'
#' When the price of one good changes, the consumer moves from the original
#' bundle to a new one. The textbook splits that move in two by imagining an
#' intermediate, *compensated* budget at the new prices:
#'
#' * **Hicks** compensation gives the consumer just enough income to reach
#'   the original utility at the new prices. The compensated bundle sits on
#'   the original indifference curve.
#' * **Slutsky** compensation gives just enough income to afford the original
#'   bundle at the new prices. The compensated budget line passes through the
#'   original bundle.
#'
#' The move from the original bundle to the compensated one is the
#' *substitution effect* (a pure response to relative prices); the move from
#' the compensated bundle to the final one is the *income effect*.
#'
#' `slutsky()` and `hicks()` are shorthands for `price_change()` with
#' `method` fixed.
#'
#' @param u A function of `x` and `y`, typically from [cobb_douglas()] or one
#'   of its siblings.
#' @param b The original [budget()].
#' @param new_px,new_py The new price. Supply exactly one.
#' @param method `"hicks"` (the default) or `"slutsky"`.
#'
#' @return An object of class `price_change`: a list with
#'   * `bundles` -- a data frame with one row each for the `original`,
#'     `compensated` and `final` bundles: `stage`, `x`, `y`, `utility`,
#'     `income`.
#'   * `effects` -- a data frame with rows `substitution`, `income` and
#'     `total`, and columns `dx` and `dy`.
#'   * `budgets` -- the three [budget()] objects, in the same order.
#'   * `method`, `good` (the good whose price changed), `old_price`,
#'     `new_price`.
#'
#' @seealso [plot_price_change()] to draw it.
#'
#' @examples
#' u <- cobb_douglas(alpha = 0.4)
#' b <- budget(income = 120, px = 3, py = 4)
#'
#' pc <- price_change(u, b, new_px = 6)
#' pc
#' pc$effects
#'
#' # Quasi-linear preferences: the income effect on x vanishes
#' q <- quasilinear(log, f_prime = function(x) 1 / x)
#' slutsky(q, b, new_px = 6)$effects
#' @export
price_change <- function(u, b, new_px = NULL, new_py = NULL,
                         method = c("hicks", "slutsky")) {
  if (!is.function(u)) {
    cli::cli_abort("{.arg u} must be a function of {.arg x} and {.arg y}.")
  }
  if (!inherits(b, "budget")) {
    cli::cli_abort("{.arg b} must be a {.fn budget} object.")
  }
  if (is.null(new_px) == is.null(new_py)) {
    cli::cli_abort("Supply exactly one of {.arg new_px} and {.arg new_py}.")
  }
  method <- match.arg(method)

  good <- if (is.null(new_py)) "x" else "y"
  new_price <- check_positive(if (good == "x") new_px else new_py)
  old_price <- if (good == "x") b$px else b$py
  b_final <- if (good == "x") budget_with(b, px = new_px) else budget_with(b, py = new_py)

  original <- optimal_bundle(u, b)
  final <- optimal_bundle(u, b_final)

  comp_income <- if (method == "slutsky") {
    b_final$cost_x(original$x) + b_final$cost_y(original$y)
  } else {
    expenditure(u, b_final$px, b_final$py, original$utility)
  }
  b_comp <- budget_with(b_final, income = comp_income)
  compensated <- optimal_bundle(u, b_comp)

  bundles <- data.frame(
    stage = c("original", "compensated", "final"),
    x = c(original$x, compensated$x, final$x),
    y = c(original$y, compensated$y, final$y),
    utility = c(original$utility, compensated$utility, final$utility),
    income = c(b$income, comp_income, b_final$income),
    stringsAsFactors = FALSE
  )
  effects <- data.frame(
    effect = c("substitution", "income", "total"),
    dx = c(compensated$x - original$x, final$x - compensated$x, final$x - original$x),
    dy = c(compensated$y - original$y, final$y - compensated$y, final$y - original$y),
    stringsAsFactors = FALSE
  )

  structure(
    list(
      bundles = bundles,
      effects = effects,
      budgets = list(original = b, compensated = b_comp, final = b_final),
      method = method,
      good = good,
      old_price = old_price,
      new_price = new_price
    ),
    class = "price_change"
  )
}

#' @rdname price_change
#' @export
slutsky <- function(u, b, new_px = NULL, new_py = NULL) {
  price_change(u, b, new_px = new_px, new_py = new_py, method = "slutsky")
}

#' @rdname price_change
#' @export
hicks <- function(u, b, new_px = NULL, new_py = NULL) {
  price_change(u, b, new_px = new_px, new_py = new_py, method = "hicks")
}

#' @export
print.price_change <- function(x, ...) {
  fmt <- fmt_num
  cat(sprintf("<Price change: p%s %s -> %s, %s compensation>\n",
              x$good, fmt(x$old_price), fmt(x$new_price),
              if (x$method == "hicks") "Hicksian" else "Slutsky"))
  b <- x$bundles
  for (i in seq_len(nrow(b))) {
    cat(sprintf("  %-12s x = %8s  y = %8s  (income %s)\n",
                b$stage[i], fmt(b$x[i]), fmt(b$y[i]), fmt(b$income[i])))
  }
  e <- x$effects
  cat("  effects on", x$good, ":\n")
  for (i in seq_len(nrow(e))) {
    d <- if (x$good == "x") e$dx[i] else e$dy[i]
    cat(sprintf("    %-12s %s\n", e$effect[i], fmt(d)))
  }
  invisible(x)
}

#' Draw the substitution and income effects of a price change
#'
#' The diagram behind [price_change()]: the original and final budget lines,
#' the dashed compensated line, the indifference curves through the bundles,
#' the three bundles themselves, and brackets along the axis of the good whose
#' price changed showing how far the substitution and income effects each
#' move the quantity.
#'
#' @param u A function of `x` and `y`.
#' @param b The original [budget()].
#' @param new_px,new_py The new price. Supply exactly one.
#' @param method `"hicks"` or `"slutsky"`.
#' @param goods Axis labels for `x` and `y`.
#' @param title,subtitle,source Passed to [labs_econ()]; sensible defaults
#'   are filled in.
#' @param xlim,ylim Panel limits. Default to a little beyond the widest
#'   budget line.
#' @param panel Passed to [theme_econ()].
#'
#' @return A ggplot object. Add [econ_masthead()] last if you want the block.
#'
#' @examples
#' u <- cobb_douglas(alpha = 0.4)
#' b <- budget(income = 120, px = 3, py = 4)
#' plot_price_change(u, b, new_px = 6)
#' plot_price_change(u, b, new_px = 6, method = "slutsky")
#' @export
plot_price_change <- function(u, b, new_px = NULL, new_py = NULL,
                              method = c("hicks", "slutsky"),
                              goods = c("Good x", "Good y"),
                              title = NULL, subtitle = NULL, source = NULL,
                              xlim = NULL, ylim = NULL, panel = NULL) {
  method <- match.arg(method)
  if (!is.character(goods) || length(goods) != 2L) {
    cli::cli_abort("{.arg goods} must be two labels.")
  }
  pc <- price_change(u, b, new_px = new_px, new_py = new_py, method = method)
  bd <- pc$budgets
  bundles <- pc$bundles

  if (is.null(xlim)) xlim <- c(0, max(vapply(bd, function(bb) bb$x_max, numeric(1))) * 1.1)
  if (is.null(ylim)) ylim <- c(0, max(vapply(bd, function(bb) bb$y_max, numeric(1))) * 1.1)
  if (is.null(title)) {
    title <- sprintf("%s of a price %s",
                     if (method == "hicks") "Hicks decomposition" else "Slutsky decomposition",
                     if (pc$new_price > pc$old_price) "rise" else "fall")
  }
  if (is.null(subtitle)) {
    changed <- if (pc$good == "x") goods[1] else goods[2]
    subtitle <- sprintf("Price of %s from %s to %s; income %s",
                        changed, format(pc$old_price), format(pc$new_price),
                        format(b$income))
  }

  levels <- unique(signif(bundles$utility, 10))
  ink <- style_colour("ink")
  muted <- style_colour("muted")

  # Brackets along the axis of the changed good, stacked just inside the panel.
  along_x <- pc$good == "x"
  q <- if (along_x) bundles$x else bundles$y
  off <- diff(if (along_x) ylim else xlim) * c(0.05, 0.11)
  bracket <- function(from, to, level, label) {
    if (isTRUE(all.equal(from, to))) {
      return(NULL)
    }
    seg <- if (along_x) {
      ggplot2::annotate("segment", x = from, xend = to, y = level, yend = level,
                        colour = ink, linewidth = 0.4,
                        arrow = grid::arrow(length = grid::unit(0.15, "cm"), type = "closed"))
    } else {
      ggplot2::annotate("segment", y = from, yend = to, x = level, xend = level,
                        colour = ink, linewidth = 0.4,
                        arrow = grid::arrow(length = grid::unit(0.15, "cm"), type = "closed"))
    }
    txt <- if (along_x) {
      ggplot2::annotate("text", x = (from + to) / 2, y = level, label = label,
                        vjust = -0.6, size = 3, colour = ink)
    } else {
      ggplot2::annotate("text", y = (from + to) / 2, x = level, label = label,
                        hjust = -0.2, size = 3, colour = ink, angle = 90)
    }
    list(seg, txt)
  }

  ggplot2::ggplot() +
    geom_budget(list(bd$original, bd$final)) +
    geom_budget(bd$compensated, colour = muted, linetype = "dashed", linewidth = 0.6) +
    geom_indifference(u, levels = levels, xlim = xlim) +
    ggplot2::annotate("point", x = bundles$x, y = bundles$y, colour = ink, size = 2.5) +
    ggplot2::annotate("text", x = bundles$x, y = bundles$y,
                      label = c("A", "B", "C"), colour = ink, size = 3.2,
                      hjust = -0.5, vjust = -0.5) +
    bracket(q[1], q[2], off[1], "Substitution") +
    bracket(q[2], q[3], off[2], "Income") +
    ggplot2::coord_cartesian(xlim = xlim, ylim = ylim, expand = FALSE) +
    labs_econ(title = title, subtitle = subtitle, source = source,
              note = "A original, B compensated, C final; dashed line is the compensated budget") +
    ggplot2::labs(x = goods[1], y = goods[2]) +
    theme_econ(panel = panel, grid = "both") +
    econ_axes(panel)
}
