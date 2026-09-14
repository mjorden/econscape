# Draw the producer's cost-minimising choice

The same diagram as
[`plot_consumer_choice()`](https://mjorden.github.io/fredscape/reference/plot_consumer_choice.md)
with the producer's vocabulary: isoquants, an isocost line, and the
input bundle that produces the most for the outlay. Works for any
production function, including a plain `function(x, y)`. The `kind`
attribute is set to `"production"` on a copy for the labels regardless
of how the function was built – so a `cobb_douglas(0.5)` constructed
with the default `kind = "utility"` draws as a technology here without
complaint. That is deliberate: the maths is identical and the
constructor default should not force a keystroke.

## Usage

``` r
plot_producer_choice(
  f,
  b,
  inputs = c("Labour", "Capital"),
  levels = NULL,
  xlim = NULL,
  ylim = NULL,
  title = NULL,
  subtitle = NULL,
  source = NULL,
  label_levels = TRUE,
  panel = NULL
)
```

## Arguments

- f:

  A production function of `x` and `y`.

- b:

  A
  [`budget()`](https://mjorden.github.io/fredscape/reference/budget.md)
  read as an isocost line: `income` is the outlay and `px`, `py` the
  input prices.

- inputs:

  Axis labels for the two inputs.

- levels:

  Curve levels. Defaults to the optimum's utility and two curves either
  side of it.

- xlim, ylim:

  Panel limits. Default to a little beyond each intercept.

- title, subtitle, source:

  Passed to
  [`labs_econ()`](https://mjorden.github.io/fredscape/reference/labs_econ.md).
  Sensible defaults are filled in from `u` and `b`.

- label_levels:

  Print each curve's level at its right-hand end?

- panel:

  Passed to
  [`theme_econ()`](https://mjorden.github.io/fredscape/reference/theme_econ.md).

## Value

A ggplot object.

## Examples

``` r
f <- cobb_douglas(0.5, 0.5, A = 3, kind = "production")
plot_producer_choice(f, budget(600, 20, 30))
```
