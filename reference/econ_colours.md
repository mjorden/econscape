# Look up fredscape colours by name

Look up fredscape colours by name

## Usage

``` r
econ_colours(...)

econ_colors(...)
```

## Arguments

- ...:

  Unquoted or quoted colour names, e.g. `"blue"`, `"red"`. With no
  arguments the whole dictionary is returned.

## Value

A named character vector of hex colours.

## Examples

``` r
econ_colours()
#>            blue            cyan           green          yellow           olive 
#>       "#006BA2"       "#3EBCD2"       "#379A8B"       "#EBB434"       "#B4BA39" 
#>          purple             tan             red      panel_blue      panel_dark 
#>       "#9A607F"       "#D1B07C"       "#E3120B"       "#D5E4EB"       "#1C2B36" 
#>       grid_blue      grid_white       grid_dark             ink       ink_light 
#>       "#FFFFFF"       "#D5E4EB"       "#3B4C5A"       "#1A1A1A"       "#F2F2F2" 
#>           muted      muted_dark           white panel_parchment  grid_parchment 
#>       "#5A6E78"       "#A8B6BF"       "#FFFFFF"       "#F4EEE2"       "#E3D9C6" 
#>       ink_brown     muted_brown            rust 
#>       "#2E2622"       "#7A6B5D"       "#8B3A2F" 
econ_colours("red", "blue")
#>       red      blue 
#> "#E3120B" "#006BA2" 
```
