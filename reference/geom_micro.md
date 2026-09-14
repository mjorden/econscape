# Chart layers for consumer and producer theory

Layers that put
[`indifference_curve()`](https://mjorden.github.io/fredscape/reference/indifference_curve.md),
[`budget()`](https://mjorden.github.io/fredscape/reference/budget.md)
and
[`optimal_bundle()`](https://mjorden.github.io/fredscape/reference/optimal_bundle.md)
onto a ggplot without constructing the data by hand. None of them
inherit aesthetics from the plot, so they can be added to an empty
[`ggplot()`](https://ggplot2.tidyverse.org/reference/ggplot.html) or
combined with other data.

## Usage

``` r
geom_indifference(
  u,
  levels,
  xlim,
  n_points = 200L,
  colour = style_colour("primary"),
  linewidth = 0.8,
  ...
)

geom_budget(
  b,
  colour = style_colour("secondary"),
  linewidth = 0.8,
  linetype = "solid",
  ...
)

geom_optimum(
  u,
  b,
  colour = style_colour("ink"),
  size = 2.5,
  drop_lines = TRUE,
  ...
)
```

## Arguments

- u:

  A function of `x` and `y`, typically from
  [`cobb_douglas()`](https://mjorden.github.io/fredscape/reference/cobb_douglas.md).

- levels:

  Utility (or output) levels, one curve each.

- xlim:

  Range of `x` over which to draw the curves.

- n_points:

  Number of points per curve. (Named `n_points`, not `n`, because `n`
  means a number of firms or consumers elsewhere in the package.)

- colour:

  Line or point colour.

- linewidth:

  Line width.

- ...:

  Passed to the underlying geom.

- b:

  A
  [`budget()`](https://mjorden.github.io/fredscape/reference/budget.md),
  or for `geom_budget()` a list of them.

- linetype:

  Line type; the drop lines in `geom_optimum()` are always dashed.

- size:

  Point size.

- drop_lines:

  Draw the dashed lines from the optimum to each axis?

## Value

A ggplot2 layer, or a list of layers, that can be added to a plot with
`+`. The convention throughout the package: a `geom_*()` returns a
single layer when it draws one thing (`geom_budget()`,
[`geom_demand()`](https://mjorden.github.io/fredscape/reference/geom_demand.md),
[`geom_engel()`](https://mjorden.github.io/fredscape/reference/geom_demand.md))
and a list when it draws several that belong together
(`geom_optimum()`'s point and drop lines,
[`geom_consumption_path()`](https://mjorden.github.io/fredscape/reference/geom_consumption_path.md)'s
path and points, `geom_indifference()`'s path and the vertical arm of a
Leontief L). Both add with `+` identically.

## Details

- `geom_indifference()` draws one path per `level`.

- `geom_budget()` draws the budget (or isocost) line between its two
  intercepts. Given a list of budgets it draws one line each, which is
  how a price or income change is shown. A kinked budget (one built with
  a
  [`price_schedule()`](https://mjorden.github.io/fredscape/reference/price_schedule.md))
  is drawn as a path through its kinks.

- `geom_optimum()` marks the chosen bundle, with dashed lines dropping
  to each axis.

## See also

[`plot_consumer_choice()`](https://mjorden.github.io/fredscape/reference/plot_consumer_choice.md)
for the whole chart in one call.

## Examples

``` r
library(ggplot2)
u <- cobb_douglas(alpha = 0.4)
b <- budget(income = 120, px = 3, py = 4)

ggplot() +
  geom_indifference(u, levels = c(8, 12, 16), xlim = c(0, 45)) +
  geom_budget(b) +
  geom_optimum(u, b) +
  coord_cartesian(xlim = c(0, 45), ylim = c(0, 35), expand = FALSE) +
  theme_econ()
```
