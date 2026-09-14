# Draw a two-part tariff

One served consumer's demand curve, the per-unit price, the quantity
bought, and the fee as the shaded surplus above the price. With several
types the type whose surplus pins the fee is drawn, and any surplus a
higher type keeps is left unshaded.

## Usage

``` r
plot_two_part_tariff(
  tariff,
  type = NULL,
  title = NULL,
  subtitle = NULL,
  source = NULL,
  panel = NULL
)
```

## Arguments

- tariff:

  A `two_part_tariff` from
  [`two_part_tariff()`](https://mjorden.github.io/econscape/reference/two_part_tariff.md).

- type:

  Which served type to draw; defaults to the one that sets the fee.

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
d <- linear_demand(intercept = 100, slope = 1)
plot_two_part_tariff(two_part_tariff(d, quadratic_cost(a = 20)))
```
