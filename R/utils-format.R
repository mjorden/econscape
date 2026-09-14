#' Format a number for a print method
#'
#' Four significant figures, no padding. Shared by every `print()` method in
#' the package so the outcome objects read the same way.
#'
#' @param v A numeric vector.
#' @return A character vector.
#' @noRd
fmt_num <- function(v) {
  format(signif(v, 4), trim = TRUE)
}

#' Axis furniture for a diagram with a meaningful origin
#'
#' [theme_econ()] draws only the x-axis line, as a time-series chart wants.
#' The theory diagrams -- indifference curves, market outcomes -- have two
#' quantity axes meeting at zero, so they add a y-axis line in the same ink
#' and right-align the axis titles against the arrowhead end of each axis.
#'
#' @param panel The panel style passed to [theme_econ()], so the line colour
#'   matches.
#' @return A ggplot2 theme object to add to a plot.
#' @noRd
econ_axes <- function(panel = NULL) {
  ggplot2::theme(
    axis.line.y = ggplot2::element_line(colour = econ_surface(panel)$axis, linewidth = 0.5),
    axis.title = ggplot2::element_text(hjust = 1)
  )
}
