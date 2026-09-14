# Draw a demand or Engel curve

`geom_demand()` draws the output of
[`demand_curve()`](https://mjorden.github.io/fredscape/reference/derived_curves.md)
the way every textbook does: quantity along the x-axis, price up the
y-axis. `geom_engel()` draws
[`engel_curve()`](https://mjorden.github.io/fredscape/reference/derived_curves.md)
with income along the x-axis.

## Usage

``` r
geom_demand(data, colour = style_colour("primary"), linewidth = 0.8, ...)

geom_engel(data, colour = style_colour("primary"), linewidth = 0.8, ...)
```

## Arguments

- data:

  A data frame from
  [`demand_curve()`](https://mjorden.github.io/fredscape/reference/derived_curves.md)
  or
  [`engel_curve()`](https://mjorden.github.io/fredscape/reference/derived_curves.md).

- colour:

  Line colour.

- linewidth:

  Line width.

- ...:

  Passed to
  [`ggplot2::geom_path()`](https://ggplot2.tidyverse.org/reference/geom_path.html).

## Value

A ggplot2 layer.

## Examples

``` r
library(ggplot2)
u <- cobb_douglas(alpha = 0.4)
b <- budget(income = 120, px = 3, py = 4)
d <- demand_curve(u, b, prices = seq(0.5, 10, by = 0.25))

ggplot() +
  geom_demand(d) +
  labs_econ(title = "Demand for x", subtitle = "Price against quantity") +
  labs(x = "Quantity", y = "Price") +
  theme_econ()
```
