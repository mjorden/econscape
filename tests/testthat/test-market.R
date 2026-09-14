d <- linear_demand(intercept = 100, slope = 1)
flat <- quadratic_cost(a = 20)                       # constant MC = 20
ushape <- quadratic_cost(fixed = 100, a = 20, b = 1)  # U-shaped AC

## Demand --------------------------------------------------------------------

test_that("linear_demand() has the textbook closed forms", {
  expect_s3_class(d, "demand")
  expect_equal(price_at(d, c(0, 40, 100, 150)), c(100, 60, 0, 0))
  expect_equal(quantity_at(d, c(100, 60, 0)), c(0, 40, 100))
  expect_equal(marginal_revenue(d, 40), 100 - 80)
  expect_equal(elasticity(d, 50), -1)            # unit elastic at the midpoint
  expect_true(elasticity(d, 20) < -1)             # elastic above it
  expect_equal(consumer_surplus(d, 40), 0.5 * 40 * 40)
  expect_output(print(d), "P = 100 - 1 \\* Q")
})

test_that("demand_fn() reproduces the linear results numerically", {
  g <- demand_fn(function(q) 100 - q, q_max = 100)
  expect_equal(price_at(g, 40), 60)
  expect_equal(quantity_at(g, 60), 40, tolerance = 1e-6)
  expect_equal(marginal_revenue(g, 40), 20, tolerance = 1e-5)
  expect_equal(elasticity(g, 50), -1, tolerance = 1e-5)
  expect_equal(consumer_surplus(g, 40), 800, tolerance = 1e-6)
  expect_equal(consumer_surplus(g, 0), 0)
  expect_output(print(g), "p_of_q")
})

test_that("demand objects validate their inputs", {
  expect_error(linear_demand(0, 1), "positive")
  expect_error(demand_fn("f", 1), "function")
  expect_error(price_at(list(), 1), "demand object")
  expect_error(price_at(d, -1), "non-negative")
})

## Cost ----------------------------------------------------------------------

test_that("quadratic_cost() has the textbook closed forms", {
  expect_equal(total_cost(ushape, c(0, 10)), c(100, 100 + 200 + 100))
  expect_equal(variable_cost(ushape, 10), 300)
  expect_equal(marginal_cost(ushape, 10), 20 + 2 * 10)
  expect_equal(average_cost(ushape, 10), 40)
  expect_equal(average_variable_cost(ushape, 10), 30)
  mac <- min_average_cost(ushape)
  expect_equal(mac$q, 10)                          # sqrt(F / b)
  expect_equal(mac$ac, 20 + 2 * sqrt(100 * 1))     # a + 2 sqrt(F b)
  expect_output(print(ushape), "100 \\+ 20 \\* q \\+ 1 \\* q\\^2")
})

test_that("min_average_cost() reports no interior minimum honestly", {
  expect_true(is.na(min_average_cost(flat)$q))
  expect_equal(min_average_cost(flat)$ac, 20)
  expect_true(is.na(min_average_cost(quadratic_cost(fixed = 50, a = 20))$q))
})

test_that("production_cost() sits on expenditure()", {
  f <- cobb_douglas(0.3, 0.5, A = 2, kind = "production")
  pc <- production_cost(f, w = 20, r = 30, fixed = 50)
  expect_equal(total_cost(pc, c(0, 10)), c(50, 50 + expenditure(f, 20, 30, 10)))
  expect_equal(marginal_cost(pc, 10), cost_curves(f, 20, 30, 10)$marginal)
  expect_true(is.finite(marginal_cost(pc, 0)))
  mac <- min_average_cost(pc, q_max = 100)
  expect_true(mac$q > 0 && mac$q < 100)
  expect_output(print(pc), "expenditure")
})

test_that("cost objects validate their inputs", {
  expect_error(quadratic_cost(), "[Aa]t least one")
  expect_error(quadratic_cost(fixed = -1, a = 1), "non-negative")
  expect_error(production_cost("f", 1, 1), "function")
  expect_error(total_cost(list(), 1), "cost object")
  expect_error(min_average_cost(production_cost(cobb_douglas(0.5), 1, 1)), "q_max")
})

## Structures ----------------------------------------------------------------

test_that("monopoly sets MR = MC: Q = (a - c) / 2b", {
  m <- monopoly(d, flat)
  expect_s3_class(m, "market_outcome")
  expect_equal(m$quantity, 40)
  expect_equal(m$price, 60)
  expect_equal(m$profit_firm, 40 * 40)
  expect_equal(m$consumer_surplus, 800)
  expect_equal(m$producer_surplus, 1600)
  expect_equal(m$deadweight_loss, 0.5 * 40 * 40)
  expect_equal(m$efficient$quantity, 80)
  expect_equal(m$lerner, (60 - 20) / 60)
  expect_equal(m$lerner, -1 / m$elasticity)      # inverse-elasticity rule
  expect_output(print(m), "monopoly, 1 firm>")
})

test_that("Cournot: q = (a - c) / (b (n + 1)), and n = 1 is the monopoly", {
  c2 <- cournot(d, flat, n = 2)
  expect_identical(c2$structure, "cournot")
  expect_equal(c2$q_firm, 80 / 3)
  expect_equal(c2$quantity, 160 / 3)
  expect_equal(c2$price, 100 - 160 / 3)
  expect_equal(cournot(d, flat, n = 1)$quantity, monopoly(d, flat)$quantity)
  expect_identical(cournot(d, flat, n = 1)$structure, "monopoly")
  # More firms: lower price, more output, less deadweight loss.
  seq_n <- c(1, 2, 5, 20)
  prices <- vapply(seq_n, function(k) cournot(d, flat, k)$price, numeric(1))
  dwl <- vapply(seq_n, function(k) cournot(d, flat, k)$deadweight_loss, numeric(1))
  expect_true(all(diff(prices) < 0))
  expect_true(all(diff(dwl) < 0))
  expect_error(cournot(d, flat, n = 1.5), "whole number")
})

test_that("short-run perfect competition sets P = MC with no deadweight loss", {
  pc <- perfect_competition(d, flat, n = 10)
  expect_equal(pc$price, 20)
  expect_equal(pc$quantity, 80)
  expect_equal(pc$q_firm, 8)
  expect_equal(pc$deadweight_loss, 0)
  expect_equal(pc$lerner, 0)
  expect_equal(pc$profit_firm, 0)
  # Rising MC: industry supply is MC(Q / n), so more firms means more output.
  few <- perfect_competition(d, ushape, n = 2)
  many <- perfect_competition(d, ushape, n = 8)
  expect_equal(price_at(d, few$quantity), marginal_cost(ushape, few$q_firm))
  expect_true(many$quantity > few$quantity)
  expect_equal(few$deadweight_loss, 0)
})

test_that("no production when marginal cost exceeds willingness to pay everywhere", {
  # MC = 200 + 2q: no firm can sell at a price above the choke price 100.
  dear <- quadratic_cost(fixed = 10, a = 200, b = 1)
  pc <- perfect_competition(d, dear, n = 3)
  expect_equal(pc$quantity, 0)
  expect_equal(pc$profit_firm, -10)
  expect_output(print(pc), "no production")
  expect_equal(monopoly(d, dear)$quantity, 0)
})

test_that("firms shut down when P = MC lies below average variable cost", {
  # A quadratic cost has MC >= AVC everywhere, so this needs falling average
  # cost: a production function with increasing returns. There P = MC would
  # leave every firm unable to cover its variable cost -- the natural-
  # monopoly case, where competition is not sustainable.
  irs <- production_cost(cobb_douglas(0.75, 0.75, kind = "production"), w = 1, r = 1)
  pc <- perfect_competition(d, irs, n = 3)
  expect_equal(pc$quantity, 0)
  expect_output(print(pc), "shut down")
  # ... while a monopolist happily serves the market.
  expect_true(monopoly(d, irs)$quantity > 0)
})

test_that("long-run competition drives price to minimum average cost", {
  lr <- perfect_competition(d, ushape)
  expect_identical(lr$structure, "competition (long run)")
  expect_equal(lr$price, 40)                       # a + 2 sqrt(F b)
  expect_equal(lr$q_firm, 10)                      # sqrt(F / b)
  expect_equal(lr$quantity, 60)                    # demand at 40
  expect_equal(lr$n, 6)
  expect_equal(lr$profit_firm, 0, tolerance = 1e-8)
  expect_error(perfect_competition(d, flat), "no interior minimum")
})

test_that("market_outcome accounting is internally consistent", {
  for (o in list(monopoly(d, ushape), cournot(d, ushape, 3), perfect_competition(d, ushape, 4))) {
    expect_equal(o$quantity, o$n * o$q_firm)
    expect_equal(o$price, price_at(d, o$quantity))
    expect_equal(o$profit_firm, o$price * o$q_firm - total_cost(ushape, o$q_firm))
    expect_true(o$deadweight_loss >= 0)
    expect_true(o$consumer_surplus >= 0)
  }
})

test_that("structures work with a production-derived cost and a general demand", {
  f <- cobb_douglas(0.3, 0.5, A = 2, kind = "production")
  pc <- production_cost(f, w = 20, r = 30)
  g <- demand_fn(function(q) 400 / sqrt(q + 1), q_max = 500)
  m <- monopoly(g, pc)
  expect_true(m$quantity > 0 && m$price > 0)
  expect_true(m$deadweight_loss > 0)
  # Still MR = MC at the optimum.
  expect_equal(marginal_revenue(g, m$quantity), marginal_cost(pc, m$quantity), tolerance = 1e-5)
  c3 <- cournot(g, pc, n = 3)
  expect_true(c3$price < m$price)
})

test_that("compare_structures() lines the outcomes up", {
  tab <- compare_structures(d, flat, n = c(2, 5))
  expect_identical(tab$structure, c("monopoly", "cournot", "cournot", "competition"))
  expect_equal(tab$n, c(1, 2, 5, 5))
  expect_true(all(diff(tab$price) < 0))
  expect_true(all(diff(tab$deadweight_loss) < 0))
  expect_equal(tab$deadweight_loss[4], 0)
  expect_named(tab, c("structure", "n", "price", "quantity", "profit_firm",
                      "consumer_surplus", "producer_surplus", "deadweight_loss", "lerner"))
})

## Plot ----------------------------------------------------------------------

test_that("plot_market() builds for each structure and shades the right areas", {
  m <- monopoly(d, flat)
  p <- ggplot2::ggplot_build(plot_market(m))
  ribbons <- sum(vapply(p$plot$layers, function(l) inherits(l$geom, "GeomRibbon"), logical(1)))
  expect_identical(ribbons, 3L)
  expect_match(p$plot$labels$title, "Monopoly")

  comp <- perfect_competition(d, flat, n = 10)
  pc <- ggplot2::ggplot_build(plot_market(comp))
  ribbons <- sum(vapply(pc$plot$layers, function(l) inherits(l$geom, "GeomRibbon"), logical(1)))
  expect_identical(ribbons, 1L)   # no DWL triangle, no PS with flat MC at P = MC

  only_dwl <- plot_market(m, shade = "dwl")
  expect_identical(sum(vapply(only_dwl$layers, function(l) inherits(l$geom, "GeomRibbon"), logical(1))), 1L)

  lr <- plot_market(perfect_competition(d, ushape))
  expect_match(lr$labels$title, "long run")
  expect_s3_class(ggplot2::ggplot_build(lr), "ggplot_built")
  expect_s3_class(ggplot2::ggplot_build(plot_market(cournot(d, ushape, 3))), "ggplot_built")
  expect_error(plot_market(list()), "market_outcome")
})

## Numerics follow-ups (#17) -------------------------------------------------

test_that("maximise_on() never returns a profit minimum", {
  # Net benefit negative then positive: the integral is minimised at the
  # crossing and maximised at an endpoint. The old rule returned 5.
  g <- function(q) if (q <= 5) -1 else 1
  expect_equal(maximise_on(g, 10), 10)
  g2 <- function(q) if (q <= 8) -1 else 1
  expect_equal(maximise_on(g2, 10), 0)
})

test_that("maximise_on() picks the best of several downward crossings", {
  # Two humps: integral of g is larger after the second crossing.
  g <- function(q) if (q < 2) 1 else if (q < 3) -0.5 else if (q < 7) 1 else -3
  expect_equal(maximise_on(g, 10), 7, tolerance = 1e-6)
  # ... and the first when the second hump is shallow.
  g3 <- function(q) if (q < 2) 1 else if (q < 5) -1 else if (q < 6) 0.5 else -3
  expect_equal(maximise_on(g3, 10), 2, tolerance = 1e-6)
})

test_that("maximise_on() keeps the endpoint behaviour and the IRS case", {
  expect_equal(maximise_on(function(q) 1, 10), 10)
  expect_equal(maximise_on(function(q) -1, 10), 0)
  irs <- production_cost(cobb_douglas(0.6, 0.6, kind = "production"), w = 20, r = 30)
  m <- monopoly(linear_demand(100, 1), irs)
  expect_true(m$quantity > 0)
  expect_equal(marginal_revenue(m$demand, m$quantity), marginal_cost(irs, m$quantity), tolerance = 1e-5)
})

test_that("find_crossing() returns the last downward crossing, or an endpoint", {
  g <- function(m) if (m < 3) 1 else if (m < 6) -1 else if (m < 8) 1 else -1
  expect_equal(find_crossing(g, 10), 8, tolerance = 1e-6)
  expect_equal(find_crossing(function(m) 1, 10), 10)
  expect_equal(find_crossing(function(m) -1, 10), 0)
})

test_that("demand_fn() rejects an inverse demand that is not decreasing", {
  expect_error(demand_fn(function(q) 50 + q, 100), "decreasing")
  expect_error(demand_fn(function(q) 100 - (q - 50)^2 / 25, 100), "decreasing")
  expect_error(demand_fn(function(q) 100 / q, 100), "finite")
  expect_error(demand_fn(function(q) 5, 100), NA)          # flat is allowed
  expect_s3_class(demand_fn(function(q) 100 - q, 100), "demand")
})

test_that("marginal cost of a custom production function is usable near zero", {
  # Same technology two ways: closed form and a plain function.
  cd <- cobb_douglas(0.25, 0.25, kind = "production")
  plain <- function(x, y) x^0.25 * y^0.25
  a <- production_cost(cd, w = 5, r = 5)
  b <- production_cost(plain, w = 5, r = 5)
  for (q in c(1e-4, 1e-2, 1)) {
    expect_true(marginal_cost(b, q) > 0)
    expect_equal(marginal_cost(b, q), marginal_cost(a, q), tolerance = 1e-2)
  }
  # At zero: the cost of the first sliver, finite and positive, same for both.
  expect_true(is.finite(marginal_cost(a, 0)) && marginal_cost(a, 0) > 0)
  expect_equal(marginal_cost(b, 0), marginal_cost(a, 0), tolerance = 1e-3)
})
