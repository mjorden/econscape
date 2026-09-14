# Economist-style colour and fill scales

Discrete scales draw from the categorical palette in order; continuous
scales interpolate a sequential or diverging ramp.

## Usage

``` r
scale_colour_econ(palette = NULL, reverse = FALSE, ...)

scale_color_econ(palette = NULL, reverse = FALSE, ...)

scale_fill_econ(palette = NULL, reverse = FALSE, ...)

scale_colour_econ_c(palette = NULL, reverse = FALSE, ...)

scale_color_econ_c(palette = NULL, reverse = FALSE, ...)

scale_fill_econ_c(palette = NULL, reverse = FALSE, ...)
```

## Arguments

- palette:

  Palette name, see
  [`econ_pal()`](https://mjorden.github.io/fredscape/reference/econ_pal.md).
  `NULL` follows
  [`set_style()`](https://mjorden.github.io/fredscape/reference/set_style.md).

- reverse:

  Reverse the colour order?

- ...:

  Passed to
  [`ggplot2::discrete_scale()`](https://ggplot2.tidyverse.org/reference/discrete_scale.html)
  or
  [`ggplot2::scale_colour_gradientn()`](https://ggplot2.tidyverse.org/reference/scale_gradient.html).

## Value

A ggplot2 scale.

## Examples

``` r
library(ggplot2)
ggplot(mtcars, aes(wt, mpg, colour = factor(cyl))) +
  geom_point(size = 3) +
  scale_colour_econ() +
  theme_econ()
```
