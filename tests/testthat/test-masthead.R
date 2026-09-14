make_plot <- function(...) {
  ggplot2::ggplot(ggplot2::economics, ggplot2::aes(date, psavert)) +
    ggplot2::geom_line() +
    labs_econ(title = "Saving grace", source = "FRED") +
    theme_econ(...)
}

test_that("econ_masthead() returns a drawable gtable", {
  g <- econ_masthead(make_plot())
  expect_s3_class(g, "econ_plot")
  expect_s3_class(g, "gtable")
  expect_true("masthead" %in% g$layout$name)
})

test_that("the masthead adds exactly two rows: the block and the gap", {
  base <- ggplot2::ggplotGrob(make_plot())
  g <- econ_masthead(make_plot())
  expect_identical(nrow(g), nrow(base) + 2L)
})

test_that("the block sits directly above the title and shares its left edge", {
  g <- econ_masthead(make_plot())
  block <- g$layout[g$layout$name == "masthead", ]
  title <- g$layout[g$layout$name == "title", ]

  expect_identical(nrow(block), 1L)
  expect_true(block$t < title$t)
  expect_identical(block$l, title$l)
})

test_that("the block takes the style's masthead colour by default", {
  g <- econ_masthead(make_plot())
  block <- g$grobs[[which(g$layout$name == "masthead")]]
  expect_identical(block$gp$fill, style_default("masthead"))
  withr::local_options(econscape.style = "economist")
  g2 <- econ_masthead(make_plot())
  expect_identical(g2$grobs[[which(g2$layout$name == "masthead")]]$gp$fill, unname(econ_colours("red")))
})

test_that("the block colour is overridable", {
  g <- econ_masthead(make_plot(), colour = "#123456")
  block <- g$grobs[[which(g$layout$name == "masthead")]]
  expect_identical(block$gp$fill, "#123456")
})

test_that("a plot with no title still gets a masthead", {
  p <- ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg)) +
    ggplot2::geom_point() +
    theme_econ()
  g <- econ_masthead(p)
  expect_true("masthead" %in% g$layout$name)
})

test_that("a gtable can be passed straight in", {
  g <- econ_masthead(ggplot2::ggplotGrob(make_plot()))
  expect_s3_class(g, "econ_plot")
})

test_that("adding a second masthead is refused", {
  g <- econ_masthead(make_plot())
  expect_error(econ_masthead(g), "already carries a masthead")
})

test_that("every panel style produces a masthead that draws without error", {
  for (panel in c("blue", "white", "dark")) {
    g <- econ_masthead(make_plot(panel = panel))
    pdf(NULL)
    on.exit(dev.off(), add = TRUE)
    expect_no_error(print(g))
    dev.off()
    on.exit()
  }
})

test_that("plot_surface() falls back rather than erroring on a bare plot", {
  s <- plot_surface(ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg)))
  expect_type(s$fill, "character")
  expect_s3_class(s$margin, "unit")
})
