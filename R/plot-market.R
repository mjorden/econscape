#' Draw a market outcome
#'
#' The demand curve, the industry marginal-cost curve (marginal cost at each
#' firm's share of the quantity), marginal revenue where it matters, the
#' outcome, and the welfare areas: consumer surplus above the price, producer
#' surplus between the price and marginal cost, and the deadweight-loss
#' triangle between the outcome and the efficient quantity.
#'
#' @param outcome A `market_outcome` from [monopoly()], [cournot()],
#'   [perfect_competition()] or [first_degree()]. For first-degree
#'   discrimination the whole area between demand and marginal cost is
#'   shaded as producer surplus, since that is who gets it.
#' @param q_max Right-hand limit of the quantity axis. Defaults to the
#'   demand curve's `q_max`.
#' @param shade Which areas to shade: any of `"cs"`, `"ps"`, `"dwl"`.
#' @param title,subtitle,source Passed to [labs_econ()]; sensible defaults
#'   are filled in.
#' @param panel Passed to [theme_econ()].
#'
#' @return A ggplot object. Add [econ_masthead()] last if you want the block.
#'
#' @examples
#' d <- linear_demand(intercept = 100, slope = 1)
#' plot_market(monopoly(d, quadratic_cost(a = 20)))
#' plot_market(cournot(d, quadratic_cost(a = 20), n = 3))
#' plot_market(perfect_competition(d, quadratic_cost(fixed = 100, a = 20, b = 1)))
#' @export
plot_market <- function(outcome, q_max = NULL, shade = c("cs", "ps", "dwl"),
                        title = NULL, subtitle = NULL, source = NULL,
                        panel = NULL) {
  if (!inherits(outcome, "market_outcome")) {
    cli::cli_abort("{.arg outcome} must be a {.cls market_outcome}.")
  }
  shade <- match.arg(shade, several.ok = TRUE)
  d <- outcome$demand
  cst <- outcome$cost
  n <- outcome$n
  if (is.null(q_max)) q_max <- d$q_max
  check_positive(q_max)

  grid <- seq(q_max / 400, q_max, length.out = 400)
  curves <- data.frame(
    q = grid,
    demand = price_at(d, grid),
    mc = marginal_cost(cst, grid / n),
    mr = marginal_revenue(d, grid)
  )
  show_mr <- outcome$structure %in% c("monopoly", "cournot")
  p_top <- max(curves$demand) * 1.08

  Q <- outcome$quantity
  P <- outcome$price
  Q_eff <- outcome$efficient$quantity
  ink <- style_colour("ink")
  muted <- style_colour("muted")
  fills <- c(cs = style_colour("primary"), ps = style_colour("tertiary"),
             dwl = style_colour("secondary"))

  # A shaded area plus its label, or nothing at all when the area is empty --
  # perfect competition with flat marginal cost has no producer surplus, and
  # any efficient outcome has no deadweight loss.
  area <- function(from, to, upper, lower, key, text, at) {
    if (to <= from) return(NULL)
    qq <- seq(from, to, length.out = 120)
    top <- upper(qq)
    bottom <- pmin(lower(qq), top)
    if (all(top - bottom < 1e-9 * max(1, p_top))) return(NULL)
    list(
      ggplot2::geom_ribbon(
        data = data.frame(q = qq, ymin = bottom, ymax = top),
        mapping = ggplot2::aes(x = .data$q, ymin = .data$ymin, ymax = .data$ymax),
        fill = fills[[key]], alpha = 0.25, inherit.aes = FALSE
      ),
      ggplot2::annotate("text", x = at, y = (upper(at) + lower(at)) / 2, label = text,
                        size = 3, colour = fills[[key]], fontface = "bold")
    )
  }
  mc_line <- function(q) marginal_cost(cst, q / n)
  flat <- function(v) function(q) rep(v, length(q))

  first_degree <- identical(outcome$structure, "first-degree discrimination")

  layers <- list()
  if (first_degree) {
    # Every unit sells at willingness to pay: the whole area between demand
    # and marginal cost is the seller's, and there is nothing else to shade.
    if ("ps" %in% shade && Q > 0) {
      layers <- c(layers, area(0, Q, function(q) price_at(d, q), mc_line, "ps",
                               "Producer surplus\n(all of it)", Q * 0.35))
    }
  } else {
    if ("cs" %in% shade && Q > 0) {
      layers <- c(layers, area(0, Q, function(q) price_at(d, q), flat(P), "cs",
                               "Consumer surplus", Q * 0.35))
    }
    if ("ps" %in% shade && Q > 0) {
      layers <- c(layers, area(0, Q, flat(P), mc_line, "ps", "Producer surplus", Q * 0.35))
    }
    if ("dwl" %in% shade && Q_eff > Q * (1 + 1e-6)) {
      layers <- c(layers, area(Q, Q_eff, function(q) price_at(d, q), mc_line, "dwl",
                               "Deadweight\nloss", (Q + Q_eff) / 2))
    }
  }

  if (is.null(title)) {
    title <- switch(outcome$structure,
      "monopoly" = "Monopoly",
      "cournot" = sprintf("Cournot oligopoly, %s firms", format(n)),
      "competition" = sprintf("Perfect competition, %s firms", format(n)),
      "competition (long run)" = "Perfect competition, long run",
      "first-degree discrimination" = "First-degree price discrimination",
      cli::cli_abort("Unknown market structure {.val {outcome$structure}}.")
    )
  }
  if (is.null(subtitle)) {
    subtitle <- sprintf("Price %s, quantity %s; Lerner index %s",
                        formatC(P, digits = 3, format = "g"),
                        formatC(Q, digits = 3, format = "g"),
                        formatC(outcome$lerner, digits = 2, format = "f"))
  }

  # Label each line at its last point still inside the panel, so a demand or
  # marginal-revenue line that reaches zero before the right edge is labelled
  # where it ends rather than dropped.
  last_visible <- function(y) {
    i <- which(y > 0 & y < p_top)
    if (length(i) == 0L) return(NULL)
    i <- max(i)
    data.frame(q = curves$q[i], y = y[i])
  }
  line_labels <- do.call(rbind, Map(
    function(y, text) {
      pt <- last_visible(y)
      if (is.null(pt)) NULL else data.frame(pt, text = text)
    },
    c(list(curves$demand, curves$mc), if (show_mr) list(curves$mr)),
    c("Demand", "Marginal cost", if (show_mr) "Marginal revenue")
  ))

  p <- ggplot2::ggplot() + layers +
    ggplot2::geom_line(data = curves, ggplot2::aes(x = .data$q, y = .data$demand),
                       colour = style_colour("primary"), linewidth = 0.8) +
    ggplot2::geom_line(data = curves, ggplot2::aes(x = .data$q, y = .data$mc),
                       colour = style_colour("secondary"), linewidth = 0.8)
  if (show_mr) {
    p <- p + ggplot2::geom_line(data = curves, ggplot2::aes(x = .data$q, y = .data$mr),
                                colour = muted, linewidth = 0.6, linetype = "dashed")
  }
  p +
    ggplot2::geom_text(data = line_labels,
                       ggplot2::aes(x = .data$q, y = .data$y, label = .data$text),
                       hjust = 1, vjust = -0.5, size = 3, colour = ink) +
    ggplot2::annotate("segment", x = c(Q, 0), xend = Q, y = c(0, P), yend = P,
                      colour = ink, linewidth = 0.4, linetype = "dotted") +
    ggplot2::annotate("point", x = Q, y = P, colour = ink, size = 2.5) +
    ggplot2::coord_cartesian(xlim = c(0, q_max), ylim = c(0, p_top), expand = FALSE) +
    labs_econ(title = title, subtitle = subtitle, source = source) +
    ggplot2::labs(x = "Quantity", y = "Price") +
    theme_econ(panel = panel, grid = "both") +
    econ_axes(panel)
}
