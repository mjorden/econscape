## Render the figures embedded in README.md.
##
## These deliberately use ggplot2's bundled `economics` data set -- itself an
## extract of five FRED series -- so the README can be rebuilt with no API key
## and no network. Re-run with:  Rscript data-raw/readme_figures.R

if (requireNamespace("devtools", quietly = TRUE)) {
  devtools::load_all(".", quiet = TRUE)
} else {
  library(fredscape)
}
library(ggplot2)

fig <- function(name) file.path("man", "figures", paste0(name, ".png"))
save_fig <- function(plot, name, width = 8, height = 4.6) {
  ggsave(fig(name), plot, width = width, height = height, dpi = 150, bg = "white")
  message("wrote ", fig(name))
}

## 1. Single series with recession shading -----------------------------------

p_unemployment <- ggplot(economics, aes(date, uempmed)) +
  annotate_recessions(from = min(economics$date), to = max(economics$date)) +
  geom_line(colour = econ_colours("blue"), linewidth = 0.8) +
  scale_x_econ_date(date_breaks = "10 years", date_labels = "%Y") +
  scale_y_econ() +
  labs_econ(
    title = "The long wait",
    subtitle = "United States, median duration of unemployment, weeks",
    note = "Shaded areas are NBER-dated recessions",
    source = "FRED, Federal Reserve Bank of St Louis"
  ) +
  theme_econ()

save_fig(econ_masthead(p_unemployment), "README-recessions")

## 2. Several series, indexed --------------------------------------------------

base_date <- min(economics$date)
indexed <- do.call(rbind, lapply(
  c(pce = "pce", pop = "pop", unemploy = "unemploy"),
  function(col) {
    data.frame(
      date = economics$date,
      series = col,
      value = economics[[col]] / economics[[col]][economics$date == base_date] * 100
    )
  }
))
indexed$series <- factor(
  indexed$series,
  levels = c("pce", "pop", "unemploy"),
  labels = c("Consumer spending", "Population", "Unemployed persons")
)

p_index <- ggplot(indexed, aes(date, value, colour = series)) +
  geom_hline(yintercept = 100, colour = econ_colours("muted"), linewidth = 0.3) +
  geom_line(linewidth = 0.8) +
  scale_colour_econ() +
  scale_x_econ_date(date_breaks = "10 years", date_labels = "%Y") +
  scale_y_econ() +
  labs_econ(
    title = "Diverging fortunes",
    subtitle = "United States, indexed to 100 at July 1967",
    source = "FRED, Federal Reserve Bank of St Louis"
  ) +
  theme_econ()

save_fig(econ_masthead(p_index), "README-index")

## 3. The palette itself -------------------------------------------------------

sizes <- c(main = 7L, cool = 3L, contrast = 2L, blues = 7L, redblue = 7L)
swatches <- do.call(rbind, lapply(names(sizes), function(name) {
  cols <- econ_pal(name)(sizes[[name]])
  data.frame(palette = name, i = seq_along(cols), colour = cols,
             stringsAsFactors = FALSE)
}))
swatches$palette <- factor(
  swatches$palette,
  levels = rev(c("main", "cool", "contrast", "blues", "redblue"))
)

p_palette <- ggplot(swatches, aes(i, palette, fill = colour)) +
  geom_tile(width = 0.94, height = 0.72) +
  scale_fill_identity() +
  scale_x_continuous(expand = expansion(mult = c(0.01, 0.01))) +
  labs_econ(
    title = "The palette",
    subtitle = "Categorical hues follow The Economist's published data colours"
  ) +
  theme_econ(panel = "white", grid = "none") +
  theme(
    axis.text.x = element_blank(),
    axis.ticks.x = element_blank(),
    axis.line.x = element_blank()
  )

save_fig(econ_masthead(p_palette), "README-palette", height = 3)

## 4. Consumer choice ----------------------------------------------------------

u <- cobb_douglas(alpha = 0.4)
b <- budget(income = 120, px = 3, py = 4)

p_choice <- plot_consumer_choice(
  u, b,
  goods = c("Coffee, cups", "Bagels"),
  title = "Breakfast, optimised",
  subtitle = "Cobb-Douglas utility, alpha = 0.4; income 120 at prices 3 and 4",
  source = "fredscape"
)

save_fig(econ_masthead(p_choice), "README-choice", width = 7, height = 5.2)

## 5. Perfect complements ------------------------------------------------------

p_leontief <- plot_consumer_choice(
  leontief(a = 1, b = 2), budget(income = 120, px = 3, py = 4),
  goods = c("Left shoes", "Right shoes"),
  title = "No use for one without the other",
  subtitle = "Leontief utility, u = min(x, y / 2); income 120 at prices 3 and 4",
  source = "fredscape"
)
save_fig(econ_masthead(p_leontief), "README-leontief", width = 7, height = 5.2)

## 6. Demand curve ---------------------------------------------------------------

d <- demand_curve(u, b, prices = seq(0.75, 12, by = 0.25))
p_demand <- ggplot() +
  geom_demand(d) +
  scale_x_continuous(limits = c(0, NA), expand = expansion(mult = c(0, 0.02))) +
  scale_y_continuous(limits = c(0, NA), expand = expansion(mult = c(0, 0.05))) +
  labs_econ(
    title = "Downward sloping, as advertised",
    subtitle = "Demand for coffee from the Cobb-Douglas consumer above; income 120, bagels at 4",
    source = "fredscape"
  ) +
  labs(x = "Cups of coffee", y = "Price per cup") +
  theme_econ(grid = "both") +
  theme(axis.line.y = element_line(colour = "#1A1A1A", linewidth = 0.5),
        axis.title = element_text(hjust = 1))
save_fig(econ_masthead(p_demand), "README-demand", width = 7, height = 4.6)

## 7. Price change ---------------------------------------------------------------

p_slutsky <- plot_price_change(
  u, b, new_px = 6,
  goods = c("Coffee, cups", "Bagels"),
  title = "When coffee doubles in price",
  subtitle = "Hicks decomposition; income 120, bagels at 4, coffee from 3 to 6",
  source = "fredscape"
)
save_fig(econ_masthead(p_slutsky), "README-price-change", width = 7, height = 5.4)

## 8. Cost curves -----------------------------------------------------------------

f <- cobb_douglas(0.3, 0.5, A = 2, kind = "production")
p_cost <- plot_cost_curves(
  f, w = 20, r = 30, q = seq(1, 40, by = 0.25), fixed = 150,
  title = "Where marginal meets average",
  subtitle = "Cobb-Douglas production with decreasing returns; w = 20, r = 30, fixed cost 150",
  source = "fredscape"
)
save_fig(econ_masthead(p_cost), "README-cost", width = 7, height = 4.6)

## 9. Monopoly ----------------------------------------------------------------------

m <- monopoly(linear_demand(intercept = 100, slope = 1), quadratic_cost(a = 20))
p_monopoly <- plot_market(
  m,
  title = "The price of market power",
  subtitle = "Monopoly facing P = 100 - Q with constant marginal cost 20",
  source = "fredscape"
)
save_fig(econ_masthead(p_monopoly), "README-monopoly", width = 7, height = 5)

## 10. Two-part tariff -------------------------------------------------------------

light <- linear_demand(intercept = 60, slope = 1)
heavy <- linear_demand(intercept = 100, slope = 1)
tp <- two_part_tariff(list(light = light, heavy = heavy), quadratic_cost(a = 20), n = c(5, 1))
p_tariff <- plot_two_part_tariff(
  tp,
  title = "The Disneyland dilemma",
  subtitle = sprintf("Five light users for every heavy one: fee %s, unit price %s, above marginal cost 20",
                     format(signif(tp$fee, 3)), format(signif(tp$price, 3))),
  source = "fredscape"
)
save_fig(econ_masthead(p_tariff), "README-tariff", width = 7, height = 4.8)

## 11. Trend and cycle -----------------------------------------------------------------

unrate <- data.frame(date = economics$date, value = 100 * economics$unemploy / economics$pop)
p_hp <- plot_trend_cycle(
  hp_filter(unrate, frequency = "monthly"),
  title = "The cycle in unemployment",
  subtitle = "United States, unemployed as % of population; Hodrick-Prescott trend, lambda = 14,400",
  source = "FRED, Federal Reserve Bank of St Louis"
)
save_fig(econ_masthead(p_hp), "README-hp", width = 8, height = 5.6)

## 12. Coefficients ---------------------------------------------------------------------

economics$unemp_rate <- 100 * economics$unemploy / economics$pop
fit <- ols(psavert ~ unemp_rate + uempmed, economics, se = "hac")
p_coef <- plot_coefficients(
  fit,
  title = "What moves the saving rate",
  subtitle = "Personal saving rate on unemployment and its median duration; Newey-West 95% intervals",
  source = "FRED, Federal Reserve Bank of St Louis"
)
save_fig(econ_masthead(p_coef), "README-coef", width = 7, height = 3.6)

## 13. The academic style ------------------------------------------------------------

old_style <- set_style("academic")
p_academic <- plot_consumer_choice(
  cobb_douglas(0.5), budget(100, px = 10, py = price_schedule(20, discount = 0.25, after = 2)),
  goods = c("Pairs of shoes", "Paintings of dogs playing poker"),
  title = "A quantity discount bends the budget line",
  subtitle = "Income $100; shoes $10; paintings $20, 25% off after the second. Cobb-Douglas, alpha = 0.5",
  source = "fredscape, academic style"
)
save_fig(econ_masthead(p_academic), "README-academic", width = 7.5, height = 5.6)
set_style(old_style)
