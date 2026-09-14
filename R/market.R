## Demand ---------------------------------------------------------------------

#' Market demand
#'
#' The demand side of a market, written as inverse demand \eqn{P(Q)}: the
#' price at which buyers take quantity \eqn{Q}. `linear_demand()` is the
#' textbook \eqn{P = a - bQ} and has closed forms for everything below;
#' `demand_fn()` accepts any decreasing function of `q` and falls back to
#' numerical methods.
#'
#' @param intercept Choke price \eqn{a}: the price at which demand is zero.
#' @param slope \eqn{b}: how fast price falls per unit of quantity. Positive.
#' @param p_of_q A function of one argument returning the price at that
#'   quantity. Must be decreasing.
#' @param q_max The largest quantity worth considering (for example, where
#'   price reaches zero). Numerical searches are confined to `[0, q_max]`.
#'
#' @return An object of class `demand` (and `linear_demand` or
#'   `general_demand`).
#'
#' @seealso [price_at()], [marginal_revenue()], [consumer_surplus()], and the
#'   market structures [monopoly()], [cournot()], [perfect_competition()].
#'
#' @examples
#' d <- linear_demand(intercept = 100, slope = 1)
#' d
#' price_at(d, 40)
#' marginal_revenue(d, 40)
#' elasticity(d, 40)
#'
#' # Constant-elasticity demand, handled numerically
#' ce <- demand_fn(function(q) 400 / sqrt(q + 1), q_max = 1000)
#' marginal_revenue(ce, 15)
#' @name demand
NULL

#' @rdname demand
#' @export
linear_demand <- function(intercept, slope) {
  check_positive(intercept)
  check_positive(slope)
  structure(
    list(intercept = intercept, slope = slope, q_max = intercept / slope),
    class = c("linear_demand", "demand")
  )
}

#' @rdname demand
#' @export
demand_fn <- function(p_of_q, q_max) {
  if (!is.function(p_of_q)) {
    cli::cli_abort("{.arg p_of_q} must be a function of quantity.")
  }
  check_positive(q_max)
  # Everything downstream -- inverting the curve, the marginal-revenue
  # crossings, the surplus integrals -- assumes inverse demand slopes down.
  # Check it on a coarse grid now rather than return plausible nonsense later.
  probe <- p_of_q(seq(0, q_max, length.out = 50))
  if (length(probe) == 1L) probe <- rep(probe, 50)
  if (length(probe) != 50L || any(!is.finite(probe))) {
    cli::cli_abort("{.arg p_of_q} must return one finite price per quantity on [0, q_max].")
  }
  if (any(diff(probe) > 1e-9 * max(1, abs(probe[1])))) {
    cli::cli_abort(c(
      "{.arg p_of_q} must be decreasing in quantity.",
      "x" = "It rises somewhere on [0, {format(q_max)}]."
    ))
  }
  structure(
    list(p_of_q = p_of_q, q_max = q_max),
    class = c("general_demand", "demand")
  )
}

#' @export
print.demand <- function(x, ...) {
  if (inherits(x, "linear_demand")) {
    cat(sprintf("<Linear demand>\n  P = %s - %s * Q   (Q = 0 at P = %s; P = 0 at Q = %s)\n",
                format(x$intercept), format(x$slope), format(x$intercept), format(x$q_max)))
  } else {
    cat(sprintf("<Demand>\n  P = p_of_q(Q) on [0, %s]\n", format(x$q_max)))
  }
  invisible(x)
}

#' @noRd
check_demand <- function(d, arg = rlang::caller_arg(d)) {
  if (!inherits(d, "demand")) {
    cli::cli_abort("{.arg {arg}} must be a demand object from {.fn linear_demand} or {.fn demand_fn}.")
  }
  d
}

#' @noRd
check_quantity <- function(q, arg = rlang::caller_arg(q)) {
  if (!is.numeric(q) || length(q) == 0L || any(!is.finite(q)) || any(q < 0)) {
    cli::cli_abort("{.arg {arg}} must be a numeric vector of non-negative values.")
  }
  q
}

#' Prices, quantities and revenue along a demand curve
#'
#' @param d A demand object from [linear_demand()] or [demand_fn()].
#' @param q Quantity. May be a vector.
#' @param p Price. May be a vector.
#' @param ... Passed on to methods.
#'
#' @return A numeric vector.
#'   * `price_at()` -- the price at which `q` is demanded (inverse demand).
#'   * `quantity_at()` -- the quantity demanded at price `p`.
#'   * `marginal_revenue()` -- \eqn{P(q) + q P'(q)}, the extra revenue from
#'     one more unit when the price must fall to sell it.
#'   * `elasticity()` -- the price elasticity of demand at `q`,
#'     \eqn{(dQ/dP)(P/Q)}; negative, and below \eqn{-1} where demand is
#'     elastic.
#'   * `consumer_surplus()` -- the area under the demand curve and above the
#'     price, up to `q`.
#'
#' @examples
#' d <- linear_demand(intercept = 100, slope = 1)
#' price_at(d, c(0, 40, 100))
#' quantity_at(d, 60)
#' marginal_revenue(d, 40)      # 100 - 2 * 40
#' elasticity(d, c(20, 50, 80)) # elastic above the midpoint
#' consumer_surplus(d, 40)
#' @name demand_curve_values
NULL

#' @rdname demand_curve_values
#' @export
price_at <- function(d, q, ...) {
  check_demand(d)
  check_quantity(q)
  UseMethod("price_at")
}

#' @export
price_at.linear_demand <- function(d, q, ...) {
  pmax(d$intercept - d$slope * q, 0)
}

#' @export
price_at.general_demand <- function(d, q, ...) {
  pmax(d$p_of_q(q), 0)
}

#' @rdname demand_curve_values
#' @export
quantity_at <- function(d, p, ...) {
  check_demand(d)
  check_quantity(p)
  UseMethod("quantity_at")
}

#' @export
quantity_at.linear_demand <- function(d, p, ...) {
  pmax((d$intercept - p) / d$slope, 0)
}

#' @export
quantity_at.general_demand <- function(d, p, ...) {
  if (is.function(d$q_of_p)) {
    return(pmax(d$q_of_p(p), 0))
  }
  vapply(p, function(pp) {
    if (pp >= price_at(d, 0)) return(0)
    if (pp <= price_at(d, d$q_max)) return(d$q_max)
    stats::uniroot(function(q) price_at(d, q) - pp, c(0, d$q_max), tol = 1e-10)$root
  }, numeric(1))
}

#' Slope of inverse demand, dP/dQ
#' @noRd
demand_slope <- function(d, q) {
  if (inherits(d, "linear_demand")) {
    return(rep_len(-d$slope, length(q)))
  }
  numeric_derivative(function(qq) price_at(d, qq))(q)
}

#' @rdname demand_curve_values
#' @export
marginal_revenue <- function(d, q, ...) {
  check_demand(d)
  check_quantity(q)
  UseMethod("marginal_revenue")
}

#' @export
marginal_revenue.linear_demand <- function(d, q, ...) {
  d$intercept - 2 * d$slope * q
}

#' @export
marginal_revenue.general_demand <- function(d, q, ...) {
  price_at(d, q) + q * demand_slope(d, q)
}

#' @rdname demand_curve_values
#' @export
elasticity <- function(d, q, ...) {
  check_demand(d)
  check_quantity(q)
  p <- price_at(d, q)
  (1 / demand_slope(d, q)) * (p / q)
}

#' @rdname demand_curve_values
#' @export
consumer_surplus <- function(d, q, ...) {
  check_demand(d)
  check_quantity(q)
  UseMethod("consumer_surplus")
}

#' @export
consumer_surplus.linear_demand <- function(d, q, ...) {
  q <- pmin(q, d$q_max)
  0.5 * d$slope * q^2
}

#' @export
consumer_surplus.general_demand <- function(d, q, ...) {
  vapply(q, function(qq) {
    if (qq == 0) return(0)
    area <- stats::integrate(function(x) price_at(d, x), 0, qq)$value
    area - price_at(d, qq) * qq
  }, numeric(1))
}

## Cost ----------------------------------------------------------------------

#' A firm's cost function
#'
#' `quadratic_cost()` is the textbook \eqn{C(q) = F + a q + b q^2}: constant
#' marginal cost when `b = 0`, rising marginal cost otherwise, and a U-shaped
#' average cost whenever both `fixed` and `b` are positive.
#' `production_cost()` derives the cost function from a production function
#' and input prices through [expenditure()], so the market module can sit
#' directly on the producer-theory one.
#'
#' @param fixed Fixed cost. Non-negative.
#' @param a Linear coefficient: marginal cost at zero output. Non-negative.
#' @param b Quadratic coefficient. Non-negative.
#' @param f A production function of `x` and `y`.
#' @param w,r Input prices.
#'
#' @return An object of class `cost` (and `quadratic_cost` or
#'   `production_cost`).
#'
#' @seealso [total_cost()] and friends; [monopoly()], [cournot()],
#'   [perfect_competition()].
#'
#' @examples
#' cst <- quadratic_cost(fixed = 100, a = 20, b = 0.5)
#' cst
#' marginal_cost(cst, 10)
#' min_average_cost(cst)
#'
#' pc <- production_cost(cobb_douglas(0.3, 0.5, kind = "production"), w = 20, r = 30)
#' total_cost(pc, 10)
#' @name cost
NULL

#' @rdname cost
#' @export
quadratic_cost <- function(fixed = 0, a = 0, b = 0) {
  check_positive(fixed, zero_ok = TRUE)
  check_positive(a, zero_ok = TRUE)
  check_positive(b, zero_ok = TRUE)
  if (a == 0 && b == 0) {
    cli::cli_abort("At least one of {.arg a} and {.arg b} must be positive.")
  }
  structure(list(fixed = fixed, a = a, b = b), class = c("quadratic_cost", "cost"))
}

#' @rdname cost
#' @export
production_cost <- function(f, w, r, fixed = 0) {
  if (!is.function(f)) {
    cli::cli_abort("{.arg f} must be a function of {.arg x} and {.arg y}.")
  }
  check_positive(w)
  check_positive(r)
  check_positive(fixed, zero_ok = TRUE)
  structure(list(f = f, w = w, r = r, fixed = fixed),
            class = c("production_cost", "cost"))
}

#' @export
print.cost <- function(x, ...) {
  if (inherits(x, "quadratic_cost")) {
    cat(sprintf("<Quadratic cost>\n  C(q) = %s + %s * q + %s * q^2\n",
                format(x$fixed), format(x$a), format(x$b)))
  } else {
    cat(sprintf("<Cost from production>\n  C(q) = %s + expenditure(f, w = %s, r = %s, q)\n",
                format(x$fixed), format(x$w), format(x$r)))
  }
  invisible(x)
}

#' @noRd
check_cost <- function(cst, arg = rlang::caller_arg(cst)) {
  if (!inherits(cst, "cost")) {
    cli::cli_abort("{.arg {arg}} must be a cost object from {.fn quadratic_cost} or {.fn production_cost}.")
  }
  cst
}

#' Cost at a level of output
#'
#' @param cost A cost object from [quadratic_cost()] or [production_cost()].
#' @param q Output. May be a vector.
#' @param q_max Upper bound for the numerical search in
#'   `min_average_cost()`; only needed for a [production_cost()].
#' @param ... Passed on to methods.
#'
#' @return A numeric vector, except `min_average_cost()`, which returns a
#'   list with the output `q` at which average cost is lowest and the average
#'   cost `ac` there. For a [quadratic_cost()] with no fixed cost or no
#'   quadratic term average cost has no interior minimum; `q` is then `NA`
#'   and `ac` the limiting value.
#'
#' @examples
#' cst <- quadratic_cost(fixed = 100, a = 20, b = 0.5)
#' total_cost(cst, c(0, 10, 20))
#' marginal_cost(cst, 10)     # 20 + 2 * 0.5 * 10
#' average_cost(cst, 10)
#' min_average_cost(cst)       # q = sqrt(F / b)
#' @name cost_values
NULL

#' @rdname cost_values
#' @export
total_cost <- function(cost, q, ...) {
  check_cost(cost)
  check_quantity(q)
  UseMethod("total_cost")
}

#' @export
total_cost.quadratic_cost <- function(cost, q, ...) {
  cost$fixed + cost$a * q + cost$b * q^2
}

#' @export
total_cost.production_cost <- function(cost, q, ...) {
  out <- rep(cost$fixed, length(q))
  pos <- q > 0
  if (any(pos)) {
    out[pos] <- out[pos] + expenditure(cost$f, cost$w, cost$r, q[pos])
  }
  out
}

#' @rdname cost_values
#' @export
variable_cost <- function(cost, q, ...) {
  total_cost(cost, q, ...) - cost$fixed
}

#' @rdname cost_values
#' @export
marginal_cost <- function(cost, q, ...) {
  check_cost(cost)
  check_quantity(q)
  UseMethod("marginal_cost")
}

#' @export
marginal_cost.quadratic_cost <- function(cost, q, ...) {
  cost$a + 2 * cost$b * q
}

#' @export
marginal_cost.production_cost <- function(cost, q, ...) {
  out <- numeric(length(q))
  pos <- q > 0
  if (any(pos)) {
    out[pos] <- mc_production(cost$f, cost$w, cost$r, q[pos])
  }
  if (any(!pos)) {
    # At zero output the derivative may not exist (it is 0 or infinite for
    # a Cobb-Douglas with non-unit returns), so report the cost of the
    # first small sliver of output instead: a right-hand secant over
    # [0, 1e-3], which is finite, scale-independent and honest.
    sliver <- 1e-3
    out[!pos] <- expenditure(cost$f, cost$w, cost$r, sliver) / sliver
  }
  out
}

#' @rdname cost_values
#' @export
average_cost <- function(cost, q, ...) {
  total_cost(cost, q, ...) / q
}

#' @rdname cost_values
#' @export
average_variable_cost <- function(cost, q, ...) {
  variable_cost(cost, q, ...) / q
}

#' @rdname cost_values
#' @export
min_average_cost <- function(cost, q_max = NULL, ...) {
  check_cost(cost)
  if (inherits(cost, "quadratic_cost")) {
    if (cost$fixed > 0 && cost$b > 0) {
      q <- sqrt(cost$fixed / cost$b)
      return(list(q = q, ac = average_cost(cost, q)))
    }
    if (cost$fixed == 0) {
      # AC = a + b q is lowest as q -> 0.
      return(list(q = NA_real_, ac = cost$a))
    }
    # Fixed cost but constant MC: AC falls forever towards a.
    return(list(q = NA_real_, ac = cost$a))
  }
  if (is.null(q_max)) {
    cli::cli_abort("{.arg q_max} is required for a {.fn production_cost}.")
  }
  check_positive(q_max)
  opt <- stats::optimize(function(q) average_cost(cost, q), c(1e-9, q_max))
  list(q = opt$minimum, ac = opt$objective)
}

## Market structures ---------------------------------------------------------

#' Scan a marginal function on (0, upper]
#'
#' Shared by the two solvers below: evaluate `g` on a grid, drop non-finite
#' points, and locate every downward crossing (positive to non-positive).
#'
#' @return A list with the grid `q`, the values `g`, the indices `down` of
#'   the grid points just before each downward crossing, and a `polish`
#'   function that refines crossing `i` with uniroot().
#' @noRd
scan_marginal <- function(g, upper, n_grid = 200L) {
  qs <- seq(upper * 1e-9, upper, length.out = n_grid)
  vals <- vapply(qs, g, numeric(1))
  keep <- is.finite(vals)
  qs <- qs[keep]
  vals <- vals[keep]
  down <- if (length(vals) > 1L) which(vals[-length(vals)] > 0 & vals[-1L] <= 0) else integer(0)
  list(
    q = qs, g = vals, down = down,
    polish = function(i) stats::uniroot(g, c(qs[i], qs[i + 1L]), tol = 1e-10)$root
  )
}

#' Maximise the integral of a marginal function on [0, upper]
#'
#' `g` is a "net benefit of one more unit" (MR - MC, P - MC, ...), so the
#' objective is its integral and the candidates for the maximum are the
#' interval's endpoints and every point where `g` crosses from positive to
#' negative. The integral is accumulated on the grid by the trapezoid rule
#' and each candidate is scored; the best one wins. That handles the cases a
#' first-crossing rule gets wrong: marginal cost falling from infinity
#' (`g` runs -, +, -), several crossings, and a `g` that only ever crosses
#' upward (a profit minimum, never returned -- one of the endpoints is).
#'
#' @noRd
maximise_on <- function(g, upper, n_grid = 200L) {
  s <- scan_marginal(g, upper, n_grid)
  if (length(s$g) == 0L) return(0)
  # Cumulative integral of g from 0, treating g as 0 on [0, q[1]].
  cum <- c(0, cumsum(diff(s$q) * (utils::head(s$g, -1) + utils::tail(s$g, -1)) / 2))
  candidates <- c(0, upper)
  scores <- c(0, cum[length(cum)])
  for (i in s$down) {
    candidates <- c(candidates, s$polish(i))
    scores <- c(scores, cum[i])
  }
  candidates[which.max(scores)]
}

#' Find where a decreasing-then-increasing gap function last crosses zero
#'
#' For a search over a *level* rather than a quantity (the common marginal
#' revenue in [third_degree()]) the integral of `g` means nothing; the
#' answer is simply the last downward crossing. With none, 0 if `g` is never
#' positive and `upper` if it always is.
#'
#' @noRd
find_crossing <- function(g, upper, n_grid = 200L) {
  s <- scan_marginal(g, upper, n_grid)
  if (length(s$g) == 0L) return(0)
  if (length(s$down) > 0L) return(s$polish(s$down[length(s$down)]))
  if (all(s$g > 0)) upper else 0
}

#' The quantity at which price equals industry marginal cost
#' @noRd
efficient_quantity <- function(d, cost, n) {
  maximise_on(function(Q) price_at(d, Q) - marginal_cost(cost, Q / n), d$q_max)
}

#' Assemble the outcome object shared by every structure
#' @noRd
market_outcome <- function(structure, d, cost, n, q_firm, note = NULL,
                           price = NULL, consumer_surplus = NULL,
                           producer_surplus = NULL) {
  Q <- n * q_firm
  P <- price %||% price_at(d, Q)
  # A discriminating seller has no single price and takes surplus the
  # uniform-price formulas do not see, so those callers pass their own.
  cs <- consumer_surplus %||% consumer_surplus(d, Q)
  ps <- producer_surplus %||% (P * Q - n * variable_cost(cost, q_firm))
  profit <- ps - n * (total_cost(cost, q_firm) - variable_cost(cost, q_firm))
  profit <- profit / n

  Q_eff <- efficient_quantity(d, cost, n)
  P_eff <- price_at(d, Q_eff)
  w_eff <- consumer_surplus(d, Q_eff) + P_eff * Q_eff - n * variable_cost(cost, Q_eff / n)
  dwl <- max(w_eff - (cs + ps), 0)

  mc <- marginal_cost(cost, q_firm)
  if (q_firm == 0 && is.null(note)) {
    note <- "no production: marginal cost exceeds willingness to pay at every quantity"
  }
  structure(
    list(
      structure = structure,
      n = n,
      price = P,
      quantity = Q,
      q_firm = q_firm,
      profit_firm = profit,
      consumer_surplus = cs,
      producer_surplus = ps,
      deadweight_loss = dwl,
      lerner = if (P > 0) (P - mc) / P else NA_real_,
      elasticity = if (Q > 0) elasticity(d, Q) else NA_real_,
      efficient = list(price = P_eff, quantity = Q_eff),
      demand = d,
      cost = cost,
      note = note
    ),
    class = "market_outcome"
  )
}

#' Market equilibrium under monopoly, oligopoly and perfect competition
#'
#' Each function puts a demand curve together with a cost function and solves
#' for the outcome:
#'
#' * `monopoly()` -- a single seller sets marginal revenue equal to marginal
#'   cost.
#' * `cournot()` -- `n` identical firms choose quantities simultaneously; the
#'   symmetric equilibrium solves \eqn{P(nq) + q P'(nq) = MC(q)}. With
#'   `n = 1` it is the monopoly; as `n` grows it approaches competition.
#' * `perfect_competition()` -- price-taking firms set marginal cost equal to
#'   price. With `n` given this is the short run: `n` firms, each producing
#'   where \eqn{MC(q) = P}, unless price is below average variable cost, in
#'   which case they shut down. With `n = NULL` it is the long run: entry
#'   drives price to minimum average cost and the number of firms follows
#'   from demand (it need not be a whole number).
#'
#' Every function returns the same `market_outcome` object, so the
#' structures can be compared directly; [compare_structures()] does exactly
#' that.
#'
#' @param demand A demand object from [linear_demand()] or [demand_fn()].
#' @param cost A cost object from [quadratic_cost()] or [production_cost()].
#' @param n Number of firms. For `perfect_competition()`, `NULL` for the
#'   long run.
#'
#' @return An object of class `market_outcome`: a list with `structure`,
#'   `n`, `price`, `quantity` (industry), `q_firm`, `profit_firm`,
#'   `consumer_surplus`, `producer_surplus`, `deadweight_loss` (against the
#'   efficient `P = MC` outcome for the same number of firms), `lerner`
#'   (\eqn{(P - MC) / P}), `elasticity` (of demand at the outcome), and
#'   `efficient` (the benchmark `price` and `quantity`). Surpluses exclude
#'   fixed costs, which are sunk.
#'
#' @examples
#' d <- linear_demand(intercept = 100, slope = 1)
#' cst <- quadratic_cost(a = 20)          # constant marginal cost 20
#'
#' monopoly(d, cst)                       # Q = 40, P = 60
#' cournot(d, cst, n = 2)                 # each firm 80/3
#' perfect_competition(d, cst, n = 10)    # P = 20, no deadweight loss
#'
#' # Long run with U-shaped average cost: entry until P = min AC
#' perfect_competition(d, quadratic_cost(fixed = 100, a = 20, b = 1))
#' @name market_structure
NULL

#' @rdname market_structure
#' @export
monopoly <- function(demand, cost) {
  check_demand(demand)
  check_cost(cost)
  q <- maximise_on(function(Q) marginal_revenue(demand, Q) - marginal_cost(cost, Q), demand$q_max)
  market_outcome("monopoly", demand, cost, n = 1, q_firm = q)
}

#' @rdname market_structure
#' @export
cournot <- function(demand, cost, n) {
  check_demand(demand)
  check_cost(cost)
  if (!is.numeric(n) || length(n) != 1L || !is.finite(n) || n < 1 || n != round(n)) {
    cli::cli_abort("{.arg n} must be a whole number of firms, at least 1.")
  }
  foc <- function(q) {
    Q <- n * q
    price_at(demand, Q) + q * demand_slope(demand, Q) - marginal_cost(cost, q)
  }
  q <- maximise_on(foc, demand$q_max / n)
  market_outcome(if (n == 1) "monopoly" else "cournot", demand, cost, n = n, q_firm = q)
}

#' @rdname market_structure
#' @export
perfect_competition <- function(demand, cost, n = NULL) {
  check_demand(demand)
  check_cost(cost)
  if (is.null(n)) {
    mac <- min_average_cost(cost, q_max = demand$q_max)
    if (is.na(mac$q)) {
      cli::cli_abort(c(
        "Average cost has no interior minimum, so free entry has no equilibrium.",
        "i" = "Long-run competition needs both a fixed cost and rising marginal cost."
      ))
    }
    Q <- quantity_at(demand, mac$ac)
    n_firms <- Q / mac$q
    if (n_firms <= 0) {
      cli::cli_abort("No firm can cover its minimum average cost at any positive quantity.")
    }
    return(market_outcome("competition (long run)", demand, cost,
                          n = n_firms, q_firm = mac$q))
  }
  if (!is.numeric(n) || length(n) != 1L || !is.finite(n) || n < 1) {
    cli::cli_abort("{.arg n} must be a positive number of firms, or NULL for the long run.")
  }
  Q <- maximise_on(function(QQ) price_at(demand, QQ) - marginal_cost(cost, QQ / n), demand$q_max)
  q <- Q / n
  note <- NULL
  if (q > 0 && price_at(demand, Q) < average_variable_cost(cost, q)) {
    q <- 0
    note <- "price below average variable cost: firms shut down"
  }
  market_outcome("competition", demand, cost, n = n, q_firm = q, note = note)
}

#' @export
print.market_outcome <- function(x, ...) {
  fmt <- fmt_num
  cat(sprintf("<Market outcome: %s, %s firm%s>\n", x$structure, fmt(x$n),
              if (isTRUE(all.equal(x$n, 1))) "" else "s"))
  cat(sprintf("  price %s, quantity %s (%s per firm), profit per firm %s\n",
              fmt(x$price), fmt(x$quantity), fmt(x$q_firm), fmt(x$profit_firm)))
  cat(sprintf("  consumer surplus %s, producer surplus %s, deadweight loss %s\n",
              fmt(x$consumer_surplus), fmt(x$producer_surplus), fmt(x$deadweight_loss)))
  cat(sprintf("  Lerner index %s, demand elasticity %s\n", fmt(x$lerner), fmt(x$elasticity)))
  if (!is.null(x$note)) cat("  note:", x$note, "\n")
  invisible(x)
}

#' Compare market structures on the same demand and cost
#'
#' Runs [monopoly()], [cournot()] for each value of `n`, and
#' [perfect_competition()] with the largest `n`, and lines the outcomes up.
#'
#' @inheritParams market_structure
#' @param n Numbers of firms to evaluate Cournot at.
#'
#' @return A data frame with one row per structure: `structure`, `n`,
#'   `price`, `quantity`, `profit_firm`, `consumer_surplus`,
#'   `producer_surplus`, `deadweight_loss`, `lerner`.
#'
#' @examples
#' compare_structures(linear_demand(100, 1), quadratic_cost(a = 20), n = c(2, 3, 5, 10))
#' @export
compare_structures <- function(demand, cost, n = c(2, 3, 5, 10)) {
  n <- check_positive_vector(n)
  outcomes <- c(
    list(monopoly(demand, cost)),
    lapply(n, function(k) cournot(demand, cost, k)),
    list(perfect_competition(demand, cost, n = max(n)))
  )
  do.call(rbind, lapply(outcomes, function(o) {
    data.frame(
      structure = o$structure, n = o$n, price = o$price, quantity = o$quantity,
      profit_firm = o$profit_firm, consumer_surplus = o$consumer_surplus,
      producer_surplus = o$producer_surplus, deadweight_loss = o$deadweight_loss,
      lerner = o$lerner, stringsAsFactors = FALSE
    )
  }))
}
