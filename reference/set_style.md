# Choose the house style

Two looks ship with the package. `"economist"` (the default) is the
blue-grey panel, red masthead and the newspaper's data palette.
`"academic"` is a fork for papers and lecture notes: a parchment panel,
a serif face, a tan-to-espresso palette and a rust masthead. Setting the
style changes the defaults of
[`theme_econ()`](https://mjorden.github.io/econscape/reference/theme_econ.md),
the `scale_*_econ()` colour scales,
[`econ_masthead()`](https://mjorden.github.io/econscape/reference/econ_masthead.md)
and every `plot_*()` helper; any argument you pass explicitly still
wins.

## Usage

``` r
set_style(style = c("economist", "academic"))

get_style()

style_colour(
  role = c("primary", "secondary", "tertiary", "ink", "muted", "band")
)
```

## Arguments

- style:

  `"economist"` or `"academic"`.

- role:

  `"primary"`, `"secondary"`, `"tertiary"`, `"ink"`, `"muted"` or
  `"band"` (recession shading).

## Value

`set_style()` invisibly returns the previous style name so it can be
restored; `get_style()` returns the current one; `style_colour()`
returns one of the current style's role colours.

## Details

The style is a session option (`econscape.style`), so put `set_style()`
at the top of a script or in `.Rprofile`. It is read when a plot is
*built*: a ggplot constructed under one style keeps that style if you
switch afterwards, so set the style first and construct the plot second.

## Examples

``` r
old <- set_style("academic")
get_style()
#> [1] "academic"
style_colour("primary")
#> [1] "#5C4033"
plot_consumer_choice(cobb_douglas(0.4), budget(120, 3, 4))

set_style(old)
```
