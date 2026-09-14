test_that("every colour in the dictionary is a valid hex triple", {
  expect_true(all(grepl("^#[0-9A-Fa-f]{6}$", econ_colours())))
  expect_false(anyDuplicated(names(econ_colours())) > 0)
})

test_that("colours can be looked up by name", {
  expect_identical(unname(econ_colours("red")), "#E3120B")
  expect_length(econ_colours("blue", "cyan"), 2L)
  expect_error(econ_colours("magenta"), "Unknown colour")
})

test_that("econ_colors() is the same function under the American spelling", {
  expect_identical(econ_colors("red"), econ_colours("red"))
})

test_that("categorical palettes return their first n colours", {
  pal <- econ_pal("main")
  expect_length(pal(3), 3L)
  expect_identical(pal(3), unname(econ_colours("blue", "cyan", "green")))
  expect_length(pal(7), 7L)
})

test_that("asking a categorical palette for too many colours errors clearly", {
  expect_error(econ_pal("main")(20), "7 colours, but 20 were requested")
  expect_error(econ_pal("contrast")(3), "2 colours, but 3 were requested")
})

test_that("continuous palettes interpolate to any length", {
  expect_length(econ_pal("blues")(256), 256L)
  expect_length(econ_pal("redblue")(3), 3L)
  expect_true(all(grepl("^#[0-9A-F]{6}$", econ_pal("blues")(20))))
})

test_that("reverse flips the order", {
  expect_identical(econ_pal("main", reverse = TRUE)(2), rev(econ_pal("main")(7))[1:2])
})

test_that("an unknown palette name is rejected", {
  expect_error(econ_pal("neon"), "palette")
})

test_that("the discrete scales build and carry the palette", {
  sc <- scale_colour_econ()
  expect_s3_class(sc, "Scale")
  expect_identical(sc$aesthetics, "colour")
  expect_identical(scale_fill_econ()$aesthetics, "fill")
  expect_identical(scale_color_econ()$aesthetics, "colour")
})

test_that("the continuous scales build", {
  expect_s3_class(scale_colour_econ_c(), "Scale")
  expect_s3_class(scale_fill_econ_c(), "Scale")
  expect_identical(scale_color_econ_c()$aesthetics, "colour")
})

test_that("a plot using the scales renders end to end", {
  p <- ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg, colour = factor(cyl))) +
    ggplot2::geom_point() +
    scale_colour_econ() +
    theme_econ()
  expect_s3_class(ggplot2::ggplot_build(p), "ggplot_built")
})


test_that("the academic primary has a name in the dictionary", {
  expect_identical(unname(econ_colours("brown")), "#5C4033")
  expect_identical(unname(econ_colours("brown")), unname(econ_styles$academic$roles[["primary"]]))
})
