test_that("cobb_douglas() builds a callable function with its parameters attached", {
  u <- cobb_douglas(alpha = 0.3)
  expect_s3_class(u, "cobb_douglas")
  expect_true(is.function(u))
  expect_identical(attr(u, "alpha"), 0.3)
  expect_identical(attr(u, "beta"), 0.7)
  expect_identical(attr(u, "A"), 1)
  expect_identical(attr(u, "kind"), "utility")
  expect_equal(u(4, 9), 4^0.3 * 9^0.7)
})

test_that("cobb_douglas() accepts non-unit degree and a scale factor", {
  f <- cobb_douglas(0.6, 0.6, A = 2, kind = "production")
  expect_equal(f(2, 3), 2 * 2^0.6 * 3^0.6)
  expect_identical(attr(f, "kind"), "production")
})

test_that("cobb_douglas() is vectorised over x and y", {
  u <- cobb_douglas(0.5)
  expect_equal(u(c(1, 4), c(4, 1)), c(2, 2))
})

test_that("cobb_douglas() rejects non-positive parameters", {
  expect_error(cobb_douglas(0), "positive number")
  expect_error(cobb_douglas(1.2), "positive number")   # beta = 1 - 1.2 < 0
  expect_error(cobb_douglas(0.5, beta = -1), "positive number")
  expect_error(cobb_douglas(0.5, A = 0), "positive number")
  expect_error(cobb_douglas(c(0.3, 0.4)), "single")
  expect_error(cobb_douglas(0.5, kind = "leisure"))
})

test_that("print.cobb_douglas() reports returns to scale", {
  expect_output(print(cobb_douglas(0.3)), "constant returns")
  expect_output(print(cobb_douglas(0.6, 0.6)), "increasing returns")
  expect_output(print(cobb_douglas(0.3, 0.3)), "decreasing returns")
  expect_output(print(cobb_douglas(0.3, kind = "production")), "production")
})

test_that("budget() derives intercepts and slope", {
  b <- budget(income = 100, px = 2, py = 5)
  expect_s3_class(b, "budget")
  expect_identical(b$x_max, 50)
  expect_identical(b$y_max, 20)
  expect_identical(b$slope, -0.4)
  expect_output(print(b), "2 \\* x \\+ 5 \\* y <= 100")
})

test_that("budget() rejects non-positive inputs", {
  expect_error(budget(0, 1, 1), "positive")
  expect_error(budget(100, -2, 5), "positive")
  expect_error(budget(100, 2, Inf), "positive")
})

test_that("budget_line() runs from the y intercept to the x intercept", {
  b <- budget(100, 2, 5)
  line <- budget_line(b)
  expect_identical(nrow(line), 2L)
  expect_equal(line$x, c(0, 50))
  expect_equal(line$y, c(20, 0))

  many <- budget_line(b, n_points = 11)
  expect_identical(nrow(many), 11L)
  # Every point satisfies the constraint with equality.
  expect_equal(b$px * many$x + b$py * many$y, rep(100, 11))
})

test_that("budget_line() validates its inputs", {
  expect_error(budget_line(list(income = 1)), "budget")
  expect_error(budget_line(budget(1, 1, 1), n_points = 1), "at least 2")
})

test_that("Cobb-Douglas indifference curves are exact contours", {
  u <- cobb_douglas(alpha = 0.5)
  x <- c(1, 2, 4, 8)
  curve <- indifference_curve(u, level = 4, x = x)

  expect_named(curve, c("x", "y", "level"))
  expect_identical(nrow(curve), 4L)
  # Every point on the curve has exactly the requested utility.
  expect_equal(u(curve$x, curve$y), rep(4, 4))
  expect_equal(curve$y, 16 / x)   # y = U^2 / x for alpha = beta = 0.5
})

test_that("indifference_curve() stacks several levels", {
  u <- cobb_douglas(0.3)
  curve <- indifference_curve(u, level = c(2, 4, 6), x = 1:5)
  expect_identical(nrow(curve), 15L)
  expect_identical(unique(curve$level), c(2, 4, 6))
  expect_equal(u(curve$x, curve$y), curve$level)
})

test_that("indifference_curve() is monotone decreasing for Cobb-Douglas", {
  u <- cobb_douglas(0.4, 0.8, A = 3)
  curve <- indifference_curve(u, level = 10, x = seq(0.5, 20, by = 0.5))
  expect_true(all(diff(curve$y) < 0))
})

test_that("the numeric fallback recovers the closed form", {
  cd <- cobb_douglas(0.3)
  generic <- function(x, y) x^0.3 * y^0.7   # same function, no class
  x <- c(1, 3, 10)
  expect_equal(
    indifference_curve(generic, level = 5, x = x)$y,
    indifference_curve(cd, level = 5, x = x)$y,
    tolerance = 1e-6
  )
})

test_that("the numeric fallback handles a Leontief utility", {
  leontief <- function(x, y) pmin(x, y)
  curve <- indifference_curve(leontief, level = 3, x = c(3, 4, 5))
  # For x >= level, the contour is the flat segment y = level.
  expect_equal(curve$y, c(3, 3, 3), tolerance = 1e-6)
})

test_that("the numeric fallback returns NA where no solution exists", {
  leontief <- function(x, y) pmin(x, y)
  # With x = 1, min(x, y) can never reach 3.
  curve <- indifference_curve(leontief, level = 3, x = c(1, 5))
  expect_true(is.na(curve$y[1]))
  expect_equal(curve$y[2], 3, tolerance = 1e-6)
})

test_that("indifference_curve() validates its inputs", {
  u <- cobb_douglas(0.5)
  expect_error(indifference_curve("u", 1, 1), "must be a function")
  expect_error(indifference_curve(u, level = NA_real_, x = 1), "finite")
  expect_error(indifference_curve(u, level = 1, x = "a"), "numeric")
  expect_error(
    indifference_curve(function(x, y) x + y, level = 1, x = 1, y_range = c(5, 1)),
    "increasing pair"
  )
})

test_that("Cobb-Douglas demand spends a fixed share of income on each good", {
  u <- cobb_douglas(alpha = 0.3)
  b <- budget(income = 100, px = 2, py = 5)
  opt <- optimal_bundle(u, b)

  expect_named(opt, c("x", "y", "utility"))
  expect_equal(opt$x * b$px, 30)   # 30% of income on x
  expect_equal(opt$y * b$py, 70)   # 70% on y
  expect_equal(opt$utility, u(opt$x, opt$y))

  # Share is invariant to prices.
  expect_equal(optimal_bundle(u, budget(100, 4, 1))$x * 4, 30)
})

test_that("the optimum lies on the budget line", {
  u <- cobb_douglas(0.6, 0.9, A = 4)
  b <- budget(250, 3, 7)
  opt <- optimal_bundle(u, b)
  expect_equal(b$px * opt$x + b$py * opt$y, b$income)
})

test_that("the tangency condition holds at the optimum", {
  u <- cobb_douglas(0.3)
  b <- budget(100, 2, 5)
  opt <- optimal_bundle(u, b)
  expect_equal(mrs(u, opt$x, opt$y), b$px / b$py)
})

test_that("the numeric optimiser agrees with the closed form", {
  cd <- cobb_douglas(0.3)
  generic <- function(x, y) x^0.3 * y^0.7
  b <- budget(100, 2, 5)
  expect_equal(optimal_bundle(generic, b)$x, optimal_bundle(cd, b)$x, tolerance = 1e-6)
  expect_equal(optimal_bundle(generic, b)$y, optimal_bundle(cd, b)$y, tolerance = 1e-6)
})

test_that("the numeric optimiser finds a corner solution for perfect substitutes", {
  # u = x + 2y: y is twice as valuable, and at px = py all income goes on y.
  substitutes <- function(x, y) x + 2 * y
  b <- budget(100, 1, 1)
  opt <- optimal_bundle(substitutes, b)
  expect_equal(opt$x, 0, tolerance = 1e-6)
  expect_equal(opt$y, 100, tolerance = 1e-6)
})

test_that("optimal_bundle() validates its inputs", {
  expect_error(optimal_bundle("u", budget(1, 1, 1)), "must be a function")
  expect_error(optimal_bundle(cobb_douglas(0.5), list()), "budget")
})

test_that("Cobb-Douglas contours return the documented NA at x <= 0 and level <= 0 (#3)", {
  u <- cobb_douglas(0.5)
  expect_silent(curve <- indifference_curve(u, level = c(0, 4), x = c(0, 2)))
  # x = 0 divides by zero; level = 0 is a fractional power of zero.
  expect_true(is.na(curve$y[curve$x == 0 & curve$level == 4]))
  expect_true(all(is.na(curve$y[curve$level == 0])))
  expect_equal(curve$y[curve$x == 2 & curve$level == 4], 8)

  expect_silent(neg <- indifference_curve(u, level = -1, x = c(-1, 1)))
  expect_true(all(is.na(neg$y)))
})

test_that("both contour methods agree on the degenerate cases (#3)", {
  cd <- cobb_douglas(0.3)
  generic <- function(x, y) x^0.3 * y^0.7
  # A negative level is unattainable for a positive utility; x = 0 pins the
  # function at zero for any positive level. Both methods must say NA there.
  # (level = 0 is excluded on purpose: its contour is the axes themselves, so
  # the numeric method can legitimately answer y = 0 at x = 0.)
  x <- c(0, 1, 5)
  a <- indifference_curve(cd, level = c(-1, 3), x = x)
  b <- suppressWarnings(indifference_curve(generic, level = c(-1, 3), x = x))
  expect_identical(is.na(a$y), is.na(b$y))
  expect_equal(a$y[!is.na(a$y)], b$y[!is.na(b$y)], tolerance = 1e-6)
})

test_that("mrs.default() is finite and accurate near the axes (#2)", {
  cd <- cobb_douglas(0.3)
  generic <- function(x, y) x^0.3 * y^0.7
  # An absolute 1e-6 step would evaluate u() at a negative x here.
  expect_silent(m <- mrs(generic, 1e-8, 5))
  expect_true(is.finite(m))
  expect_equal(m, mrs(cd, 1e-8, 5), tolerance = 1e-4)
})

test_that("mrs.default() keeps its precision at large magnitudes (#2)", {
  cd <- cobb_douglas(0.3)
  generic <- function(x, y) x^0.3 * y^0.7
  expect_equal(mrs(generic, 1e6, 3e6), mrs(cd, 1e6, 3e6), tolerance = 1e-6)
  expect_equal(mrs(generic, c(1e-8, 2, 1e6), c(5, 5, 5)),
               mrs(cd, c(1e-8, 2, 1e6), c(5, 5, 5)), tolerance = 1e-4)
})

test_that("mrs.default() never evaluates u() on a negative quantity (#2)", {
  seen <- numeric(0)
  spy <- function(x, y) { seen <<- c(seen, x, y); x^0.5 * y^0.5 }
  mrs(spy, 1e-9, 1e-9)
  expect_true(all(seen >= 0))
  expect_error(mrs(spy, 1, 1, h = 0), "positive")
})

test_that("mrs() has the Cobb-Douglas closed form and matches finite differences", {
  cd <- cobb_douglas(0.3)
  generic <- function(x, y) x^0.3 * y^0.7
  expect_equal(mrs(cd, 2, 5), (0.3 / 0.7) * (5 / 2))
  expect_equal(mrs(generic, 2, 5), mrs(cd, 2, 5), tolerance = 1e-6)
  expect_length(mrs(cd, 1:3, 1:3), 3L)
  expect_error(mrs(1, 1, 1), "must be a function")
})
