# Draw the substitution and income effects of a price change

The diagram behind
[`price_change()`](https://mjorden.github.io/econscape/reference/price_change.md):
the original and final budget lines, the dashed compensated line, the
indifference curves through the bundles, the three bundles themselves,
and brackets along the axis of the good whose price changed showing how
far the substitution and income effects each move the quantity.

## Usage

``` r
plot_price_change(
  u,
  b,
  new_px = NULL,
  new_py = NULL,
  method = c("hicks", "slutsky"),
  goods = c("Good x", "Good y"),
  title = NULL,
  subtitle = NULL,
  source = NULL,
  xlim = NULL,
  ylim = NULL,
  panel = NULL
)
```

## Arguments

- u:

  A function of `x` and `y`.

- b:

  The original
  [`budget()`](https://mjorden.github.io/econscape/reference/budget.md).

- new_px, new_py:

  The new price. Supply exactly one.

- method:

  `"hicks"` or `"slutsky"`.

- goods:

  Axis labels for `x` and `y`.

- title, subtitle, source:

  Passed to
  [`labs_econ()`](https://mjorden.github.io/econscape/reference/labs_econ.md);
  sensible defaults are filled in.

- xlim, ylim:

  Panel limits. Default to a little beyond the widest budget line.

- panel:

  Passed to
  [`theme_econ()`](https://mjorden.github.io/econscape/reference/theme_econ.md).

## Value

A ggplot object. Add
[`econ_masthead()`](https://mjorden.github.io/econscape/reference/econ_masthead.md)
last if you want the block.

## Examples

``` r
u <- cobb_douglas(alpha = 0.4)
b <- budget(income = 120, px = 3, py = 4)
plot_price_change(u, b, new_px = 6)

plot_price_change(u, b, new_px = 6, method = "slutsky")
```
