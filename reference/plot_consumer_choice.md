# Draw the consumer's choice in one call

Composes indifference curves, the budget line and the optimal bundle
into a finished chart in the house style, with each curve labelled by
its level at the right-hand edge of the panel. For a
`kind = "production"` Cobb-Douglas the labels switch to isoquant and
isocost vocabulary.

## Usage

``` r
plot_consumer_choice(
  u,
  b,
  levels = NULL,
  xlim = NULL,
  ylim = NULL,
  goods = c("Good x", "Good y"),
  title = NULL,
  subtitle = NULL,
  source = NULL,
  label_levels = TRUE,
  panel = NULL
)
```

## Arguments

- u:

  A function of `x` and `y`, typically from
  [`cobb_douglas()`](https://mjorden.github.io/econscape/reference/cobb_douglas.md).

- b:

  A
  [`budget()`](https://mjorden.github.io/econscape/reference/budget.md).

- levels:

  Curve levels. Defaults to the optimum's utility and two curves either
  side of it.

- xlim, ylim:

  Panel limits. Default to a little beyond each intercept.

- goods:

  Axis labels for `x` and `y`.

- title, subtitle, source:

  Passed to
  [`labs_econ()`](https://mjorden.github.io/econscape/reference/labs_econ.md).
  Sensible defaults are filled in from `u` and `b`.

- label_levels:

  Print each curve's level at its right-hand end?

- panel:

  Passed to
  [`theme_econ()`](https://mjorden.github.io/econscape/reference/theme_econ.md).

## Value

A ggplot object. Add
[`econ_masthead()`](https://mjorden.github.io/econscape/reference/econ_masthead.md)
last if you want the block.

## Examples

``` r
u <- cobb_douglas(alpha = 0.3)
b <- budget(income = 100, px = 2, py = 5)
plot_consumer_choice(u, b)


f <- cobb_douglas(0.5, 0.5, A = 3, kind = "production")
plot_consumer_choice(f, budget(600, 20, 30), goods = c("Labour", "Capital"))
```
