# Draw average and marginal cost

Plots the average- and marginal-cost curves from
[`cost_curves()`](https://mjorden.github.io/econscape/reference/producer.md)
in the house style, each labelled at its right-hand end. Total cost is
left out: it lives on a different scale and the AC/MC pair is the one
the textbook argument is about.

## Usage

``` r
plot_cost_curves(
  f,
  w,
  r,
  q,
  fixed = 0,
  title = NULL,
  subtitle = NULL,
  source = NULL,
  panel = NULL
)
```

## Arguments

- f:

  A production function of `x` and `y`, e.g.
  `cobb_douglas(0.3, 0.5, kind = "production")`.

- w, r:

  Input prices for `x` and `y` (wage and rental rate, by convention).

- q:

  Vector of output levels. Positive.

- fixed:

  A fixed cost added to total cost. It does not affect marginal cost,
  but gives average cost its textbook U shape.

- title, subtitle, source:

  Passed to
  [`labs_econ()`](https://mjorden.github.io/econscape/reference/labs_econ.md);
  sensible defaults are filled in.

- panel:

  Passed to
  [`theme_econ()`](https://mjorden.github.io/econscape/reference/theme_econ.md).

## Value

A ggplot object. Add
[`econ_masthead()`](https://mjorden.github.io/econscape/reference/econ_masthead.md)
last if you want the block.

## Examples

``` r
f <- cobb_douglas(0.3, 0.5, A = 2, kind = "production")
plot_cost_curves(f, w = 20, r = 30, q = seq(1, 40, by = 0.5), fixed = 150)
```
