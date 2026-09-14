# An Economist-style ggplot2 theme

Reproduces the chart furniture of The Economist: a flat blue-grey panel
with no border, horizontal gridlines only, a solid baseline with ticks
on the x-axis, and left-aligned title, subtitle and caption that hang
off the plot edge rather than the panel.

## Usage

``` r
theme_econ(
  base_size = 12,
  base_family = NULL,
  panel = NULL,
  grid = c("y", "x", "both", "none"),
  legend_position = "top"
)
```

## Arguments

- base_size:

  Base font size in points.

- base_family:

  Base font family. `""` uses the device default; `NULL` follows the
  current style
  ([`set_style()`](https://mjorden.github.io/fredscape/reference/set_style.md)).

- panel:

  Panel style: `"blue"` (the classic printed panel), `"white"`, `"dark"`
  or `"parchment"`. `NULL` follows the current style.

- grid:

  Which major gridlines to draw: `"y"` (the default), `"x"`, `"both"` or
  `"none"`.

- legend_position:

  Passed to
  [`ggplot2::theme()`](https://ggplot2.tidyverse.org/reference/theme.html).
  Defaults to `"top"`, left-justified and without a legend title.

## Value

A ggplot2 theme object.

## Details

Two conventions are left to the caller because they depend on the data
rather than the style: put the units in the subtitle and drop the axis
titles with `labs(x = NULL, y = NULL)`, and move the y-axis labels to
the right with
[`scale_y_econ()`](https://mjorden.github.io/fredscape/reference/scale_econ_axis.md).
[`labs_econ()`](https://mjorden.github.io/fredscape/reference/labs_econ.md)
does the first for you.

The Economist sets in a proprietary face (Officina Sans / EconSans).
This theme does not ship or assume a font: `base_family = ""` means the
device default. Pass a family you actually have installed if you want to
get closer.

## See also

[`scale_colour_econ()`](https://mjorden.github.io/fredscape/reference/scale_econ.md)
for matching colour scales,
[`econ_masthead()`](https://mjorden.github.io/fredscape/reference/econ_masthead.md)
for the red block, and
[`annotate_recessions()`](https://mjorden.github.io/fredscape/reference/annotate_recessions.md)
for recession bands.

## Examples

``` r
library(ggplot2)
ggplot(economics, aes(date, unemploy / pop * 100)) +
  geom_line(colour = econ_colours("blue"), linewidth = 0.8) +
  scale_y_econ() +
  labs_econ(
    title = "Out of work",
    subtitle = "United States, unemployed as % of population",
    source = "FRED, Federal Reserve Bank of St Louis"
  ) +
  theme_econ()
```
