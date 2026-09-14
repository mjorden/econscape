# Draw the locus of optimal bundles

Adds a
[`price_consumption_path()`](https://mjorden.github.io/econscape/reference/derived_curves.md)
or
[`income_consumption_path()`](https://mjorden.github.io/econscape/reference/derived_curves.md)
to the indifference-curve diagram as a path through the bundles, with a
point at each one. Pair it with
[`geom_budget()`](https://mjorden.github.io/econscape/reference/geom_micro.md)
given the matching list of budgets to show the lines the bundles sit on.

## Usage

``` r
geom_consumption_path(
  data,
  colour = style_colour("ink"),
  linewidth = 0.6,
  size = 2,
  ...
)
```

## Arguments

- data:

  A data frame with `x` and `y` columns from one of the path functions.

- colour:

  Path and point colour.

- linewidth:

  Path width.

- size:

  Point size; `0` for no points.

- ...:

  Passed to
  [`ggplot2::geom_path()`](https://ggplot2.tidyverse.org/reference/geom_path.html).

## Value

A list of ggplot2 layers.

## Examples

``` r
library(ggplot2)
u <- cobb_douglas(alpha = 0.4)
b <- budget(income = 120, px = 3, py = 4)
incomes <- c(60, 120, 180)
path <- income_consumption_path(u, b, incomes)

ggplot() +
  geom_budget(lapply(incomes, function(i) budget(i, 3, 4))) +
  geom_indifference(u, levels = path$x^0.4 * path$y^0.6, xlim = c(0, 60)) +
  geom_consumption_path(path) +
  coord_cartesian(xlim = c(0, 60), ylim = c(0, 45), expand = FALSE) +
  theme_econ()
```
