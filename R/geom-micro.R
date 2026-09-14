#' Grid of x values for drawing a curve, avoiding the singularity at zero
#'
#' Cobb-Douglas indifference curves go to infinity as `x` approaches zero, so a
#' grid that starts exactly at the axis produces an `Inf` and a broken path.
#'
#' @param xlim Two numbers.
#' @param n_points Number of points.
#' @return A numeric vector.
#' @noRd
curve_grid <- function(xlim, n_points) {
  if (!is.numeric(xlim) || length(xlim) != 2L || any(!is.finite(xlim)) ||
      xlim[1] >= xlim[2] || xlim[1] < 0) {
    cli::cli_abort("{.arg xlim} must be an increasing pair of non-negative numbers.")
  }
  n_points <- as.integer(n_points)
  if (is.na(n_points) || n_points < 2L) {
    cli::cli_abort("{.arg n_points} must be at least 2.")
  }
  lo <- if (xlim[1] > 0) xlim[1] else diff(xlim) / (n_points * 4)
  seq(lo, xlim[2], length.out = n_points)
}

#' Chart layers for consumer and producer theory
#'
#' Layers that put [indifference_curve()], [budget()] and [optimal_bundle()]
#' onto a ggplot without constructing the data by hand. None of them inherit
#' aesthetics from the plot, so they can be added to an empty `ggplot()` or
#' combined with other data.
#'
#' * `geom_indifference()` draws one path per `level`.
#' * `geom_budget()` draws the budget (or isocost) line between its two
#'   intercepts. Given a list of budgets it draws one line each, which is how
#'   a price or income change is shown.
#' * `geom_optimum()` marks the chosen bundle, with dashed lines dropping to
#'   each axis.
#'
#' @param u A function of `x` and `y`, typically from [cobb_douglas()].
#' @param levels Utility (or output) levels, one curve each.
#' @param xlim Range of `x` over which to draw the curves.
#' @param n_points Number of points per curve. (Named `n_points`, not `n`,
#'   because `n` means a number of firms or consumers elsewhere in the
#'   package.)
#' @param b A [budget()], or for `geom_budget()` a list of them.
#' @param colour Line or point colour.
#' @param linewidth Line width.
#' @param linetype Line type; the drop lines in `geom_optimum()` are always
#'   dashed.
#' @param size Point size.
#' @param drop_lines Draw the dashed lines from the optimum to each axis?
#' @param ... Passed to the underlying geom.
#'
#' @return A ggplot2 layer, or a list of layers, that can be added to a plot
#'   with `+`. The convention throughout the package: a `geom_*()` returns a
#'   single layer when it draws one thing (`geom_budget()`, `geom_demand()`,
#'   `geom_engel()`) and a list when it draws several that belong together
#'   (`geom_optimum()`'s point and drop lines, `geom_consumption_path()`'s
#'   path and points, `geom_indifference()`'s path and the vertical arm of a
#'   Leontief L). Both add with `+` identically.
#'
#' @seealso [plot_consumer_choice()] for the whole chart in one call.
#'
#' @examples
#' library(ggplot2)
#' u <- cobb_douglas(alpha = 0.4)
#' b <- budget(income = 120, px = 3, py = 4)
#'
#' ggplot() +
#'   geom_indifference(u, levels = c(8, 12, 16), xlim = c(0, 45)) +
#'   geom_budget(b) +
#'   geom_optimum(u, b) +
#'   coord_cartesian(xlim = c(0, 45), ylim = c(0, 35), expand = FALSE) +
#'   theme_econ()
#' @name geom_micro
NULL

#' @rdname geom_micro
#' @export
geom_indifference <- function(u, levels, xlim, n_points = 200L,
                              colour = unname(econ_hex["blue"]),
                              linewidth = 0.8, ...) {
  x <- curve_grid(xlim, n_points)
  df <- indifference_curve(u, level = levels, x = x)
  df <- df[is.finite(df$y), , drop = FALSE]
  path <- ggplot2::geom_path(
    data = df,
    mapping = ggplot2::aes(x = .data$x, y = .data$y, group = .data$level),
    colour = colour,
    linewidth = linewidth,
    inherit.aes = FALSE,
    ...
  )
  if (!inherits(u, "leontief")) {
    return(path)
  }
  # A Leontief contour is L-shaped, and indifference_curve() can only return
  # one y per x -- the horizontal arm. Draw the vertical arm from the kink up
  # to the top of the panel as a separate segment per level.
  kink_x <- attr(u, "a") * levels / attr(u, "A")
  kink_y <- attr(u, "b") * levels / attr(u, "A")
  keep <- levels > 0
  arms <- ggplot2::annotate(
    "segment",
    x = kink_x[keep], xend = kink_x[keep], y = kink_y[keep], yend = Inf,
    colour = colour, linewidth = linewidth
  )
  list(path, arms)
}

#' @rdname geom_micro
#' @export
geom_budget <- function(b, colour = unname(econ_hex["red"]),
                        linewidth = 0.8, linetype = "solid", ...) {
  budgets <- if (inherits(b, "budget")) list(b) else b
  if (!is.list(budgets) || length(budgets) == 0L ||
      !all(vapply(budgets, inherits, logical(1), what = "budget"))) {
    cli::cli_abort("{.arg b} must be a {.fn budget} object or a list of them.")
  }
  # One segment per budget, from the y intercept to the x intercept. Built as
  # data rather than annotate() so a family of lines is a single layer that
  # colour/linetype vectors can be recycled across.
  lines <- data.frame(
    x = 0,
    y = vapply(budgets, function(bb) bb$y_max, numeric(1)),
    xend = vapply(budgets, function(bb) bb$x_max, numeric(1)),
    yend = 0
  )
  ggplot2::geom_segment(
    data = lines,
    mapping = ggplot2::aes(x = .data$x, y = .data$y,
                           xend = .data$xend, yend = .data$yend),
    colour = colour, linewidth = linewidth, linetype = linetype,
    inherit.aes = FALSE, ...
  )
}

#' @rdname geom_micro
#' @export
geom_optimum <- function(u, b, colour = unname(econ_hex["ink"]),
                         size = 2.5, drop_lines = TRUE, ...) {
  opt <- optimal_bundle(u, b)
  layers <- list()
  if (drop_lines) {
    layers <- c(layers, list(
      ggplot2::annotate(
        "segment",
        x = c(opt$x, 0), y = c(0, opt$y), xend = opt$x, yend = opt$y,
        colour = colour, linewidth = 0.4, linetype = "dashed"
      )
    ))
  }
  c(layers, list(
    ggplot2::annotate(
      "point", x = opt$x, y = opt$y,
      colour = colour, size = size, ...
    )
  ))
}

#' Draw the consumer's choice in one call
#'
#' Composes indifference curves, the budget line and the optimal bundle into
#' a finished chart in the house style, with each curve labelled by its level
#' at the right-hand edge of the panel. For a `kind = "production"`
#' Cobb-Douglas the labels switch to isoquant and isocost vocabulary.
#'
#' @param u A function of `x` and `y`, typically from [cobb_douglas()].
#' @param b A [budget()].
#' @param levels Curve levels. Defaults to the optimum's utility and two
#'   curves either side of it.
#' @param xlim,ylim Panel limits. Default to a little beyond each intercept.
#' @param goods Axis labels for `x` and `y`.
#' @param title,subtitle,source Passed to [labs_econ()]. Sensible defaults
#'   are filled in from `u` and `b`.
#' @param label_levels Print each curve's level at its right-hand end?
#' @param panel Passed to [theme_econ()].
#'
#' @return A ggplot object. Add [econ_masthead()] last if you want the block.
#'
#' @examples
#' u <- cobb_douglas(alpha = 0.3)
#' b <- budget(income = 100, px = 2, py = 5)
#' plot_consumer_choice(u, b)
#'
#' f <- cobb_douglas(0.5, 0.5, A = 3, kind = "production")
#' plot_consumer_choice(f, budget(600, 20, 30), goods = c("Labour", "Capital"))
#' @export
plot_consumer_choice <- function(u, b,
                                 levels = NULL,
                                 xlim = NULL,
                                 ylim = NULL,
                                 goods = c("Good x", "Good y"),
                                 title = NULL,
                                 subtitle = NULL,
                                 source = NULL,
                                 label_levels = TRUE,
                                 panel = "blue") {
  if (!inherits(b, "budget")) {
    cli::cli_abort("{.arg b} must be a {.fn budget} object.")
  }
  if (!is.character(goods) || length(goods) != 2L) {
    cli::cli_abort("{.arg goods} must be two labels.")
  }
  opt <- optimal_bundle(u, b)
  production <- identical(attr(u, "kind"), "production")

  if (is.null(levels)) {
    levels <- opt$utility * c(0.7, 1, 1.3)
  }
  if (is.null(xlim)) xlim <- c(0, b$x_max * 1.15)
  if (is.null(ylim)) ylim <- c(0, b$y_max * 1.15)

  if (is.null(title)) {
    title <- if (production) "Cost minimisation" else "Consumer choice"
  }
  if (is.null(subtitle)) {
    subtitle <- sprintf(
      "%s %s at %s; %s = %s, %s = %s",
      if (production) "Outlay" else "Income",
      format(b$income), if (production) "input prices" else "prices",
      goods[1], format(b$px), goods[2], format(b$py)
    )
  }
  curve_name <- if (production) "Isoquant" else "Indifference curve"

  p <- ggplot2::ggplot() +
    geom_indifference(u, levels = levels, xlim = xlim) +
    geom_budget(b) +
    geom_optimum(u, b)

  if (label_levels) {
    labels <- curve_labels(u, levels, xlim, ylim)
    if (nrow(labels) > 0L) {
      p <- p + ggplot2::geom_text(
        data = labels,
        mapping = ggplot2::aes(x = .data$x, y = .data$y, label = .data$label),
        # Right-aligned and pulled inward: the panel has no expansion, so a
        # label pushed past the edge is clipped away.
        hjust = 1, vjust = -0.4, nudge_x = -diff(xlim) * 0.01,
        colour = unname(econ_hex["blue"]), size = 3.2,
        inherit.aes = FALSE
      )
    }
  }

  p +
    ggplot2::coord_cartesian(xlim = xlim, ylim = ylim, expand = FALSE) +
    labs_econ(title = title, subtitle = subtitle, source = source) +
    ggplot2::labs(x = goods[1], y = goods[2]) +
    theme_econ(panel = panel, grid = "both") +
    econ_axes(panel) +
    ggplot2::annotate(
      "text", x = xlim[2], y = ylim[2], label = curve_name,
      hjust = 1.05, vjust = 1.5, size = 3.2,
      colour = unname(econ_hex["muted"])
    )
}

#' Where to print each curve's level
#'
#' Takes, for each curve, the visible point furthest to the right: the curve's
#' end if it leaves the panel through the right edge, or the point where it
#' crosses the top edge otherwise. Curves that never enter the panel get no
#' label.
#'
#' @return A data frame with `x`, `y` and `label`.
#' @noRd
curve_labels <- function(u, levels, xlim, ylim, n_points = 400L) {
  x <- curve_grid(xlim, n_points)
  df <- indifference_curve(u, level = levels, x = x)
  df <- df[is.finite(df$y) & df$y >= ylim[1] & df$y <= ylim[2], , drop = FALSE]
  if (nrow(df) == 0L) {
    return(data.frame(x = numeric(0), y = numeric(0), label = character(0)))
  }
  rows <- lapply(split(df, df$level), function(d) {
    d[which.max(d$x), , drop = FALSE]
  })
  out <- do.call(rbind, rows)
  out$label <- format(signif(out$level, 3))
  # Nudge labels that would run off the top edge back inside the panel.
  out$y <- pmin(out$y, ylim[2] - diff(ylim) * 0.03)
  out[, c("x", "y", "label")]
}
