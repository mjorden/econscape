#' Producer theory: expansion paths and cost curves
#'
#' The consumer's problem and the producer's cost-minimisation problem are the
#' same mathematics with different names: a production function is a utility
#' function over inputs, an isocost line is a budget line with input prices,
#' and the expenditure function is the total-cost function. These helpers put
#' the producer's vocabulary on the machinery the rest of the package already
#' has.
#'
#' * `expansion_path()` -- the cost-minimising input bundle at each level of
#'   outlay, i.e. the income-consumption path read as a producer.
#' * `conditional_demand()` -- the cheapest input bundle that produces each
#'   output level, and what it costs.
#' * `cost_curves()` -- total, average and marginal cost at each output level.
#'   Marginal cost is closed-form for Cobb-Douglas (\eqn{C(q) \propto
#'   q^{1/(\alpha+\beta)}}, so \eqn{MC = C / ((\alpha + \beta) q)}) and a
#'   numerical derivative of [expenditure()] otherwise; for the constant-
#'   returns constructors that derivative is exact.
#'
#' @param f A production function of `x` and `y`, e.g.
#'   `cobb_douglas(0.3, 0.5, kind = "production")`.
#' @param w,r Input prices for `x` and `y` (wage and rental rate, by
#'   convention).
#' @param outlays Vector of total outlays.
#' @param q Vector of output levels. Positive.
#' @param fixed A fixed cost added to total cost. It does not affect marginal
#'   cost, but gives average cost its textbook U shape.
#'
#' @return A data frame:
#'   * `expansion_path()`: `outlay`, `x`, `y`, `output`.
#'   * `conditional_demand()`: `output`, `x`, `y`, `cost`.
#'   * `cost_curves()`: `output`, `total`, `average`, `marginal`.
#'
#' @examples
#' f <- cobb_douglas(0.3, 0.5, A = 2, kind = "production")
#' f   # decreasing returns to scale
#'
#' expansion_path(f, w = 20, r = 30, outlays = c(300, 600, 900))
#' conditional_demand(f, w = 20, r = 30, q = c(5, 10, 20))
#' cost_curves(f, w = 20, r = 30, q = c(5, 10, 20), fixed = 100)
#' @name producer
NULL

#' @rdname producer
#' @export
expansion_path <- function(f, w, r, outlays) {
  if (!is.function(f)) {
    cli::cli_abort("{.arg f} must be a function of {.arg x} and {.arg y}.")
  }
  check_positive(w)
  check_positive(r)
  outlays <- check_positive_vector(outlays)
  path <- income_consumption_path(f, budget(outlays[1], w, r), outlays)
  data.frame(
    outlay = path$income,
    x = path$x,
    y = path$y,
    output = f(path$x, path$y)
  )
}

#' @rdname producer
#' @export
conditional_demand <- function(f, w, r, q) {
  if (!is.function(f)) {
    cli::cli_abort("{.arg f} must be a function of {.arg x} and {.arg y}.")
  }
  check_positive(w)
  check_positive(r)
  q <- check_positive_vector(q)
  cost <- expenditure(f, w, r, q)
  rows <- lapply(seq_along(q), function(i) {
    opt <- optimal_bundle(f, budget(cost[i], w, r))
    data.frame(output = q[i], x = opt$x, y = opt$y, cost = cost[i])
  })
  do.call(rbind, rows)
}

#' @rdname producer
#' @export
cost_curves <- function(f, w, r, q, fixed = 0) {
  if (!is.function(f)) {
    cli::cli_abort("{.arg f} must be a function of {.arg x} and {.arg y}.")
  }
  check_positive(w)
  check_positive(r)
  q <- check_positive_vector(q)
  check_positive(fixed, zero_ok = TRUE)

  variable <- expenditure(f, w, r, q)
  total <- fixed + variable
  data.frame(
    output = q,
    total = total,
    average = total / q,
    marginal = mc_from_production(f, w, r, q)
  )
}

#' Marginal cost of production at each output level (internal; dispatches on the production function -- marginal_cost() is the public generic on cost objects)
#' @noRd
mc_from_production <- function(f, w, r, q) {
  UseMethod("mc_from_production")
}

#' @noRd
mc_from_production.cobb_douglas <- function(f, w, r, q) {
  d <- attr(f, "alpha") + attr(f, "beta")
  expenditure(f, w, r, q) / (d * q)
}

#' @noRd
mc_from_production.default <- function(f, w, r, q) {
  # When expenditure() has no closed form it is a uniroot() around an
  # optimize(), accurate to ~1e-9: a difference step must sit well above
  # that noise floor or the derivative is garbage near zero output.
  closed_form <- inherits(f, c("cobb_douglas", "ces", "leontief", "perfect_substitutes", "quasilinear"))
  numeric_derivative(function(lv) expenditure(f, w, r, lv),
                     h_min = if (closed_form) 0 else 1e-4)(q)
}

#' Draw average and marginal cost
#'
#' Plots the average- and marginal-cost curves from [cost_curves()] in the
#' house style, each labelled at its right-hand end. Total cost is left out:
#' it lives on a different scale and the AC/MC pair is the one the textbook
#' argument is about.
#'
#' @inheritParams producer
#' @param title,subtitle,source Passed to [labs_econ()]; sensible defaults
#'   are filled in.
#' @param panel Passed to [theme_econ()].
#'
#' @return A ggplot object. Add [econ_masthead()] last if you want the block.
#'
#' @examples
#' f <- cobb_douglas(0.3, 0.5, A = 2, kind = "production")
#' plot_cost_curves(f, w = 20, r = 30, q = seq(1, 40, by = 0.5), fixed = 150)
#' @export
plot_cost_curves <- function(f, w, r, q, fixed = 0,
                             title = NULL, subtitle = NULL, source = NULL,
                             panel = "blue") {
  cc <- cost_curves(f, w, r, q, fixed = fixed)
  long <- rbind(
    data.frame(output = cc$output, cost = cc$average, curve = "Average cost"),
    data.frame(output = cc$output, cost = cc$marginal, curve = "Marginal cost")
  )
  ends <- long[long$output == max(long$output), , drop = FALSE]

  if (is.null(title)) title <- "Cost curves"
  if (is.null(subtitle)) {
    subtitle <- sprintf("Input prices w = %s, r = %s%s", format(w), format(r),
                        if (fixed > 0) sprintf("; fixed cost %s", format(fixed)) else "")
  }

  ggplot2::ggplot(long, ggplot2::aes(x = .data$output, y = .data$cost,
                                     colour = .data$curve)) +
    ggplot2::geom_line(linewidth = 0.8) +
    ggplot2::geom_text(
      data = ends,
      mapping = ggplot2::aes(label = .data$curve),
      hjust = 1, vjust = -0.5, size = 3.2, show.legend = FALSE
    ) +
    scale_colour_econ(palette = "contrast") +
    ggplot2::scale_x_continuous(expand = ggplot2::expansion(mult = c(0, 0.02))) +
    scale_y_econ(limits = c(0, NA)) +
    labs_econ(title = title, subtitle = subtitle, source = source) +
    ggplot2::labs(x = "Output", y = "Cost per unit") +
    theme_econ(panel = panel, legend_position = "none") +
    # Deliberately not econ_axes(): the y labels sit on the right here, so a
    # left-hand axis line would frame nothing.
    ggplot2::theme(axis.title = ggplot2::element_text(hjust = 1))
}

#' Draw the producer's cost-minimising choice
#'
#' The same diagram as [plot_consumer_choice()] with the producer's
#' vocabulary: isoquants, an isocost line, and the input bundle that produces
#' the most for the outlay. Works for any production function, including a
#' plain `function(x, y)`. The `kind` attribute is set to `"production"` on a
#' copy for the labels regardless of how the function was built -- so a
#' `cobb_douglas(0.5)` constructed with the default `kind = "utility"` draws
#' as a technology here without complaint. That is deliberate: the maths is
#' identical and the constructor default should not force a keystroke.
#'
#' @param f A production function of `x` and `y`.
#' @param b A [budget()] read as an isocost line: `income` is the outlay and
#'   `px`, `py` the input prices.
#' @param inputs Axis labels for the two inputs.
#' @inheritParams plot_consumer_choice
#'
#' @return A ggplot object.
#'
#' @examples
#' f <- cobb_douglas(0.5, 0.5, A = 3, kind = "production")
#' plot_producer_choice(f, budget(600, 20, 30))
#' @export
plot_producer_choice <- function(f, b, inputs = c("Labour", "Capital"),
                                 levels = NULL, xlim = NULL, ylim = NULL,
                                 title = NULL, subtitle = NULL, source = NULL,
                                 label_levels = TRUE, panel = "blue") {
  if (!is.function(f)) {
    cli::cli_abort("{.arg f} must be a function of {.arg x} and {.arg y}.")
  }
  attr(f, "kind") <- "production"
  plot_consumer_choice(
    f, b, levels = levels, xlim = xlim, ylim = ylim, goods = inputs,
    title = title, subtitle = subtitle, source = source,
    label_levels = label_levels, panel = panel
  )
}
