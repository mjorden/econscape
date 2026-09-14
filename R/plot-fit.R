#' Draw a coefficient table
#'
#' A dot-and-whisker plot of the estimates in an [ols()] fit with their
#' confidence intervals, in the house style. Coefficients whose interval
#' excludes zero are drawn in blue, the rest in grey.
#'
#' @param fit An `econ_fit` from [ols()].
#' @param level Confidence level for the whiskers.
#' @param intercept Include the intercept? Usually on a different scale from
#'   the slopes, so off by default.
#' @param terms Optional character vector of terms to show, in order.
#' @param title,subtitle,source Passed to [labs_econ()]; sensible defaults
#'   are filled in.
#' @param panel Passed to [theme_econ()].
#'
#' @return A ggplot object. Add [econ_masthead()] last if you want the block.
#'
#' @examples
#' econ <- ggplot2::economics
#' econ$unemp_rate <- 100 * econ$unemploy / econ$pop
#' fit <- ols(psavert ~ unemp_rate + uempmed, econ, se = "hac")
#' plot_coefficients(fit)
#' @export
plot_coefficients <- function(fit, level = 0.95, intercept = FALSE, terms = NULL,
                              title = NULL, subtitle = NULL, source = NULL,
                              panel = NULL) {
  tab <- coef_table(fit, level = level)
  if (!intercept) tab <- tab[tab$term != "(Intercept)", , drop = FALSE]
  if (!is.null(terms)) {
    missing <- setdiff(terms, tab$term)
    if (length(missing) > 0L) {
      cli::cli_abort("Unknown term{?s}: {.val {missing}}.")
    }
    tab <- tab[match(terms, tab$term), , drop = FALSE]
  }
  if (nrow(tab) == 0L) {
    cli::cli_abort("Nothing to plot: no terms left after dropping the intercept.")
  }
  tab$term <- factor(tab$term, levels = rev(tab$term))
  tab$clear <- tab$conf_low > 0 | tab$conf_high < 0

  se_label <- switch(fit$se_type,
    classical = "classical", hc1 = "HC1", hac = sprintf("Newey-West, %d lags", fit$lags)
  )
  if (is.null(title)) title <- "Estimated coefficients"
  if (is.null(subtitle)) {
    subtitle <- sprintf("%s; %s%% intervals, %s standard errors",
                        deparse(fit$formula), format(100 * level), se_label)
  }
  ink <- econ_surface(panel)$ink

  ggplot2::ggplot(tab, ggplot2::aes(x = .data$estimate, y = .data$term)) +
    ggplot2::geom_vline(xintercept = 0, colour = econ_surface(panel)$muted, linewidth = 0.4) +
    ggplot2::geom_segment(
      ggplot2::aes(x = .data$conf_low, xend = .data$conf_high,
                   yend = .data$term, colour = .data$clear),
      linewidth = 0.8
    ) +
    ggplot2::geom_point(ggplot2::aes(colour = .data$clear), size = 3) +
    ggplot2::scale_colour_manual(
      values = c(`TRUE` = style_colour("primary"), `FALSE` = econ_surface(panel)$muted),
      guide = "none"
    ) +
    labs_econ(title = title, subtitle = subtitle, source = source) +
    ggplot2::labs(x = "Estimate", y = NULL) +
    theme_econ(panel = panel, grid = "x") +
    ggplot2::theme(axis.text.y = ggplot2::element_text(colour = ink, hjust = 1))
}
