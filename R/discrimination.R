#' Horizontal summation of demand curves
#'
#' The market demand faced by a seller who cannot tell buyer groups apart:
#' at every price, the sum of the quantities each group demands. The inverse
#' is found numerically, so the result is a [demand_fn()] and works anywhere
#' a demand object does -- most usefully as the uniform-price benchmark for
#' [third_degree()].
#'
#' @param demands A list of demand objects.
#'
#' @return A `general_demand` object whose `q_max` is the sum of the parts'.
#'
#' @examples
#' students <- linear_demand(intercept = 60, slope = 0.5)
#' others <- linear_demand(intercept = 100, slope = 1)
#' both <- aggregate_demand(list(students, others))
#' quantity_at(both, 40)   # 40 + 60
#' price_at(both, 100)
#' @export
aggregate_demand <- function(demands) {
  demands <- check_demand_list(demands)
  choke <- max(vapply(demands, function(d) price_at(d, 0), numeric(1)))
  q_total <- function(p) sum(vapply(demands, function(d) quantity_at(d, p), numeric(1)))
  q0 <- q_total(0)
  p_of_q <- function(q) {
    vapply(q, function(qq) {
      if (qq <= 0) return(choke)
      if (qq >= q0) return(0)
      stats::uniroot(function(p) q_total(p) - qq, c(0, choke), tol = 1e-10)$root
    }, numeric(1))
  }
  out <- demand_fn(p_of_q, q_max = q0)
  # The price-to-quantity direction is the cheap one here; keep it so
  # quantity_at() can answer directly instead of inverting p_of_q, which
  # would put a root-find inside a root-find.
  out$q_of_p <- function(p) vapply(p, q_total, numeric(1))
  out
}

#' @noRd
check_demand_list <- function(demands, arg = rlang::caller_arg(demands)) {
  if (inherits(demands, "demand")) {
    demands <- list(demands)
  }
  if (!is.list(demands) || length(demands) == 0L ||
      !all(vapply(demands, inherits, logical(1), what = "demand"))) {
    cli::cli_abort("{.arg {arg}} must be a demand object or a list of them.")
  }
  # Name every unnamed element, not just a wholly unnamed list: a partially
  # named list has names() of c("a", ""), and a blank name breaks the
  # name-based lookups downstream.
  nm <- names(demands)
  if (is.null(nm)) nm <- character(length(demands))
  blank <- is.na(nm) | !nzchar(nm)
  nm[blank] <- paste0("segment_", seq_along(demands))[blank]
  if (anyDuplicated(nm)) {
    cli::cli_abort("{.arg {arg}} has duplicated names: {.val {nm[duplicated(nm)]}}.")
  }
  names(demands) <- nm
  demands
}

#' Price discrimination
#'
#' What a monopolist does with more than one price.
#'
#' `first_degree()` is perfect discrimination: every unit sells at the
#' buyer's willingness to pay, so the seller keeps producing until price
#' equals marginal cost -- the efficient quantity, with no deadweight loss --
#' and takes the entire surplus. There is no single price; `price` in the
#' result is the price of the last unit, \eqn{P(Q) = MC}.
#'
#' `third_degree()` is segmentation: separate groups with their own demand
#' curves, one marginal cost, and no resale between them. The seller
#' equates marginal revenue across groups to the common marginal cost,
#' \eqn{MR_i(Q_i) = MC(\sum Q_i)}, which by the inverse-elasticity rule means
#' the less elastic group pays more. The result also carries the
#' uniform-price benchmark, [monopoly()] on the [aggregate_demand()], so the
#' gain from segmenting is explicit.
#'
#' @param demand A demand object.
#' @param demands A list of demand objects, one per segment. Names, if
#'   given, label the segments.
#' @param cost A cost object.
#'
#' @return `first_degree()` returns a `market_outcome` (see
#'   [market_structure]). `third_degree()` returns an object of class
#'   `third_degree`: a list with `segments` (a data frame: `segment`,
#'   `price`, `quantity`, `elasticity`, `lerner`, `revenue`), `quantity`,
#'   `marginal_cost`, `profit`, and `uniform` (the `market_outcome` under a
#'   single price).
#'
#' @examples
#' d <- linear_demand(intercept = 100, slope = 1)
#' cst <- quadratic_cost(a = 20)
#'
#' first_degree(d, cst)     # Q = 80, all 3200 of surplus to the seller
#' monopoly(d, cst)         # for comparison: Q = 40, deadweight loss 800
#'
#' students <- linear_demand(intercept = 60, slope = 0.5)
#' third_degree(list(students = students, others = d), cst)
#' @name price_discrimination
NULL

#' @rdname price_discrimination
#' @export
first_degree <- function(demand, cost) {
  check_demand(demand)
  check_cost(cost)
  Q <- efficient_quantity(demand, cost, n = 1)
  # Producer surplus is the whole area between demand and marginal cost.
  ps <- if (Q > 0) {
    stats::integrate(function(q) price_at(demand, q) - marginal_cost(cost, q), 0, Q)$value
  } else {
    0
  }
  market_outcome(
    "first-degree discrimination", demand, cost, n = 1, q_firm = Q,
    price = price_at(demand, Q), consumer_surplus = 0, producer_surplus = ps,
    note = "price is that of the last unit; earlier units sold at willingness to pay"
  )
}

#' Quantity at which a segment's marginal revenue equals m
#' @noRd
quantity_at_mr <- function(d, m) {
  maximise_on(function(q) marginal_revenue(d, q) - m, d$q_max)
}

#' @rdname price_discrimination
#' @export
third_degree <- function(demands, cost) {
  demands <- check_demand_list(demands)
  check_cost(cost)

  total_at <- function(m) sum(vapply(demands, quantity_at_mr, numeric(1), m = m))
  choke <- max(vapply(demands, function(d) price_at(d, 0), numeric(1)))
  # Total quantity falls as the common marginal-revenue level m rises, so
  # MC(Q(m)) - m usually falls through zero once. Not always: with falling
  # marginal cost (increasing returns) it can dip below zero and come back,
  # so bracket the crossing the same way the other structures do.
  gap <- function(m) marginal_cost(cost, total_at(m)) - m
  m <- find_crossing(gap, choke)

  q <- vapply(demands, quantity_at_mr, numeric(1), m = m)
  p <- mapply(function(d, qq) price_at(d, qq), demands, q)
  Q <- sum(q)
  mc <- marginal_cost(cost, Q)
  segments <- data.frame(
    segment = names(demands),
    price = unname(p),
    quantity = unname(q),
    elasticity = mapply(function(d, qq) if (qq > 0) elasticity(d, qq) else NA_real_, demands, q),
    lerner = ifelse(p > 0, (p - mc) / p, NA_real_),
    revenue = unname(p * q),
    stringsAsFactors = FALSE
  )
  rownames(segments) <- NULL

  structure(
    list(
      segments = segments,
      quantity = Q,
      marginal_cost = mc,
      profit = sum(p * q) - total_cost(cost, Q),
      uniform = monopoly(aggregate_demand(demands), cost),
      demands = demands,
      cost = cost
    ),
    class = "third_degree"
  )
}

#' @export
print.third_degree <- function(x, ...) {
  fmt <- fmt_num
  cat("<Third-degree price discrimination>\n")
  s <- x$segments
  for (i in seq_len(nrow(s))) {
    cat(sprintf("  %-12s price %s, quantity %s, elasticity %s\n",
                s$segment[i], fmt(s$price[i]), fmt(s$quantity[i]), fmt(s$elasticity[i])))
  }
  cat(sprintf("  total quantity %s at marginal cost %s; profit %s\n",
              fmt(x$quantity), fmt(x$marginal_cost), fmt(x$profit)))
  u <- x$uniform
  cat(sprintf("  uniform price instead: price %s, quantity %s, profit %s\n",
              fmt(u$price), fmt(u$quantity), fmt(u$profit_firm)))
  invisible(x)
}

#' Two-part tariffs
#'
#' A seller who charges an entry fee plus a per-unit price. With identical
#' consumers the answer is Disneyland's: set the price at marginal cost and
#' the fee at the whole of each consumer's surplus, which replicates
#' [first_degree()] profit with only two numbers.
#'
#' With different types of consumer the seller faces a trade-off. Serving
#' everyone means pinning the fee to the *lowest* type's surplus, which
#' pushes the optimal price above marginal cost so the higher types pay
#' more through the per-unit charge. Alternatively the seller can exclude
#' the low types and take the high types' full surplus. `two_part_tariff()`
#' evaluates every "serve this type and above" cut-off, optimises the price
#' for each, and returns the most profitable.
#'
#' @param demands A demand object (one consumer type), or a list of them,
#'   one per type, each describing a single consumer's demand.
#' @param cost A cost object.
#' @param n Number of consumers of each type. Recycled to the number of
#'   types.
#'
#' @return An object of class `two_part_tariff`: a list with `price`, `fee`,
#'   `served` (logical, per type), `types` (a data frame: `type`, `n`,
#'   `served`, `quantity` per consumer, `surplus` per consumer after the
#'   fee), `quantity` (total), `profit`, `marginal_cost`, and `candidates`
#'   (the profit of each cut-off considered).
#'
#' @seealso [plot_two_part_tariff()].
#'
#' @examples
#' d <- linear_demand(intercept = 100, slope = 1)
#' cst <- quadratic_cost(a = 20)
#'
#' two_part_tariff(d, cst)                    # p = 20, fee = 3200
#'
#' light <- linear_demand(intercept = 60, slope = 1)
#' two_part_tariff(list(light = light, heavy = d), cst, n = c(5, 1))  # serve both, p > MC
#' two_part_tariff(list(light = light, heavy = d), cst, n = c(1, 1))  # exclude light users
#' @export
two_part_tariff <- function(demands, cost, n = 1) {
  demands <- check_demand_list(demands)
  check_cost(cost)
  n <- check_positive_vector(n)
  if (length(n) != 1L && length(n) != length(demands)) {
    cli::cli_abort("{.arg n} must have one entry, or one per type.")
  }
  n <- rep_len(n, length(demands))
  k <- length(demands)

  # Order types by surplus at marginal cost, lowest first: a fee pinned to a
  # type's surplus serves that type and every type above it.
  mc0 <- marginal_cost(cost, 0)
  base_surplus <- vapply(demands, function(d) consumer_surplus(d, quantity_at(d, mc0)), numeric(1))
  ord <- order(base_surplus)

  profit_at <- function(p, served) {
    q <- vapply(demands, quantity_at, numeric(1), p = p)
    fee <- min(vapply(demands[served], function(d) consumer_surplus(d, quantity_at(d, p)), numeric(1)))
    Q <- sum(n[served] * q[served])
    fee * sum(n[served]) + p * Q - total_cost(cost, Q)
  }

  candidates <- lapply(seq_len(k), function(i) {
    served <- seq_along(demands) %in% ord[i:k]
    p_top <- min(vapply(demands[served], function(d) price_at(d, 0), numeric(1)))
    opt <- stats::optimize(function(p) -profit_at(p, served), c(0, p_top), tol = 1e-9)
    # optimize() cannot land exactly on marginal cost, which is the answer
    # in the identical-consumer case; check it explicitly, and let it win
    # any tie within rounding -- on some platforms the search stops a few
    # 1e-7 away with a profit larger by 1e-9, which is noise, not a result.
    p_mc <- min(max(mc0, 0), p_top)
    at_mc <- profit_at(p_mc, served)
    if (at_mc >= -opt$objective - 1e-8 * max(1, abs(at_mc))) {
      list(served = served, price = p_mc, profit = at_mc)
    } else {
      list(served = served, price = opt$minimum, profit = -opt$objective)
    }
  })
  profits <- vapply(candidates, function(cc) cc$profit, numeric(1))
  best <- candidates[[which.max(profits)]]

  p <- best$price
  served <- best$served
  q <- vapply(demands, quantity_at, numeric(1), p = p)
  surplus <- vapply(demands, function(d) consumer_surplus(d, quantity_at(d, p)), numeric(1))
  fee <- min(surplus[served])
  Q <- sum(n[served] * q[served])

  structure(
    list(
      price = p,
      fee = fee,
      served = served,
      types = data.frame(
        type = names(demands),
        n = n,
        served = served,
        quantity = ifelse(served, q, 0),
        surplus = ifelse(served, surplus - fee, 0),
        stringsAsFactors = FALSE
      ),
      quantity = Q,
      profit = best$profit,
      marginal_cost = marginal_cost(cost, Q),
      candidates = data.frame(
        lowest_served = names(demands)[ord],
        price = vapply(candidates, function(cc) cc$price, numeric(1)),
        profit = profits,
        stringsAsFactors = FALSE
      ),
      demands = demands,
      cost = cost
    ),
    class = "two_part_tariff"
  )
}

#' @export
print.two_part_tariff <- function(x, ...) {
  fmt <- fmt_num
  cat(sprintf("<Two-part tariff>\n  fee %s, price per unit %s (marginal cost %s)\n",
              fmt(x$fee), fmt(x$price), fmt(x$marginal_cost)))
  t <- x$types
  for (i in seq_len(nrow(t))) {
    cat(sprintf("  %-12s n = %s, %s\n", t$type[i], fmt(t$n[i]),
                if (t$served[i]) sprintf("buys %s, surplus after fee %s", fmt(t$quantity[i]), fmt(t$surplus[i]))
                else "not served"))
  }
  cat(sprintf("  total quantity %s, profit %s\n", fmt(x$quantity), fmt(x$profit)))
  invisible(x)
}

#' Draw a two-part tariff
#'
#' One served consumer's demand curve, the per-unit price, the quantity
#' bought, and the fee as the shaded surplus above the price. With several
#' types the type whose surplus pins the fee is drawn, and any surplus a
#' higher type keeps is left unshaded.
#'
#' @param tariff A `two_part_tariff` from [two_part_tariff()].
#' @param type Which served type to draw; defaults to the one that sets the
#'   fee.
#' @param title,subtitle,source Passed to [labs_econ()]; sensible defaults
#'   are filled in.
#' @param panel Passed to [theme_econ()].
#'
#' @return A ggplot object. Add [econ_masthead()] last if you want the block.
#'
#' @examples
#' d <- linear_demand(intercept = 100, slope = 1)
#' plot_two_part_tariff(two_part_tariff(d, quadratic_cost(a = 20)))
#' @export
plot_two_part_tariff <- function(tariff, type = NULL,
                                 title = NULL, subtitle = NULL, source = NULL,
                                 panel = "blue") {
  if (!inherits(tariff, "two_part_tariff")) {
    cli::cli_abort("{.arg tariff} must come from {.fn two_part_tariff}.")
  }
  t <- tariff$types
  if (is.null(type)) {
    served <- which(t$served)
    type <- t$type[served][which.min(t$surplus[served])]
  }
  if (!type %in% t$type[t$served]) {
    cli::cli_abort("{.arg type} must name a served type: {.val {t$type[t$served]}}.")
  }
  d <- tariff$demands[[type]]
  p <- tariff$price
  q <- quantity_at(d, p)
  choke <- price_at(d, 0)
  ink <- unname(econ_hex["ink"])

  grid <- seq(0, d$q_max, length.out = 300)
  curve <- data.frame(q = grid, p = price_at(d, grid))
  fee_area <- data.frame(q = seq(0, q, length.out = 120))
  fee_area$ymax <- price_at(d, fee_area$q)
  fee_area$ymin <- p

  if (is.null(title)) title <- "Pay to enter, then pay per unit"
  if (is.null(subtitle)) {
    subtitle <- sprintf("Fee %s plus %s per unit; marginal cost %s",
                        format(signif(tariff$fee, 4)), format(signif(p, 4)),
                        format(signif(tariff$marginal_cost, 4)))
  }

  ggplot2::ggplot() +
    ggplot2::geom_ribbon(
      data = fee_area,
      ggplot2::aes(x = .data$q, ymin = .data$ymin, ymax = .data$ymax),
      fill = unname(econ_hex["blue"]), alpha = 0.25
    ) +
    ggplot2::annotate("text", x = q * 0.3, y = (price_at(d, q * 0.3) + p) / 2,
                      label = "Fee = surplus\nat the unit price", size = 3,
                      colour = unname(econ_hex["blue"]), fontface = "bold") +
    ggplot2::geom_line(data = curve, ggplot2::aes(x = .data$q, y = .data$p),
                       colour = unname(econ_hex["blue"]), linewidth = 0.8) +
    ggplot2::geom_hline(yintercept = tariff$marginal_cost, colour = unname(econ_hex["red"]),
                        linewidth = 0.6, linetype = if (p > tariff$marginal_cost) "dashed" else "solid") +
    ggplot2::annotate("segment", x = 0, xend = q, y = p, yend = p, colour = ink, linewidth = 0.5) +
    ggplot2::annotate("segment", x = q, xend = q, y = 0, yend = p, colour = ink,
                      linewidth = 0.4, linetype = "dotted") +
    ggplot2::annotate("point", x = q, y = p, colour = ink, size = 2.5) +
    ggplot2::annotate("text", x = d$q_max, y = tariff$marginal_cost, label = "Marginal cost",
                      hjust = 1, vjust = -0.5, size = 3, colour = ink) +
    ggplot2::annotate("text", x = q, y = p, label = "Unit price", hjust = -0.15, vjust = -0.5,
                      size = 3, colour = ink) +
    ggplot2::coord_cartesian(xlim = c(0, d$q_max), ylim = c(0, choke * 1.08), expand = FALSE) +
    labs_econ(title = title, subtitle = subtitle, source = source) +
    ggplot2::labs(x = sprintf("Quantity per %s consumer", type), y = "Price") +
    theme_econ(panel = panel, grid = "both") +
    econ_axes(panel)
}
