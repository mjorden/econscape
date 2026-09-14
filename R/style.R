#' The two house styles
#'
#' A style bundles the defaults every chart helper reads: which panel
#' [theme_econ()] draws, which categorical palette the colour scales use, what
#' colour the masthead block is, the base font family, and the role colours
#' the `plot_*()` functions draw with (`primary` for the main series and
#' indifference curves, `secondary` for budget lines and marginal cost,
#' `tertiary` for a third series, plus `ink` and `muted`).
#'
#' @noRd
econ_styles <- list(
  economist = list(
    panel = "blue",
    palette = "main",
    masthead = "#E3120B",
    base_family = "",
    roles = c(primary = "#006BA2", secondary = "#E3120B", tertiary = "#379A8B",
              ink = "#1A1A1A", muted = "#5A6E78", band = "#8FA5B0")
  ),
  academic = list(
    panel = "parchment",
    palette = "academic",
    masthead = "#8B3A2F",
    base_family = "serif",
    roles = c(primary = "#5C4033", secondary = "#8B3A2F", tertiary = "#A47551",
              ink = "#2E2622", muted = "#7A6B5D", band = "#D8C3A5")
  )
)

#' Choose the house style
#'
#' Two looks ship with the package. `"academic"` (the default) is for papers
#' and lecture notes: a parchment panel, a serif face, a tan-to-espresso
#' palette and a rust masthead. `"economist"` is the blue-grey panel, red
#' masthead and data palette of the newspaper's charts, with the device's
#' default sans face. Setting the
#' style changes the defaults of [theme_econ()], the `scale_*_econ()` colour
#' scales, [econ_masthead()] and every `plot_*()` helper; any argument you
#' pass explicitly still wins.
#'
#' The style is a session option (`econscape.style`), so put `set_style()` at
#' the top of a script or in `.Rprofile`. It is read when a plot is *built*:
#' a ggplot constructed under one style keeps that style if you switch
#' afterwards, so set the style first and construct the plot second.
#'
#' @param style `"academic"` or `"economist"`.
#'
#' @return `set_style()` invisibly returns the previous style name so it can
#'   be restored; `get_style()` returns the current one; `style_colour()`
#'   returns one of the current style's role colours.
#'
#' @examples
#' old <- set_style("economist")
#' get_style()
#' style_colour("primary")
#' plot_consumer_choice(cobb_douglas(0.4), budget(120, 3, 4))
#' set_style(old)
#' @export
set_style <- function(style = c("academic", "economist")) {
  style <- match.arg(style)
  old <- get_style()
  options(econscape.style = style)
  invisible(old)
}

#' @rdname set_style
#' @export
get_style <- function() {
  style <- getOption("econscape.style", default = "academic")
  if (!style %in% names(econ_styles)) {
    cli::cli_abort("Unknown style {.val {style}} in option {.code econscape.style}.")
  }
  style
}

#' @rdname set_style
#' @param role `"primary"`, `"secondary"`, `"tertiary"`, `"ink"`, `"muted"` or
#'   `"band"` (recession shading).
#' @export
style_colour <- function(role = c("primary", "secondary", "tertiary", "ink", "muted", "band")) {
  role <- match.arg(role)
  unname(econ_styles[[get_style()]]$roles[[role]])
}

#' @noRd
style_default <- function(field) {
  econ_styles[[get_style()]][[field]]
}
