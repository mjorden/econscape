## Price schedules -----------------------------------------------------------

paintings <- price_schedule(20, discount = 0.25, after = 2)

test_that("price_schedule() builds tiers from a discount or explicitly", {
  expect_s3_class(paintings, "price_schedule")
  expect_equal(paintings$prices, c(20, 15))
  expect_equal(paintings$breaks, c(2, Inf))
  explicit <- price_schedule(c(20, 15), breaks = 2)
  expect_equal(explicit$prices, paintings$prices)
  expect_output(print(paintings), "20 up to 2; 15 beyond 2")
  expect_error(price_schedule(20), "discount")
  expect_error(price_schedule(20, discount = 1.5, after = 2), "between 0 and 1")
  expect_error(price_schedule(c(20, 15), breaks = c(3, 2)), "increasing")
  expect_error(price_schedule(c(20, 15, 10), breaks = 2), "one more entry")
  expect_error(price_schedule(20, discount = 0.2, after = 2, breaks = 2), "not both")
})

test_that("schedule_cost() and schedule_quantity() invert each other", {
  expect_equal(schedule_cost(paintings, 0:4), c(0, 20, 40, 55, 70))
  expect_equal(schedule_cost(paintings, 2.5), 47.5)
  expect_equal(schedule_quantity(paintings, c(0, 20, 40, 55, 100)), c(0, 1, 2, 3, 6))
  q <- c(0.5, 1.5, 2, 3.7)
  expect_equal(schedule_quantity(paintings, schedule_cost(paintings, q)), q)
  # Flat prices pass straight through.
  expect_equal(schedule_cost(10, 3), 30)
  expect_equal(schedule_quantity(10, 100), 10)
  three <- price_schedule(c(10, 8, 5), breaks = c(2, 5))
  expect_equal(schedule_cost(three, c(2, 5, 7)), c(20, 44, 54))
  expect_equal(schedule_quantity(three, 54), 7)
})

## Kinked budgets ------------------------------------------------------------

b_kink <- budget(income = 100, px = 10, py = paintings)

test_that("a budget with a schedule is kinked, with the right intercepts", {
  expect_true(b_kink$kinked)
  expect_equal(b_kink$x_max, 10)
  expect_equal(b_kink$y_max, 6)
  expect_true(is.na(b_kink$slope))
  expect_equal(b_kink$cost_y(3), 55)
  expect_output(print(b_kink), "kinked")
  flat <- budget(100, 10, 20)
  expect_false(flat$kinked)
  expect_equal(flat$slope, -0.5)
  expect_equal(flat$cost_x(2), 20)
})

test_that("budget_line() of a kinked budget passes through the kink", {
  line <- budget_line(b_kink)
  expect_true(any(abs(line$y - 2) < 1e-9 & abs(line$x - 6) < 1e-9))   # (6 shoes, 2 paintings)
  expect_equal(line$y[1], 6)                       # starts at the y intercept
  expect_equal(line$x[nrow(line)], 10)             # ends at the x intercept
  expect_true(all(diff(line$y) <= 0))
  # Every point spends exactly the income.
  expect_equal(b_kink$cost_x(line$x) + b_kink$cost_y(line$y), rep(100, nrow(line)))
  # Below the kink (fewer than 2 paintings, full price) a pair of shoes trades
  # for half a painting; above it (discounted) for two thirds of one.
  below <- line[line$y < 2, ]; above <- line[line$y > 2, ]
  expect_equal(diff(below$y[1:2]) / diff(below$x[1:2]), -0.5)
  expect_equal(diff(above$y[1:2]) / diff(above$x[1:2]), -2 / 3)
  expect_identical(nrow(budget_line(b_kink, n_points = 5)), 6L)   # 5 points + the kink
  # A schedule on x kinks too.
  bx <- budget(100, px = paintings, py = 10)
  expect_true(any(abs(budget_line(bx)$x - 2) < 1e-9))
})

test_that("geom_budget() draws a kinked budget as a path", {
  layers <- geom_budget(b_kink)
  expect_type(layers, "list")
  expect_length(layers, 1L)
  built <- ggplot2::ggplot_build(ggplot2::ggplot() + layers)$data[[1]]
  expect_true(nrow(built) > 100)
  mixed <- geom_budget(list(b_kink, budget(100, 10, 20)), linetype = c("solid", "dashed"))
  expect_length(mixed, 2L)
  d <- ggplot2::ggplot_build(ggplot2::ggplot() + mixed)$data
  expect_identical(unique(d[[2]]$linetype), "dashed")
})

test_that("optimal_bundle() on a kinked budget searches the frontier", {
  u <- cobb_douglas(0.5)
  opt <- optimal_bundle(u, b_kink)
  expect_equal(b_kink$cost_x(opt$x) + b_kink$cost_y(opt$y), 100, tolerance = 1e-6)
  # Brute force over the frontier agrees.
  line <- budget_line(b_kink, n_points = 2000)
  expect_true(opt$utility >= max(u(line$x, line$y)) - 1e-6)
  # The discount makes paintings cheaper at the margin, so more are bought
  # than under a flat $20 price.
  flat <- optimal_bundle(u, budget(100, 10, 20))
  expect_true(opt$y > flat$y)
  # Preferences that put all weight on x sit at the x intercept.
  corner <- optimal_bundle(perfect_substitutes(10, 1), b_kink)
  expect_equal(c(corner$x, corner$y), c(10, 0))
  # A Leontief consumer on the kinked budget still buys in proportion.
  l <- optimal_bundle(leontief(1, 1), b_kink)
  expect_equal(l$x, l$y, tolerance = 1e-6)
})

test_that("the derived helpers accept kinked budgets", {
  u <- cobb_douglas(0.5)
  expect_s3_class(ggplot2::ggplot_build(plot_consumer_choice(u, b_kink)), "ggplot_built")
  pc <- hicks(u, b_kink, new_px = 5)
  expect_true(all(is.finite(unlist(pc$bundles[, c("x", "y")]))))
})

## Utility tables ------------------------------------------------------------

movies <- utility_table(tu_x = c(20, 37, 50, 60, 65), tu_y = c(16, 30, 40, 46, 48),
                        goods = c("movies", "popcorn"))

test_that("utility_table() evaluates and validates", {
  expect_s3_class(movies, "utility_table")
  expect_equal(movies(3, 4), 50 + 46)
  expect_equal(movies(0, 0), 0)
  expect_equal(movies(2.5, 1), 43.5 + 16)      # interpolated between rows
  expect_true(is.na(movies(6, 1)))             # beyond the table
  expect_output(print(movies), "movies")
  expect_error(utility_table(c(20, 10), c(1, 2)), "non-decreasing")
  expect_error(utility_table(c(1, 2), c(1, 2), goods = "x"), "two names")
})

test_that("the movies problem: whole-unit optimum at both budgets", {
  at_55 <- optimal_bundle(movies, budget(55, px = 7.5, py = 3))
  expect_equal(c(at_55$x, at_55$y, at_55$utility), c(5, 5, 113))
  at_35 <- optimal_bundle(movies, budget(35, px = 7.5, py = 3))
  expect_equal(c(at_35$x, at_35$y, at_35$utility), c(3, 4, 96))
  # Before the price cut, at $10 a movie
  before <- optimal_bundle(movies, budget(55, px = 10, py = 3))
  expect_equal(before$x * 10 + before$y * 3 <= 55, TRUE)
})

test_that("mu_per_dollar() lays out the textbook purchase order", {
  order <- mu_per_dollar(movies, budget(35, px = 7.5, py = 3))
  expect_named(order, c("good", "unit", "price", "mu", "mu_per_dollar", "cumulative_cost", "affordable"))
  expect_identical(order$good[1:3], rep("popcorn", 3))          # 5.33, 4.67, 3.33
  expect_identical(order$good[4:5], rep("movies", 2))           # 2.67, 2.27
  expect_equal(order$cumulative_cost[7], 34.5)                  # ... third movie: $34.50
  expect_identical(sum(order$affordable), 7L)
  # Affordable set matches the exhaustive optimum: 3 movies, 4 bags.
  bought <- order[order$affordable, ]
  expect_equal(sum(bought$good == "movies"), 3)
  expect_equal(sum(bought$good == "popcorn"), 4)
  # Units of a good stay in order even when a later unit's ratio is higher.
  expect_true(all(diff(order$unit[order$good == "movies"]) == 1))
  expect_error(mu_per_dollar(cobb_douglas(0.5), budget(1, 1, 1)), "utility_table")
})

test_that("utility-table indifference curves and MRS come from the table", {
  curve <- indifference_curve(movies, level = 96, x = c(3, 1, 5))
  expect_equal(curve$y[1], 4)                  # (3, 4) is on TU = 96
  expect_true(is.na(curve$y[2]))               # 1 movie cannot reach 96 with <= 5 bags
  expect_equal(mrs(movies, 3, 4), 13 / 6)      # MU of the 3rd movie over the 4th bag
  expect_s3_class(ggplot2::ggplot_build(plot_consumer_choice(movies, budget(35, 7.5, 3))), "ggplot_built")
})

test_that("a utility table on a kinked budget searches whole bundles", {
  disc <- budget(35, px = price_schedule(10, discount = 0.25, after = 2), py = 3)
  opt <- optimal_bundle(movies, disc)
  expect_true(disc$cost_x(opt$x) + disc$cost_y(opt$y) <= 35)
  expect_equal(opt$x, round(opt$x))
  order <- mu_per_dollar(movies, disc)
  expect_equal(order$price[order$good == "movies"], c(10, 10, 7.5, 7.5, 7.5))
})
