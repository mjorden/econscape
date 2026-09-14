#' Read the resolved plot background and margin from a ggplot
#'
#' [econ_masthead()] has to paint the strip it adds in the same colour as the
#' plot it sits on, and indent the block to line up with the title. Both live
#' in the plot's theme, which may be complete (the usual case, after adding
#' [theme_econ()]) or a partial override of the session default.
#'
#' @param plot A ggplot object.
#' @return A list with `fill` and `margin`.
#' @noRd
plot_surface <- function(plot) {
  fallback <- list(fill = "white", margin = grid::unit(rep(5.5, 4), "pt"))
  th <- plot$theme
  if (is.null(th) || length(th) == 0L) {
    th <- ggplot2::theme_get()
  } else if (!isTRUE(attr(th, "complete"))) {
    th <- ggplot2::theme_get() + th
  }
  tryCatch(
    {
      bg <- ggplot2::calc_element("plot.background", th)
      margin <- ggplot2::calc_element("plot.margin", th)
      list(
        fill = if (is.null(bg$fill) || is.na(bg$fill)) fallback$fill else bg$fill,
        margin = if (is.null(margin)) fallback$margin else margin
      )
    },
    error = function(e) fallback
  )
}

#' Add the red masthead block above a chart
#'
#' The Economist prefixes every chart with a small red rectangle at the top
#' left, above the title. That block is not a plot layer -- it sits outside the
#' plotting area entirely -- so it cannot be added with `+`. This function
#' converts the plot to a grob table and inserts the block as a new row aligned
#' with the title.
#'
#' The result is a grid object, not a ggplot, so it is the last thing you add.
#' It prints normally and [ggplot2::ggsave()] accepts it, but you cannot add
#' further ggplot layers to it afterwards.
#'
#' @param plot A ggplot object, or a gtable from a previous
#'   [ggplot2::ggplotGrob()] call.
#' @param colour Block colour. `NULL` follows the current style: Economist red,
#'   or rust for the academic style.
#' @param width,height Block dimensions, as [grid::unit()] objects.
#' @param gap Space between the block and whatever is below it.
#'
#' @return An object of class `econ_plot`, which inherits from `gtable`.
#'
#' @examples
#' library(ggplot2)
#' p <- ggplot(economics, aes(date, psavert)) +
#'   geom_line(colour = econ_colours("blue"), linewidth = 0.7) +
#'   scale_y_econ() +
#'   labs_econ(
#'     title = "Saving grace",
#'     subtitle = "United States, personal saving rate, % of disposable income",
#'     source = "FRED, Federal Reserve Bank of St Louis"
#'   ) +
#'   theme_econ()
#'
#' econ_masthead(p)
#' @export
econ_masthead <- function(plot,
                          colour = NULL,
                          width = grid::unit(0.55, "cm"),
                          height = grid::unit(0.13, "cm"),
                          gap = grid::unit(0.3, "cm")) {
  if (inherits(plot, "econ_plot")) {
    cli::cli_abort("{.arg plot} already carries a masthead.")
  }

  colour <- colour %||% style_default("masthead")
  surface <- plot_surface(plot)
  g <- if (inherits(plot, "gtable")) plot else ggplot2::ggplotGrob(plot)

  # Line the block up with the title where there is one, so the two share a
  # left edge regardless of plot.title.position; otherwise fall back to the
  # top-left of the whole table.
  title <- which(g$layout$name == "title")
  if (length(title) == 1L) {
    pos <- g$layout$t[title] - 1L
    left <- g$layout$l[title]
    right <- g$layout$r[title]
  } else {
    pos <- 0L
    left <- 1L
    right <- ncol(g)
  }

  g <- gtable::gtable_add_rows(g, gap, pos = pos)
  g <- gtable::gtable_add_rows(g, height, pos = pos)

  block <- grid::rectGrob(
    x = grid::unit(0, "npc"),
    hjust = 0,
    width = width,
    height = grid::unit(1, "npc"),
    gp = grid::gpar(fill = colour, col = NA)
  )

  g <- gtable::gtable_add_grob(
    g, block,
    t = pos + 1L, l = left, r = right,
    name = "masthead", clip = "off"
  )

  # The rows were inserted inside the existing background grob, but a plot
  # built without one (or with a transparent background) would show through.
  if (!any(g$layout$name == "background")) {
    g <- gtable::gtable_add_grob(
      g,
      grid::rectGrob(gp = grid::gpar(fill = surface$fill, col = NA)),
      t = 1L, b = nrow(g), l = 1L, r = ncol(g),
      z = -Inf, name = "background"
    )
  }

  class(g) <- unique(c("econ_plot", class(g)))
  g
}

#' Draw an econ_plot
#'
#' @param x An `econ_plot` from [econ_masthead()].
#' @param newpage Start a new grid page first?
#' @param ... Ignored, for compatibility with [print()].
#'
#' @return `x`, invisibly.
#' @export
print.econ_plot <- function(x, newpage = TRUE, ...) {
  if (newpage) {
    grid::grid.newpage()
  }
  # Drop the subclass so grid dispatches to the gtable draw method.
  grob <- x
  class(grob) <- setdiff(class(grob), "econ_plot")
  grid::grid.draw(grob)
  invisible(x)
}

#' @rdname print.econ_plot
#' @export
plot.econ_plot <- function(x, ...) {
  print(x, ...)
}
