# Build a econscape palette function

Build a econscape palette function

## Usage

``` r
econ_pal(palette = NULL, reverse = FALSE)
```

## Arguments

- palette:

  One of `"main"` (7 categorical hues), `"cool"`, `"contrast"`,
  `"academic"` (7 tans and browns), `"blues"` or `"browns"` (sequential)
  or `"redblue"` (diverging). `NULL` means the current style's
  categorical palette, see
  [`set_style()`](https://mjorden.github.io/econscape/reference/set_style.md).

- reverse:

  Reverse the colour order?

## Value

A function of one argument `n` returning `n` colours. Categorical
palettes return their first `n` colours and error if `n` exceeds what
the palette holds; continuous palettes interpolate.

## Examples

``` r
econ_pal()(3)
#> [1] "#5C4033" "#A47551" "#C9A87C"
econ_pal("blues")(9)
#> [1] "#EBF3F7" "#CDE2EB" "#B0D2E0" "#92C2D5" "#6DAFC8" "#479BBB" "#2787AC"
#> [8] "#10709C" "#00588D"
```
