#' Surface colours for a given panel style
#'
#' @param panel `"blue"`, `"white"`, `"dark"` or `"parchment"`; `NULL` follows
#'   the current style.
#' @return A list of plot, panel, grid, axis, ink and muted colours.
#' @noRd
econ_surface <- function(panel = NULL) {
  panel <- panel %||% style_default("panel")
  switch(panel,
    blue = list(
      plot  = unname(econ_hex["panel_blue"]),
      panel = unname(econ_hex["panel_blue"]),
      grid  = unname(econ_hex["grid_blue"]),
      axis  = unname(econ_hex["ink"]),
      ink   = unname(econ_hex["ink"]),
      muted = unname(econ_hex["muted"])
    ),
    white = list(
      plot  = unname(econ_hex["white"]),
      panel = unname(econ_hex["white"]),
      grid  = unname(econ_hex["grid_white"]),
      axis  = unname(econ_hex["ink"]),
      ink   = unname(econ_hex["ink"]),
      muted = unname(econ_hex["muted"])
    ),
    parchment = list(
      plot  = unname(econ_hex["panel_parchment"]),
      panel = unname(econ_hex["panel_parchment"]),
      grid  = unname(econ_hex["grid_parchment"]),
      axis  = unname(econ_hex["ink_brown"]),
      ink   = unname(econ_hex["ink_brown"]),
      muted = unname(econ_hex["muted_brown"])
    ),
    dark = list(
      plot  = unname(econ_hex["panel_dark"]),
      panel = unname(econ_hex["panel_dark"]),
      grid  = unname(econ_hex["grid_dark"]),
      axis  = unname(econ_hex["ink_light"]),
      ink   = unname(econ_hex["ink_light"]),
      muted = unname(econ_hex["muted_dark"])
    ),
    cli::cli_abort("Unknown panel style {.val {panel}}.")
  )
}

#' The house ggplot2 theme
#'
#' The chart furniture of a well-set economics chart: a flat panel with no
#' border, horizontal gridlines only, a solid baseline with ticks on the
#' x-axis, and left-aligned title, subtitle and caption that hang off the plot
#' edge rather than the panel. In the default academic style the panel is
#' parchment and the face serif; under `set_style("economist")` it is the
#' newspaper's blue-grey panel in the device's sans face.
#'
#' Two conventions are left to the caller because they depend on the data
#' rather than the style: put the units in the subtitle and drop the axis
#' titles with `labs(x = NULL, y = NULL)`, and move the y-axis labels to the
#' right with [scale_y_econ()]. [labs_econ()] does the first for you.
#'
#' No font ships with the package. The academic style asks for `"serif"`,
#' the economist style for `""` (the device default -- The Economist's own
#' face is proprietary); pass a family you actually have installed to get
#' closer to either.
#'
#' @param base_size Base font size in points.
#' @param base_family Base font family. `""` uses the device default;
#'   `NULL` follows the current style ([set_style()]).
#' @param panel Panel style: `"parchment"`, `"blue"` (the newspaper's printed
#'   panel), `"white"` or `"dark"`. `NULL` follows the current style.
#' @param grid Which major gridlines to draw: `"y"` (the default), `"x"`,
#'   `"both"` or `"none"`.
#' @param legend_position Passed to [ggplot2::theme()]. Defaults to `"top"`,
#'   left-justified and without a legend title.
#'
#' @return A ggplot2 theme object.
#'
#' @seealso [scale_colour_econ()] for matching colour scales,
#'   [econ_masthead()] for the red block, and [annotate_recessions()] for
#'   recession bands.
#'
#' @examples
#' library(ggplot2)
#' ggplot(economics, aes(date, unemploy / pop * 100)) +
#'   geom_line(colour = econ_colours("blue"), linewidth = 0.8) +
#'   scale_y_econ() +
#'   labs_econ(
#'     title = "Out of work",
#'     subtitle = "United States, unemployed as % of population",
#'     source = "FRED, Federal Reserve Bank of St Louis"
#'   ) +
#'   theme_econ()
#' @export
theme_econ <- function(base_size = 12,
                       base_family = NULL,
                       panel = NULL,
                       grid = c("y", "x", "both", "none"),
                       legend_position = "top") {
  panel <- match_code(panel %||% style_default("panel"), c("blue", "white", "dark", "parchment"))
  base_family <- base_family %||% style_default("base_family")
  grid <- match.arg(grid)
  s <- econ_surface(panel)
  half <- base_size / 2

  gridline <- ggplot2::element_line(colour = s$grid, linewidth = 0.4)
  blank <- ggplot2::element_blank()

  ggplot2::theme_minimal(base_size = base_size, base_family = base_family) +
    ggplot2::theme(
      # Surfaces
      plot.background = ggplot2::element_rect(fill = s$plot, colour = NA),
      panel.background = ggplot2::element_rect(fill = s$panel, colour = NA),
      panel.border = blank,
      legend.background = ggplot2::element_rect(fill = s$plot, colour = NA),
      legend.key = ggplot2::element_rect(fill = s$plot, colour = NA),
      strip.background = blank,

      # Grid: horizontal only by default, which is what the printed charts do
      panel.grid.major.x = if (grid %in% c("x", "both")) gridline else blank,
      panel.grid.major.y = if (grid %in% c("y", "both")) gridline else blank,
      panel.grid.minor = blank,

      # A solid baseline with outward ticks, x-axis only
      axis.line.x = ggplot2::element_line(colour = s$axis, linewidth = 0.5),
      axis.line.y = blank,
      axis.ticks.x = ggplot2::element_line(colour = s$axis, linewidth = 0.5),
      axis.ticks.y = blank,
      axis.ticks.length = grid::unit(base_size / 3, "pt"),
      axis.text = ggplot2::element_text(colour = s$ink, size = ggplot2::rel(0.9)),
      axis.title = ggplot2::element_text(colour = s$muted, size = ggplot2::rel(0.9)),
      axis.title.x = ggplot2::element_text(margin = ggplot2::margin(t = half)),
      axis.title.y = ggplot2::element_text(margin = ggplot2::margin(r = half)),

      # Titles hang off the plot edge, not the panel
      plot.title.position = "plot",
      plot.caption.position = "plot",
      plot.title = ggplot2::element_text(
        colour = s$ink, face = "bold", size = ggplot2::rel(1.35),
        hjust = 0, margin = ggplot2::margin(b = half * 0.6)
      ),
      plot.subtitle = ggplot2::element_text(
        colour = s$muted, size = ggplot2::rel(1),
        hjust = 0, margin = ggplot2::margin(b = base_size)
      ),
      plot.caption = ggplot2::element_text(
        colour = s$muted, size = ggplot2::rel(0.75),
        hjust = 0, margin = ggplot2::margin(t = base_size)
      ),
      plot.margin = ggplot2::margin(half, base_size, half, base_size),

      # Legend reads as a label row, not a boxed key
      legend.position = legend_position,
      legend.justification = "left",
      legend.direction = "horizontal",
      legend.title = blank,
      legend.text = ggplot2::element_text(colour = s$ink, size = ggplot2::rel(0.9)),
      legend.key.height = grid::unit(base_size, "pt"),
      legend.margin = ggplot2::margin(b = half),

      strip.text = ggplot2::element_text(
        colour = s$ink, face = "bold", size = ggplot2::rel(0.95),
        hjust = 0, margin = ggplot2::margin(b = half * 0.5)
      )
    )
}

#' Axis scales that follow the house conventions
#'
#' `scale_y_econ()` puts the y labels on the right, where The Economist prints
#' them, and removes the padding under the baseline so a series that touches
#' zero sits on the axis.
#'
#' `scale_x_econ_date()` drops the horizontal padding so a time series runs the
#' full width of the panel.
#'
#' @param ... Passed to [ggplot2::scale_y_continuous()] or
#'   [ggplot2::scale_x_date()].
#' @param position Axis side. Defaults to `"right"`.
#' @param expand Expansion, see [ggplot2::expansion()].
#'
#' @return A ggplot2 scale.
#'
#' @examples
#' library(ggplot2)
#' ggplot(economics, aes(date, psavert)) +
#'   geom_line(colour = econ_colours("blue")) +
#'   scale_x_econ_date() +
#'   scale_y_econ() +
#'   theme_econ()
#' @name scale_econ_axis
NULL

#' @rdname scale_econ_axis
#' @export
scale_y_econ <- function(...,
                         position = "right",
                         expand = ggplot2::expansion(mult = c(0, 0.05))) {
  ggplot2::scale_y_continuous(..., position = position, expand = expand)
}

#' @rdname scale_econ_axis
#' @export
scale_x_econ_date <- function(..., expand = ggplot2::expansion(mult = c(0, 0))) {
  ggplot2::scale_x_date(..., expand = expand)
}

#' House-style labels
#'
#' A thin wrapper over [ggplot2::labs()] that drops both axis titles (the units
#' belong in the subtitle) and formats `source` into the caption the way the
#' printed charts do.
#'
#' @param title Chart title. Short and declarative.
#' @param subtitle Subtitle carrying the units and geography.
#' @param source Data source, rendered as `Source: <source>`. Use
#'   `sources` for more than one.
#' @param sources Character vector of sources, rendered as
#'   `Sources: a; b`.
#' @param note Optional note, placed above the source line.
#' @param ... Further arguments passed to [ggplot2::labs()], e.g. `colour`.
#'
#' @return A ggplot2 labels object.
#'
#' @examples
#' library(ggplot2)
#' ggplot(economics, aes(date, uempmed)) +
#'   geom_line(colour = econ_colours("red")) +
#'   labs_econ(
#'     title = "The long wait",
#'     subtitle = "United States, median duration of unemployment, weeks",
#'     source = "FRED, Federal Reserve Bank of St Louis"
#'   ) +
#'   theme_econ()
#' @export
labs_econ <- function(title = NULL,
                      subtitle = NULL,
                      source = NULL,
                      sources = NULL,
                      note = NULL,
                      ...) {
  if (!is.null(source) && !is.null(sources)) {
    cli::cli_abort("Supply {.arg source} or {.arg sources}, not both.")
  }
  src <- sources %||% source
  source_line <- if (is.null(src)) {
    NULL
  } else if (length(src) > 1L) {
    paste0("Sources: ", paste(src, collapse = "; "))
  } else {
    paste0("Source: ", src)
  }

  caption <- c(note, source_line)
  caption <- if (length(caption) == 0L) NULL else paste(caption, collapse = "\n")

  ggplot2::labs(
    title = title,
    subtitle = subtitle,
    caption = caption,
    x = NULL,
    y = NULL,
    ...
  )
}
