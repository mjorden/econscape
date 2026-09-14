# House-style labels

A thin wrapper over
[`ggplot2::labs()`](https://ggplot2.tidyverse.org/reference/labs.html)
that drops both axis titles (the units belong in the subtitle) and
formats `source` into the caption the way the printed charts do.

## Usage

``` r
labs_econ(
  title = NULL,
  subtitle = NULL,
  source = NULL,
  sources = NULL,
  note = NULL,
  ...
)
```

## Arguments

- title:

  Chart title. Short and declarative.

- subtitle:

  Subtitle carrying the units and geography.

- source:

  Data source, rendered as `Source: <source>`. Use `sources` for more
  than one.

- sources:

  Character vector of sources, rendered as `Sources: a; b`.

- note:

  Optional note, placed above the source line.

- ...:

  Further arguments passed to
  [`ggplot2::labs()`](https://ggplot2.tidyverse.org/reference/labs.html),
  e.g. `colour`.

## Value

A ggplot2 labels object.

## Examples

``` r
library(ggplot2)
ggplot(economics, aes(date, uempmed)) +
  geom_line(colour = econ_colours("red")) +
  labs_econ(
    title = "The long wait",
    subtitle = "United States, median duration of unemployment, weeks",
    source = "FRED, Federal Reserve Bank of St Louis"
  ) +
  theme_econ()
```
