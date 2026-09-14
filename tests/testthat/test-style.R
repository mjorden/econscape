test_that("the default style is academic and set_style() round-trips", {
  withr::local_options(econscape.style = NULL)
  expect_identical(get_style(), "academic")
  old <- set_style("economist")
  expect_identical(old, "academic")
  expect_identical(get_style(), "economist")
  set_style(old)
  expect_identical(get_style(), "academic")
  expect_error(set_style("gothic"))
  withr::local_options(econscape.style = "gothic")
  expect_error(get_style(), "Unknown style")
})

test_that("style_colour() follows the style", {
  withr::local_options(econscape.style = "economist")
  expect_identical(style_colour("primary"), "#006BA2")
  expect_identical(style_colour("secondary"), "#E3120B")
  withr::local_options(econscape.style = "academic")
  expect_identical(style_colour("primary"), "#5C4033")
  expect_identical(style_colour("band"), "#D8C3A5")
  expect_error(style_colour("neon"))
})

test_that("theme, scales and masthead follow the style unless told otherwise", {
  withr::local_options(econscape.style = "academic")
  th <- theme_econ()
  expect_identical(th$panel.background$fill, "#F4EEE2")
  expect_identical(th$text$family, "serif")
  expect_identical(theme_econ(panel = "blue")$panel.background$fill, "#D5E4EB")
  expect_identical(theme_econ(base_family = "")$text$family, "")
  expect_identical(econ_pal()(2), c("#5C4033", "#A47551"))
  expect_identical(econ_pal("main")(1), "#006BA2")
  expect_length(econ_pal("browns")(9), 9L)
  p <- ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg)) + ggplot2::geom_point() +
    labs_econ(title = "t") + theme_econ()
  g <- econ_masthead(p)
  block <- g$grobs[[which(g$layout$name == "masthead")]]
  expect_identical(block$gp$fill, "#8B3A2F")
  expect_identical(econ_masthead(p, colour = "#000000")$grobs[[which(g$layout$name == "masthead")]]$gp$fill, "#000000")
  withr::local_options(econscape.style = "economist")
  expect_identical(theme_econ()$panel.background$fill, "#D5E4EB")
  expect_identical(econ_pal()(1), "#006BA2")
})

test_that("every plot helper builds under the academic style", {
  withr::local_options(econscape.style = "academic")
  u <- cobb_douglas(0.4); b <- budget(120, 3, 4)
  d <- linear_demand(100, 1); cst <- quadratic_cost(a = 20)
  econ <- ggplot2::economics
  plots <- list(
    plot_consumer_choice(u, b),
    plot_price_change(u, b, new_px = 6),
    plot_cost_curves(cobb_douglas(0.3, 0.5, kind = "production"), 20, 30, q = 1:20, fixed = 50),
    plot_market(monopoly(d, cst)),
    plot_two_part_tariff(two_part_tariff(d, cst)),
    plot_coefficients(ols(psavert ~ uempmed, econ)),
    plot_trend_cycle(hp_filter(data.frame(date = econ$date, value = econ$psavert), frequency = "monthly"))
  )
  for (p in plots) expect_s3_class(ggplot2::ggplot_build(p), "ggplot_built")
  # The consumer-choice curves are drawn in the academic primary, not Economist blue.
  built <- ggplot2::ggplot_build(plots[[1]])$data[[1]]
  expect_identical(unique(built$colour), "#5C4033")
})

test_that("recession bands take the style's band colour by default", {
  withr::local_options(econscape.style = "academic")
  layer <- annotate_recessions(from = "1990-01-01", to = "2015-01-01")
  expect_identical(layer$aes_params$fill, "#D8C3A5")
  expect_identical(annotate_recessions(fill = "red")$aes_params$fill, "red")
})
