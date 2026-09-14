## Price schedules -----------------------------------------------------------

#' A unit price that changes with the quantity bought
#'
#' Quantity discounts ("25% off after the second"), block tariffs and
#' rationing all make a good's price depend on how much of it you already
#' have. A price schedule holds the unit price in each tier, and [budget()]
#' accepts one in place of a number, giving a *kinked* budget line.
#'
#' Two ways to build one: the common case as a base price with a discount
#' after a threshold, or the general case as a vector of tier prices and the
#' upper bounds of all but the last tier.
#'
#' @param price Base unit price, or a vector of tier prices when `breaks` is
#'   given.
#' @param discount Fraction off every unit after the first `after` units.
#' @param after Units bought at the base price before the discount applies.
#' @param breaks Upper bound of each tier except the last, which is
#'   unbounded. Must be increasing.
#'
#' @return An object of class `price_schedule`.
#'
#' @details
#' A kinked budget changes what the downstream functions can assume:
#' [budget_line()] traces the frontier through the kinks, [geom_budget()]
#' draws it as a path, and [optimal_bundle()] searches along the frontier
#' numerically instead of using a closed form, since the tangency condition
#' no longer identifies the optimum on its own (the kink itself is a
#' candidate). The marginal rate of substitution is still available from
#' [mrs()], but the budget's `slope` is `NA`.
#'
#' @examples
#' # Paintings $20 each, 25% off after the second
#' paintings <- price_schedule(20, discount = 0.25, after = 2)
#' paintings
#' schedule_cost(paintings, 0:4)      # cumulative cost of 0..4 paintings
#' schedule_quantity(paintings, 100)  # how many $100 buys
#'
#' # The same thing as tiers
#' price_schedule(c(20, 15), breaks = 2)
#'
#' b <- budget(income = 100, px = 10, py = paintings)
#' b
#' budget_line(b, n_points = 5)
#' @export
price_schedule <- function(price, discount = NULL, after = NULL, breaks = NULL) {
  if (!is.null(breaks)) {
    if (!is.null(discount) || !is.null(after)) {
      cli::cli_abort("Give either {.arg discount}/{.arg after} or {.arg breaks}, not both.")
    }
    prices <- check_positive_vector(price)
    if (!is.numeric(breaks) || any(!is.finite(breaks)) || any(breaks <= 0) || is.unsorted(breaks, strictly = TRUE)) {
      cli::cli_abort("{.arg breaks} must be increasing positive numbers.")
    }
    if (length(prices) != length(breaks) + 1L) {
      cli::cli_abort("{.arg price} needs one more entry than {.arg breaks} ({length(breaks) + 1}).")
    }
  } else {
    check_positive(price)
    if (is.null(discount) || is.null(after)) {
      cli::cli_abort("Give {.arg discount} and {.arg after}, or {.arg breaks}.")
    }
    check_unit_interval(discount)
    check_positive(after)
    prices <- c(price, price * (1 - discount))
    breaks <- after
  }
  structure(list(prices = prices, breaks = c(breaks, Inf)), class = "price_schedule")
}

#' @export
print.price_schedule <- function(x, ...) {
  cat(format_price(x), "\n")
  invisible(x)
}

#' A numeric price or a schedule, normalised
#' @noRd
as_price <- function(p, arg = rlang::caller_arg(p)) {
  if (inherits(p, "price_schedule")) return(p)
  check_positive(p, arg = arg)
}

#' @noRd
format_price <- function(p) {
  if (!inherits(p, "price_schedule")) return(format(p))
  tiers <- character(length(p$prices))
  lower <- c(0, utils::head(p$breaks, -1))
  for (i in seq_along(tiers)) {
    upper <- p$breaks[i]
    range <- if (is.infinite(upper)) sprintf("beyond %s", format(lower[i])) else sprintf("up to %s", format(upper))
    tiers[i] <- sprintf("%s %s", format(p$prices[i]), range)
  }
  paste0("<price schedule: ", paste(tiers, collapse = "; "), ">")
}

#' Cumulative cost of q units under a schedule (or a flat price)
#'
#' @return A numeric vector the length of `q`.
#' @rdname price_schedule
#' @param schedule A `price_schedule`, or a plain price.
#' @param q Quantities.
#' @export
schedule_cost <- function(schedule, q) {
  check_quantity(q)
  if (!inherits(schedule, "price_schedule")) return(schedule * q)
  lower <- c(0, utils::head(schedule$breaks, -1))
  vapply(q, function(qq) {
    units <- pmax(pmin(qq, schedule$breaks) - lower, 0)
    sum(units * schedule$prices)
  }, numeric(1))
}

#' Largest quantity a given spend buys under a schedule
#'
#' @rdname price_schedule
#' @param spend Money available.
#' @export
schedule_quantity <- function(schedule, spend) {
  check_quantity(spend)
  if (!inherits(schedule, "price_schedule")) return(spend / schedule)
  lower <- c(0, utils::head(schedule$breaks, -1))
  tier_cost <- (schedule$breaks - lower) * schedule$prices     # Inf for the last tier
  vapply(spend, function(s) {
    left <- s
    for (i in seq_along(schedule$prices)) {
      if (left <= tier_cost[i]) return(lower[i] + left / schedule$prices[i])
      left <- left - tier_cost[i]
    }
    schedule$breaks[length(schedule$breaks)]
  }, numeric(1))
}

#' Unit price of the k-th unit
#' @noRd
marginal_price <- function(schedule, k) {
  if (!inherits(schedule, "price_schedule")) return(rep_len(schedule, length(k)))
  vapply(k, function(kk) schedule$prices[which(kk <= schedule$breaks)[1]], numeric(1))
}

#' The frontier of a kinked budget, through every kink
#' @noRd
kinked_budget_line <- function(b, n_points) {
  # Parametrise by y: for each y, x is the most the leftover money buys.
  ys <- seq(0, b$y_max, length.out = n_points)
  kinks_y <- if (inherits(b$py, "price_schedule")) b$py$breaks[is.finite(b$py$breaks)] else numeric(0)
  if (inherits(b$px, "price_schedule")) {
    # y at which x reaches each of its own breaks
    for (bx in b$px$breaks[is.finite(b$px$breaks)]) {
      leftover <- b$income - schedule_cost(b$px, bx)
      if (leftover > 0) kinks_y <- c(kinks_y, schedule_quantity(b$py, leftover))
    }
  }
  ys <- sort(unique(c(ys, kinks_y[kinks_y > 0 & kinks_y < b$y_max])), decreasing = TRUE)
  xs <- schedule_quantity(b$px, pmax(b$income - schedule_cost(b$py, ys), 0))
  data.frame(x = xs, y = ys)
}

#' Best bundle on a kinked frontier, for smooth preferences
#' @noRd
optimal_bundle_kinked <- function(u, b) {
  along <- function(y) {
    x <- schedule_quantity(b$px, pmax(b$income - schedule_cost(b$py, y), 0))
    u(x, y)
  }
  # Coarse scan (the frontier is only piecewise smooth), then polish the best
  # bracket, then compare with the kinks and endpoints explicitly.
  grid <- seq(0, b$y_max, length.out = 400)
  vals <- vapply(grid, along, numeric(1))
  vals[!is.finite(vals)] <- -Inf
  i <- which.max(vals)
  lo <- grid[max(i - 1L, 1L)]
  hi <- grid[min(i + 1L, length(grid))]
  polished <- if (hi > lo) stats::optimize(along, c(lo, hi), maximum = TRUE, tol = 1e-10)$maximum else grid[i]
  candidates <- c(polished, 0, b$y_max, kinked_budget_line(b, 2L)$y)
  candidates <- candidates[candidates >= 0 & candidates <= b$y_max]
  scores <- vapply(candidates, along, numeric(1))
  scores[!is.finite(scores)] <- -Inf
  y <- candidates[which.max(scores)]
  x <- schedule_quantity(b$px, pmax(b$income - schedule_cost(b$py, y), 0))
  data.frame(x = x, y = y, utility = u(x, y))
}

## Utility tables ------------------------------------------------------------

#' Preferences given as a total-utility table
#'
#' The introductory-course setup: a table of total utility from 1, 2, 3, ...
#' units of each good, with utility additive across goods. Rationality then
#' means choosing the affordable *whole-unit* bundle with the highest total
#' utility -- the rule "spend each dollar where it buys the most utility" --
#' and [optimal_bundle()] does exactly that search. [indifference_curve()]
#' interpolates the table so the curves can be drawn; [mu_per_dollar()] lays
#' out the purchase order the textbook argument walks through.
#'
#' @param tu_x,tu_y Total utility from 1, 2, ..., n units of each good.
#'   Utility from zero units is zero. Need not be concave, but the
#'   marginal-utility-per-dollar rule only reproduces the optimum when it
#'   is.
#' @param goods Names for the two goods, used in [mu_per_dollar()] output.
#'
#' @return A function of `x` and `y` of class `utility_table`, evaluating
#'   total utility at any (interpolated) quantities, with the tables and
#'   ranges as attributes.
#'
#' @examples
#' u <- utility_table(tu_x = c(20, 37, 50, 60, 65),   # movies
#'                    tu_y = c(16, 30, 40, 46, 48),   # bags of popcorn
#'                    goods = c("movies", "popcorn"))
#' u
#' u(3, 4)
#'
#' b <- budget(income = 35, px = 7.5, py = 3)
#' optimal_bundle(u, b)          # 3 movies, 4 bags
#' mu_per_dollar(u, b)           # the purchase order
#' plot_consumer_choice(u, b, goods = c("Movies", "Popcorn"))
#' @export
utility_table <- function(tu_x, tu_y, goods = c("x", "y")) {
  for (v in list(tu_x, tu_y)) {
    if (!is.numeric(v) || length(v) < 1L || any(!is.finite(v)) || any(diff(c(0, v)) < 0)) {
      cli::cli_abort("{.arg tu_x} and {.arg tu_y} must be non-decreasing total utilities from 1, 2, ... units.")
    }
  }
  if (!is.character(goods) || length(goods) != 2L) {
    cli::cli_abort("{.arg goods} must be two names.")
  }
  tx <- c(0, tu_x)
  ty <- c(0, tu_y)
  fx <- stats::approxfun(seq_along(tx) - 1, tx, rule = 1)
  fy <- stats::approxfun(seq_along(ty) - 1, ty, rule = 1)
  f <- function(x, y) fx(x) + fy(y)
  structure(f, class = c("utility_table", "function"),
            tu_x = tx, tu_y = ty, n_x = length(tu_x), n_y = length(tu_y),
            goods = goods, kind = "utility")
}

#' @export
print.utility_table <- function(x, ...) {
  g <- attr(x, "goods")
  cat(sprintf("<Utility table: %s (up to %d) and %s (up to %d), additive>\n",
              g[1], attr(x, "n_x"), g[2], attr(x, "n_y")))
  tab <- data.frame(units = seq_len(max(attr(x, "n_x"), attr(x, "n_y"))))
  tab[[g[1]]] <- c(attr(x, "tu_x")[-1], rep(NA, nrow(tab) - attr(x, "n_x")))
  tab[[g[2]]] <- c(attr(x, "tu_y")[-1], rep(NA, nrow(tab) - attr(x, "n_y")))
  print(tab, row.names = FALSE)
  invisible(x)
}

#' @rdname indifference_curve
#' @export
indifference_curve.utility_table <- function(u, level, x, ...) {
  ty <- attr(u, "tu_y")
  tx <- attr(u, "tu_x")
  fx <- stats::approxfun(seq_along(tx) - 1, tx, rule = 1)
  inv_y <- stats::approxfun(ty, seq_along(ty) - 1, rule = 1, ties = "ordered")
  rows <- lapply(level, function(lv) {
    y <- inv_y(lv - fx(x))
    data.frame(x = x, y = y, level = lv)
  })
  do.call(rbind, rows)
}

#' @rdname optimal_bundle
#' @export
optimal_bundle.utility_table <- function(u, b, ...) {
  grid <- expand.grid(x = 0:attr(u, "n_x"), y = 0:attr(u, "n_y"))
  grid$cost <- b$cost_x(grid$x) + b$cost_y(grid$y)
  grid <- grid[grid$cost <= b$income + 1e-9, , drop = FALSE]
  grid$utility <- u(grid$x, grid$y)
  best <- grid[order(-grid$utility, grid$cost), ][1, ]
  data.frame(x = best$x, y = best$y, utility = best$utility)
}

#' @rdname mrs
#' @export
mrs.utility_table <- function(u, x, y, ...) {
  v <- recycle2(x, y)
  tx <- attr(u, "tu_x")
  ty <- attr(u, "tu_y")
  mu <- function(t, q) {
    q <- pmin(pmax(round(q), 1), length(t) - 1)
    t[q + 1] - t[q]
  }
  mu(tx, v$x) / mu(ty, v$y)
}

#' The marginal-utility-per-dollar purchase order
#'
#' Lists every unit of both goods in the order a rational consumer buys them
#' -- highest marginal utility per dollar first -- with the running total
#' spent, so the answer to "what do I buy with $35?" is read off where the
#' cumulative cost passes the income. This is the argument the introductory
#' course makes; [optimal_bundle()] reaches the same bundle by exhaustive
#' search, and the two agree whenever marginal utility is diminishing.
#'
#' @param u A [utility_table()].
#' @param b A [budget()]; prices may be [price_schedule()]s, in which case
#'   each unit is priced at its own tier.
#'
#' The order is the textbook's constrained greedy: at each step buy the
#' next unit of whichever good gives more utility per dollar, never skipping
#' ahead within a good, and stop at the first unit the income cannot cover.
#' That rule finds the optimum only when marginal utility is diminishing and
#' the income is spent exactly; otherwise (a table that is not concave, or
#' leftover cash that would have bought a cheaper unit further down the
#' list) the affordable set can differ from [optimal_bundle()]. When it does,
#' a warning is issued and the result carries a `note` attribute saying so.
#'
#' @return A data frame with one row per unit: `good`, `unit`, `price`,
#'   `mu`, `mu_per_dollar`, `cumulative_cost`, `affordable`.
#'
#' @examples
#' u <- utility_table(c(20, 37, 50, 60, 65), c(16, 30, 40, 46, 48),
#'                    goods = c("movies", "popcorn"))
#' mu_per_dollar(u, budget(35, px = 7.5, py = 3))
#' @export
mu_per_dollar <- function(u, b) {
  if (!inherits(u, "utility_table")) {
    cli::cli_abort("{.arg u} must be a {.fn utility_table}.")
  }
  if (!inherits(b, "budget")) {
    cli::cli_abort("{.arg b} must be a {.fn budget} object.")
  }
  g <- attr(u, "goods")
  units_x <- seq_len(attr(u, "n_x"))
  units_y <- seq_len(attr(u, "n_y"))
  out <- rbind(
    data.frame(good = g[1], unit = units_x, price = marginal_price(b$px, units_x),
               mu = diff(attr(u, "tu_x")), stringsAsFactors = FALSE),
    data.frame(good = g[2], unit = units_y, price = marginal_price(b$py, units_y),
               mu = diff(attr(u, "tu_y")), stringsAsFactors = FALSE)
  )
  out$mu_per_dollar <- out$mu / out$price
  # Constrained greedy: units of a good are bought in order, so at each step
  # only the *next* unit of each good is a candidate. A global sort by value
  # per dollar is not the same thing -- it lets a cheap-looking later unit
  # pull its predecessors forward.
  ix <- which(out$good == g[1])
  iy <- which(out$good == g[2])
  pick <- integer(0)
  i <- 1L
  j <- 1L
  while (i <= length(ix) || j <= length(iy)) {
    take_x <- if (i > length(ix)) {
      FALSE
    } else if (j > length(iy)) {
      TRUE
    } else {
      out$mu_per_dollar[ix[i]] >= out$mu_per_dollar[iy[j]]
    }
    if (take_x) {
      pick <- c(pick, ix[i]); i <- i + 1L
    } else {
      pick <- c(pick, iy[j]); j <- j + 1L
    }
  }
  out <- out[pick, , drop = FALSE]
  out$cumulative_cost <- cumsum(out$price)
  out$affordable <- out$cumulative_cost <= b$income + 1e-9
  rownames(out) <- NULL

  # The greedy rule is only optimal under diminishing marginal utility; say
  # so when it disagrees with the exhaustive search.
  bought <- out[out$affordable, , drop = FALSE]
  greedy <- c(sum(bought$good == g[1]), sum(bought$good == g[2]))
  opt <- optimal_bundle(u, b)
  if (!isTRUE(all.equal(greedy, c(opt$x, opt$y)))) {
    note <- sprintf(
      "the marginal-utility-per-dollar rule buys (%s = %d, %s = %d), but the utility-maximising bundle is (%s = %d, %s = %d); the rule is only guaranteed under diminishing marginal utility with the income spent exactly",
      g[1], greedy[1], g[2], greedy[2], g[1], round(opt$x), g[2], round(opt$y)
    )
    cli::cli_warn(c("!" = "The MU-per-dollar order is not the optimum here.", "i" = note))
    attr(out, "note") <- note
  }
  out
}
