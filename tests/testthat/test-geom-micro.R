u <- cobb_douglas(alpha = 0.4)
b <- budget(income = 120, px = 3, py = 4)

built_layers <- function(p) ggplot2::ggplot_build(p)$data

test_that("curve_grid() never starts at zero", {
  g <- curve_grid(c(0, 10), n_points = 50)
  expect_true(g[1] > 0)
  expect_equal(g[50], 10)
  expect_length(g, 50L)
  expect_equal(curve_grid(c(2, 10), n_points = 5)[1], 2)
})

test_that("curve_grid() validates its inputs", {
  expect_error(curve_grid(c(10, 0), 10), "increasing pair")
  expect_error(curve_grid(c(-1, 10), 10), "non-negative")
  expect_error(curve_grid(c(0, 10), 1), "at least 2")
  # R partially matches n to n_points, so the old spelling still works.
  old <- ggplot2::ggplot_build(ggplot2::ggplot() + geom_indifference(u, levels = 10, xlim = c(1, 30), n = 25))
  expect_identical(nrow(old$data[[1]]), 25L)
})

test_that("geom_indifference() draws one path per level with finite y", {
  p <- ggplot2::ggplot() + geom_indifference(u, levels = c(8, 12), xlim = c(0, 40))
  d <- built_layers(p)[[1]]
  expect_identical(length(unique(d$group)), 2L)
  expect_true(all(is.finite(d$y)))
  expect_identical(nrow(d), 400L)   # 200 points x 2 levels
})

test_that("geom_indifference() points lie on the requested contour", {
  p <- ggplot2::ggplot() + geom_indifference(u, levels = 10, xlim = c(1, 30), n_points = 25)
  d <- built_layers(p)[[1]]
  expect_equal(u(d$x, d$y), rep(10, nrow(d)))
})

test_that("geom_budget() spans the two intercepts", {
  p <- ggplot2::ggplot() + geom_budget(b)
  d <- built_layers(p)[[1]]
  expect_equal(c(d$x, d$y, d$xend, d$yend), c(0, b$y_max, b$x_max, 0))
  expect_error(geom_budget(list()), "budget")
})

test_that("geom_optimum() marks the bundle with drop lines by default", {
  layers <- geom_optimum(u, b)
  expect_length(layers, 2L)
  p <- ggplot2::ggplot() + layers
  d <- built_layers(p)
  opt <- optimal_bundle(u, b)
  expect_equal(d[[2]]$x, opt$x)
  expect_equal(d[[2]]$y, opt$y)
  # Both drop lines end at the optimum.
  expect_equal(d[[1]]$xend, rep(opt$x, 2))
  expect_equal(d[[1]]$yend, rep(opt$y, 2))
})

test_that("geom_optimum(drop_lines = FALSE) is a single layer", {
  expect_length(geom_optimum(u, b, drop_lines = FALSE), 1L)
})

test_that("plot_consumer_choice() builds a complete ggplot", {
  p <- plot_consumer_choice(u, b)
  expect_s3_class(p, "ggplot")
  built <- ggplot2::ggplot_build(p)
  expect_s3_class(built, "ggplot_built")
  expect_identical(p$labels$title, "Consumer choice")
  expect_match(p$labels$subtitle, "Income 120")
})

test_that("plot_consumer_choice() switches vocabulary for production", {
  f <- cobb_douglas(0.5, 0.5, A = 3, kind = "production")
  p <- plot_consumer_choice(f, budget(600, 20, 30), goods = c("Labour", "Capital"))
  expect_identical(p$labels$title, "Cost minimisation")
  expect_match(p$labels$subtitle, "Outlay 600")
  expect_identical(p$labels$x, "Labour")
  expect_identical(p$labels$y, "Capital")
  expect_s3_class(ggplot2::ggplot_build(p), "ggplot_built")
})

test_that("plot_consumer_choice() defaults put the optimum's curve in the middle", {
  opt <- optimal_bundle(u, b)
  p <- plot_consumer_choice(u, b)
  # First layer is the indifference paths; three groups, middle one at the optimum's level.
  d <- built_layers(p)[[1]]
  levels <- sort(unique(d$group))
  expect_length(levels, 3L)
})

test_that("plot_consumer_choice() honours explicit levels and limits", {
  p <- plot_consumer_choice(u, b, levels = c(5, 15), xlim = c(0, 60), ylim = c(0, 50))
  d <- built_layers(p)[[1]]
  expect_identical(length(unique(d$group)), 2L)
  expect_equal(p$coordinates$limits$x, c(0, 60))
})

test_that("plot_consumer_choice() can suppress labels and validates inputs", {
  with_labels <- plot_consumer_choice(u, b)
  without <- plot_consumer_choice(u, b, label_levels = FALSE)
  expect_true(length(with_labels$layers) > length(without$layers))
  expect_error(plot_consumer_choice(u, list()), "budget")
  expect_error(plot_consumer_choice(u, b, goods = "x"), "two labels")
})

test_that("curve_labels() places one label per visible curve at its rightmost point", {
  xlim <- c(0, b$x_max * 1.15)
  ylim <- c(0, b$y_max * 1.15)
  labels <- curve_labels(u, levels = c(8, 12, 16), xlim, ylim)
  expect_identical(nrow(labels), 3L)
  expect_named(labels, c("x", "y", "label"))
  expect_true(all(labels$y <= ylim[2]))
  expect_true(all(labels$x <= xlim[2]))
})

test_that("curve_labels() drops a curve that never enters the panel", {
  labels <- curve_labels(u, levels = c(10, 1e6), xlim = c(0, 40), ylim = c(0, 30))
  expect_identical(nrow(labels), 1L)
  expect_identical(labels$label, "10")
})

test_that("the full chart renders through econ_masthead()", {
  g <- econ_masthead(plot_consumer_choice(u, b))
  expect_s3_class(g, "econ_plot")
  pdf(NULL)
  on.exit(dev.off(), add = TRUE)
  expect_no_error(print(g))
})
