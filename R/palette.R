#' The econscape colour dictionary
#'
#' Every colour the package uses, in one place. The categorical hues follow the
#' data palette The Economist publishes for its own charts; the surface and
#' ink colours are matched to the printed page (the blue-grey chart panel, the
#' red masthead block). The sequential and diverging ramps are built from those
#' hues rather than copied from a published ramp, so treat them as
#' Economist-flavoured rather than Economist-official.
#'
#' @format A named character vector of hex colours.
#' @noRd
econ_hex <- c(
  # Categorical data hues
  blue    = "#006BA2",
  cyan    = "#3EBCD2",
  green   = "#379A8B",
  yellow  = "#EBB434",
  olive   = "#B4BA39",
  purple  = "#9A607F",
  tan     = "#D1B07C",

  # Structural. The grid_<panel> entries are the gridline colour used ON that
  # panel, not a grid that is that colour: white lines on the blue panel,
  # blue-grey lines on the white one. They are not swapped.
  red         = "#E3120B",
  panel_blue  = "#D5E4EB",
  panel_dark  = "#1C2B36",
  grid_blue   = "#FFFFFF",
  grid_white  = "#D5E4EB",
  grid_dark   = "#3B4C5A",
  ink         = "#1A1A1A",
  ink_light   = "#F2F2F2",
  muted       = "#5A6E78",
  muted_dark  = "#A8B6BF",
  white       = "#FFFFFF",

  # The academic style: parchment surfaces and brown ink
  panel_parchment = "#F4EEE2",
  grid_parchment  = "#E3D9C6",
  brown           = "#5C4033",
  ink_brown       = "#2E2622",
  muted_brown     = "#7A6B5D",
  rust            = "#8B3A2F"
)

#' Look up econscape colours by name
#'
#' @param ... Unquoted or quoted colour names, e.g. `"blue"`, `"red"`. With no
#'   arguments the whole dictionary is returned.
#'
#' @return A named character vector of hex colours.
#'
#' @examples
#' econ_colours()
#' econ_colours("red", "blue")
#' @export
econ_colours <- function(...) {
  names <- c(...)
  if (length(names) == 0L) {
    return(econ_hex)
  }
  unknown <- setdiff(names, names(econ_hex))
  if (length(unknown) > 0L) {
    cli::cli_abort(c(
      "Unknown colour name{?s}: {.val {unknown}}.",
      "i" = "Available: {.val {names(econ_hex)}}."
    ))
  }
  econ_hex[names]
}

#' @rdname econ_colours
#' @export
econ_colors <- econ_colours

#' Palette definitions
#' @noRd
econ_palettes <- list(
  main = unname(econ_hex[c("blue", "cyan", "green", "yellow", "olive",
                           "purple", "tan")]),
  cool = unname(econ_hex[c("blue", "cyan", "green")]),
  contrast = unname(econ_hex[c("blue", "red")]),
  blues = c("#EBF3F7", "#BCD9E5", "#8DBFD3", "#4E9FBE", "#1B7FA6", "#00588D"),
  redblue = c("#A81829", "#D4574B", "#EBB9AF", "#E9EEF2",
              "#A2C2D4", "#4E90B4", "#00588D"),
  academic = c("#5C4033", "#A47551", "#C9A87C", "#7B5E3B", "#D8C3A5", "#3E2F23", "#9C8B7A"),
  browns = c("#F4EEE2", "#E3D3B8", "#CDB48E", "#B08F63", "#8C6A44", "#5C4033")
)

#' Build a econscape palette function
#'
#' @param palette One of `"main"` (7 categorical hues), `"cool"`, `"contrast"`,
#'   `"academic"` (7 tans and browns), `"blues"` or `"browns"` (sequential) or
#'   `"redblue"` (diverging). `NULL` means the current style's categorical
#'   palette, see [set_style()].
#' @param reverse Reverse the colour order?
#'
#' @return A function of one argument `n` returning `n` colours. Categorical
#'   palettes return their first `n` colours and error if `n` exceeds what the
#'   palette holds; continuous palettes interpolate.
#'
#' @examples
#' econ_pal()(3)
#' econ_pal("blues")(9)
#' @export
econ_pal <- function(palette = NULL, reverse = FALSE) {
  palette <- palette %||% style_default("palette")
  palette <- match_code(palette, names(econ_palettes))
  cols <- econ_palettes[[palette]]
  if (reverse) {
    cols <- rev(cols)
  }
  continuous <- palette %in% c("blues", "browns", "redblue")

  function(n) {
    if (continuous) {
      return(grDevices::colorRampPalette(cols)(n))
    }
    if (n > length(cols)) {
      cli::cli_abort(c(
        "Palette {.val {palette}} has {length(cols)} colour{?s}, but {n} were requested.",
        "i" = "Use {.code econ_pal(\"blues\")} for an interpolating palette,
               or collapse categories."
      ))
    }
    cols[seq_len(n)]
  }
}

#' House-style colour and fill scales
#'
#' Discrete scales draw from the categorical palette in order; continuous
#' scales interpolate a sequential or diverging ramp.
#'
#' @param palette Palette name, see [econ_pal()]. `NULL` follows [set_style()].
#' @param reverse Reverse the colour order?
#' @param ... Passed to [ggplot2::discrete_scale()] or
#'   [ggplot2::scale_colour_gradientn()].
#'
#' @return A ggplot2 scale.
#'
#' @examples
#' library(ggplot2)
#' ggplot(mtcars, aes(wt, mpg, colour = factor(cyl))) +
#'   geom_point(size = 3) +
#'   scale_colour_econ() +
#'   theme_econ()
#' @name scale_econ
NULL

#' @rdname scale_econ
#' @export
scale_colour_econ <- function(palette = NULL, reverse = FALSE, ...) {
  ggplot2::discrete_scale(
    aesthetics = "colour",
    palette = econ_pal(palette, reverse),
    ...
  )
}

#' @rdname scale_econ
#' @export
scale_color_econ <- scale_colour_econ

#' @rdname scale_econ
#' @export
scale_fill_econ <- function(palette = NULL, reverse = FALSE, ...) {
  ggplot2::discrete_scale(
    aesthetics = "fill",
    palette = econ_pal(palette, reverse),
    ...
  )
}

#' @rdname scale_econ
#' @export
scale_colour_econ_c <- function(palette = NULL, reverse = FALSE, ...) {
  palette <- palette %||% if (get_style() == "academic") "browns" else "blues"
  ggplot2::scale_colour_gradientn(
    colours = econ_pal(palette, reverse)(256),
    ...
  )
}

#' @rdname scale_econ
#' @export
scale_color_econ_c <- scale_colour_econ_c

#' @rdname scale_econ
#' @export
scale_fill_econ_c <- function(palette = NULL, reverse = FALSE, ...) {
  palette <- palette %||% if (get_style() == "academic") "browns" else "blues"
  ggplot2::scale_fill_gradientn(
    colours = econ_pal(palette, reverse)(256),
    ...
  )
}
