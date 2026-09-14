#' Check a numeric vector of positive values
#' @noRd
check_positive_vector <- function(x, arg = rlang::caller_arg(x)) {
  if (!is.numeric(x) || length(x) == 0L || any(!is.finite(x)) || any(x <= 0)) {
    cli::cli_abort("{.arg {arg}} must be a numeric vector of positive values.")
  }
  x
}

#' @noRd
check_good <- function(good) {
  if (!is.character(good) || length(good) != 1L || !good %in% c("x", "y")) {
    cli::cli_abort("{.arg good} must be {.val x} or {.val y}.")
  }
  good
}

#' Re-price or re-fund a budget
#' @noRd
budget_with <- function(b, income = b$income, px = b$px, py = b$py) {
  budget(income = income, px = px, py = py)
}

#' Curves traced by the optimal bundle
#'
#' [optimal_bundle()] answers one question: what does the consumer choose at
#' one set of prices and one income? These functions ask it repeatedly and
#' collect the answers.
#'
#' * `demand_curve()` varies the price of one good, holding the other price
#'   and income fixed, and records the quantity of that good.
#' * `engel_curve()` varies income, holding both prices fixed, and records the
#'   quantity of one good.
#' * `price_consumption_path()` and `income_consumption_path()` are the same
#'   experiments, but keep the whole bundle `(x, y)` so the locus can be drawn
#'   on the indifference-curve diagram.
#'
#' Every constructor in the package has a closed-form [optimal_bundle()], so
#' these are fast; a plain `function(x, y)` goes through the numeric line
#' search once per point.
#'
#' @param u A function of `x` and `y`, typically from [cobb_douglas()] or one
#'   of its siblings.
#' @param b A [budget()] giving the baseline income and prices. The one being
#'   varied is overridden.
#' @param prices Vector of prices for `good` to evaluate at.
#' @param incomes Vector of incomes to evaluate at.
#' @param good Which good's price to vary or quantity to report: `"x"` or
#'   `"y"`.
#'
#' @return A data frame, one row per price or income:
#'   * `demand_curve()`: `price`, `quantity`, `good`.
#'   * `engel_curve()`: `income`, `quantity`, `good`.
#'   * `price_consumption_path()`: `price`, `x`, `y`, `good`.
#'   * `income_consumption_path()`: `income`, `x`, `y`.
#'
#' @examples
#' u <- cobb_douglas(alpha = 0.4)
#' b <- budget(income = 120, px = 3, py = 4)
#'
#' # Cobb-Douglas demand is a rectangular hyperbola: x = 0.4 * 120 / px
#' demand_curve(u, b, prices = c(1, 2, 4, 8))
#'
#' # ... and the Engel curve a ray through the origin
#' engel_curve(u, b, incomes = c(60, 120, 240))
#'
#' # Quasi-linear: the demand for x ignores income entirely
#' q <- quasilinear(log, f_prime = function(x) 1 / x)
#' engel_curve(q, b, incomes = c(60, 120, 240))
#' @name derived_curves
NULL

#' @rdname derived_curves
#' @export
demand_curve <- function(u, b, prices, good = "x") {
  path <- price_consumption_path(u, b, prices, good)
  data.frame(
    price = path$price,
    quantity = path[[good]],
    good = good,
    stringsAsFactors = FALSE
  )
}

#' @rdname derived_curves
#' @export
engel_curve <- function(u, b, incomes, good = "x") {
  good <- check_good(good)
  path <- income_consumption_path(u, b, incomes)
  data.frame(
    income = path$income,
    quantity = path[[good]],
    good = good,
    stringsAsFactors = FALSE
  )
}

#' @rdname derived_curves
#' @export
price_consumption_path <- function(u, b, prices, good = "x") {
  if (!inherits(b, "budget")) {
    cli::cli_abort("{.arg b} must be a {.fn budget} object.")
  }
  good <- check_good(good)
  prices <- check_positive_vector(prices)

  rows <- lapply(prices, function(p) {
    bp <- if (good == "x") budget_with(b, px = p) else budget_with(b, py = p)
    opt <- optimal_bundle(u, bp)
    data.frame(price = p, x = opt$x, y = opt$y)
  })
  out <- do.call(rbind, rows)
  out$good <- good
  out
}

#' @rdname derived_curves
#' @export
income_consumption_path <- function(u, b, incomes) {
  if (!inherits(b, "budget")) {
    cli::cli_abort("{.arg b} must be a {.fn budget} object.")
  }
  incomes <- check_positive_vector(incomes)

  rows <- lapply(incomes, function(i) {
    opt <- optimal_bundle(u, budget_with(b, income = i))
    data.frame(income = i, x = opt$x, y = opt$y)
  })
  do.call(rbind, rows)
}

#' Draw a demand or Engel curve
#'
#' `geom_demand()` draws the output of [demand_curve()] the way every textbook
#' does: quantity along the x-axis, price up the y-axis. `geom_engel()` draws
#' [engel_curve()] with income along the x-axis.
#'
#' @param data A data frame from [demand_curve()] or [engel_curve()].
#' @param colour Line colour.
#' @param linewidth Line width.
#' @param ... Passed to [ggplot2::geom_path()].
#'
#' @return A ggplot2 layer.
#'
#' @examples
#' library(ggplot2)
#' u <- cobb_douglas(alpha = 0.4)
#' b <- budget(income = 120, px = 3, py = 4)
#' d <- demand_curve(u, b, prices = seq(0.5, 10, by = 0.25))
#'
#' ggplot() +
#'   geom_demand(d) +
#'   labs_econ(title = "Demand for x", subtitle = "Price against quantity") +
#'   labs(x = "Quantity", y = "Price") +
#'   theme_econ()
#' @name geom_demand
NULL

#' @rdname geom_demand
#' @export
geom_demand <- function(data, colour = style_colour("primary"), linewidth = 0.8, ...) {
  if (!is.data.frame(data) || !all(c("price", "quantity") %in% names(data))) {
    cli::cli_abort("{.arg data} must come from {.fn demand_curve}.")
  }
  data <- data[order(data$price), , drop = FALSE]
  ggplot2::geom_path(
    data = data,
    mapping = ggplot2::aes(x = .data$quantity, y = .data$price),
    colour = colour, linewidth = linewidth, inherit.aes = FALSE, ...
  )
}

#' @rdname geom_demand
#' @export
geom_engel <- function(data, colour = style_colour("primary"), linewidth = 0.8, ...) {
  if (!is.data.frame(data) || !all(c("income", "quantity") %in% names(data))) {
    cli::cli_abort("{.arg data} must come from {.fn engel_curve}.")
  }
  data <- data[order(data$income), , drop = FALSE]
  ggplot2::geom_path(
    data = data,
    mapping = ggplot2::aes(x = .data$income, y = .data$quantity),
    colour = colour, linewidth = linewidth, inherit.aes = FALSE, ...
  )
}

#' Draw the locus of optimal bundles
#'
#' Adds a [price_consumption_path()] or [income_consumption_path()] to the
#' indifference-curve diagram as a path through the bundles, with a point at
#' each one. Pair it with [geom_budget()] given the matching list of budgets
#' to show the lines the bundles sit on.
#'
#' @param data A data frame with `x` and `y` columns from one of the path
#'   functions.
#' @param colour Path and point colour.
#' @param linewidth Path width.
#' @param size Point size; `0` for no points.
#' @param ... Passed to [ggplot2::geom_path()].
#'
#' @return A list of ggplot2 layers.
#'
#' @examples
#' library(ggplot2)
#' u <- cobb_douglas(alpha = 0.4)
#' b <- budget(income = 120, px = 3, py = 4)
#' incomes <- c(60, 120, 180)
#' path <- income_consumption_path(u, b, incomes)
#'
#' ggplot() +
#'   geom_budget(lapply(incomes, function(i) budget(i, 3, 4))) +
#'   geom_indifference(u, levels = path$x^0.4 * path$y^0.6, xlim = c(0, 60)) +
#'   geom_consumption_path(path) +
#'   coord_cartesian(xlim = c(0, 60), ylim = c(0, 45), expand = FALSE) +
#'   theme_econ()
#' @export
geom_consumption_path <- function(data, colour = style_colour("ink"),
                                  linewidth = 0.6, size = 2, ...) {
  if (!is.data.frame(data) || !all(c("x", "y") %in% names(data))) {
    cli::cli_abort("{.arg data} must have {.field x} and {.field y} columns.")
  }
  layers <- list(
    ggplot2::geom_path(
      data = data,
      mapping = ggplot2::aes(x = .data$x, y = .data$y),
      colour = colour, linewidth = linewidth, inherit.aes = FALSE, ...
    )
  )
  if (size > 0) {
    layers <- c(layers, list(
      ggplot2::geom_point(
        data = data,
        mapping = ggplot2::aes(x = .data$x, y = .data$y),
        colour = colour, size = size, inherit.aes = FALSE
      )
    ))
  }
  layers
}
