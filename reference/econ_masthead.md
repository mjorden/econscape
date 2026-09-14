# Add the red masthead block above a chart

The Economist prefixes every chart with a small red rectangle at the top
left, above the title. That block is not a plot layer – it sits outside
the plotting area entirely – so it cannot be added with `+`. This
function converts the plot to a grob table and inserts the block as a
new row aligned with the title.

## Usage

``` r
econ_masthead(
  plot,
  colour = NULL,
  width = grid::unit(0.55, "cm"),
  height = grid::unit(0.13, "cm"),
  gap = grid::unit(0.3, "cm")
)
```

## Arguments

- plot:

  A ggplot object, or a gtable from a previous
  [`ggplot2::ggplotGrob()`](https://ggplot2.tidyverse.org/reference/ggplotGrob.html)
  call.

- colour:

  Block colour. `NULL` follows the current style: Economist red, or rust
  for the academic style.

- width, height:

  Block dimensions, as
  [`grid::unit()`](https://rdrr.io/r/grid/unit.html) objects.

- gap:

  Space between the block and whatever is below it.

## Value

An object of class `econ_plot`, which inherits from `gtable`.

## Details

The result is a grid object, not a ggplot, so it is the last thing you
add. It prints normally and
[`ggplot2::ggsave()`](https://ggplot2.tidyverse.org/reference/ggsave.html)
accepts it, but you cannot add further ggplot layers to it afterwards.

## Examples

``` r
library(ggplot2)
p <- ggplot(economics, aes(date, psavert)) +
  geom_line(colour = econ_colours("blue"), linewidth = 0.7) +
  scale_y_econ() +
  labs_econ(
    title = "Saving grace",
    subtitle = "United States, personal saving rate, % of disposable income",
    source = "FRED, Federal Reserve Bank of St Louis"
  ) +
  theme_econ()

econ_masthead(p)
```
