# Package index

## FRED data

A small client that returns tidy data frames.

- [`fred_series()`](https://mjorden.github.io/econscape/reference/fred_series.md)
  : Download FRED series observations
- [`fred_series_info()`](https://mjorden.github.io/econscape/reference/fred_series_info.md)
  : Look up FRED series metadata
- [`fred_search()`](https://mjorden.github.io/econscape/reference/fred_search.md)
  : Search FRED for series matching free text
- [`fred_recessions()`](https://mjorden.github.io/econscape/reference/fred_recessions.md)
  : Fetch recession dates live from FRED
- [`fred_key()`](https://mjorden.github.io/econscape/reference/fred_key.md)
  [`fred_has_key()`](https://mjorden.github.io/econscape/reference/fred_key.md)
  [`fred_set_key()`](https://mjorden.github.io/econscape/reference/fred_key.md)
  : Manage the FRED API key

## The Economist style

Theme, palettes, labels and the red masthead block.

- [`set_style()`](https://mjorden.github.io/econscape/reference/set_style.md)
  [`get_style()`](https://mjorden.github.io/econscape/reference/set_style.md)
  [`style_colour()`](https://mjorden.github.io/econscape/reference/set_style.md)
  : Choose the house style
- [`theme_econ()`](https://mjorden.github.io/econscape/reference/theme_econ.md)
  : An Economist-style ggplot2 theme
- [`scale_colour_econ()`](https://mjorden.github.io/econscape/reference/scale_econ.md)
  [`scale_color_econ()`](https://mjorden.github.io/econscape/reference/scale_econ.md)
  [`scale_fill_econ()`](https://mjorden.github.io/econscape/reference/scale_econ.md)
  [`scale_colour_econ_c()`](https://mjorden.github.io/econscape/reference/scale_econ.md)
  [`scale_color_econ_c()`](https://mjorden.github.io/econscape/reference/scale_econ.md)
  [`scale_fill_econ_c()`](https://mjorden.github.io/econscape/reference/scale_econ.md)
  : Economist-style colour and fill scales
- [`scale_y_econ()`](https://mjorden.github.io/econscape/reference/scale_econ_axis.md)
  [`scale_x_econ_date()`](https://mjorden.github.io/econscape/reference/scale_econ_axis.md)
  : Axis scales that follow the house conventions
- [`labs_econ()`](https://mjorden.github.io/econscape/reference/labs_econ.md)
  : Economist-style labels
- [`econ_masthead()`](https://mjorden.github.io/econscape/reference/econ_masthead.md)
  : Add the red masthead block above a chart
- [`print(`*`<econ_plot>`*`)`](https://mjorden.github.io/econscape/reference/print.econ_plot.md)
  [`plot(`*`<econ_plot>`*`)`](https://mjorden.github.io/econscape/reference/print.econ_plot.md)
  : Draw an econ_plot
- [`econ_colours()`](https://mjorden.github.io/econscape/reference/econ_colours.md)
  [`econ_colors()`](https://mjorden.github.io/econscape/reference/econ_colours.md)
  : Look up econscape colours by name
- [`econ_pal()`](https://mjorden.github.io/econscape/reference/econ_pal.md)
  : Build a econscape palette function
- [`annotate_recessions()`](https://mjorden.github.io/econscape/reference/annotate_recessions.md)
  : Shade recession bands behind a time series
- [`nber_recessions`](https://mjorden.github.io/econscape/reference/nber_recessions.md)
  : US recession dates from the NBER

## Preferences and technology

Utility and production functions that carry their parameters.

- [`cobb_douglas()`](https://mjorden.github.io/econscape/reference/cobb_douglas.md)
  : Cobb-Douglas utility and production functions
- [`ces()`](https://mjorden.github.io/econscape/reference/ces.md) :
  Constant elasticity of substitution (CES) functions
- [`leontief()`](https://mjorden.github.io/econscape/reference/leontief.md)
  : Perfect complements (Leontief) functions
- [`perfect_substitutes()`](https://mjorden.github.io/econscape/reference/perfect_substitutes.md)
  : Perfect substitutes (linear) functions
- [`quasilinear()`](https://mjorden.github.io/econscape/reference/quasilinear.md)
  : Quasi-linear utility

## Consumer theory

- [`budget()`](https://mjorden.github.io/econscape/reference/budget.md)
  : A budget constraint
- [`budget_line()`](https://mjorden.github.io/econscape/reference/budget_line.md)
  : Coordinates of a budget line
- [`price_schedule()`](https://mjorden.github.io/econscape/reference/price_schedule.md)
  [`schedule_cost()`](https://mjorden.github.io/econscape/reference/price_schedule.md)
  [`schedule_quantity()`](https://mjorden.github.io/econscape/reference/price_schedule.md)
  : A unit price that changes with the quantity bought
- [`utility_table()`](https://mjorden.github.io/econscape/reference/utility_table.md)
  : Preferences given as a total-utility table
- [`mu_per_dollar()`](https://mjorden.github.io/econscape/reference/mu_per_dollar.md)
  : The marginal-utility-per-dollar purchase order
- [`indifference_curve()`](https://mjorden.github.io/econscape/reference/indifference_curve.md)
  : Indifference curves and isoquants
- [`optimal_bundle()`](https://mjorden.github.io/econscape/reference/optimal_bundle.md)
  : The bundle a consumer (or producer) chooses
- [`mrs()`](https://mjorden.github.io/econscape/reference/mrs.md) :
  Marginal rate of substitution
- [`expenditure()`](https://mjorden.github.io/econscape/reference/expenditure.md)
  : The expenditure function
- [`demand_curve()`](https://mjorden.github.io/econscape/reference/derived_curves.md)
  [`engel_curve()`](https://mjorden.github.io/econscape/reference/derived_curves.md)
  [`price_consumption_path()`](https://mjorden.github.io/econscape/reference/derived_curves.md)
  [`income_consumption_path()`](https://mjorden.github.io/econscape/reference/derived_curves.md)
  : Curves traced by the optimal bundle
- [`price_change()`](https://mjorden.github.io/econscape/reference/price_change.md)
  [`slutsky()`](https://mjorden.github.io/econscape/reference/price_change.md)
  [`hicks()`](https://mjorden.github.io/econscape/reference/price_change.md)
  : Decompose a price change into substitution and income effects

## Producer theory

- [`expansion_path()`](https://mjorden.github.io/econscape/reference/producer.md)
  [`conditional_demand()`](https://mjorden.github.io/econscape/reference/producer.md)
  [`cost_curves()`](https://mjorden.github.io/econscape/reference/producer.md)
  : Producer theory: expansion paths and cost curves

## Markets

Demand and cost objects, equilibria, and price discrimination.

- [`linear_demand()`](https://mjorden.github.io/econscape/reference/demand.md)
  [`demand_fn()`](https://mjorden.github.io/econscape/reference/demand.md)
  : Market demand
- [`price_at()`](https://mjorden.github.io/econscape/reference/demand_curve_values.md)
  [`quantity_at()`](https://mjorden.github.io/econscape/reference/demand_curve_values.md)
  [`marginal_revenue()`](https://mjorden.github.io/econscape/reference/demand_curve_values.md)
  [`elasticity()`](https://mjorden.github.io/econscape/reference/demand_curve_values.md)
  [`consumer_surplus()`](https://mjorden.github.io/econscape/reference/demand_curve_values.md)
  : Prices, quantities and revenue along a demand curve
- [`aggregate_demand()`](https://mjorden.github.io/econscape/reference/aggregate_demand.md)
  : Horizontal summation of demand curves
- [`quadratic_cost()`](https://mjorden.github.io/econscape/reference/cost.md)
  [`production_cost()`](https://mjorden.github.io/econscape/reference/cost.md)
  : A firm's cost function
- [`total_cost()`](https://mjorden.github.io/econscape/reference/cost_values.md)
  [`variable_cost()`](https://mjorden.github.io/econscape/reference/cost_values.md)
  [`marginal_cost()`](https://mjorden.github.io/econscape/reference/cost_values.md)
  [`average_cost()`](https://mjorden.github.io/econscape/reference/cost_values.md)
  [`average_variable_cost()`](https://mjorden.github.io/econscape/reference/cost_values.md)
  [`min_average_cost()`](https://mjorden.github.io/econscape/reference/cost_values.md)
  : Cost at a level of output
- [`monopoly()`](https://mjorden.github.io/econscape/reference/market_structure.md)
  [`cournot()`](https://mjorden.github.io/econscape/reference/market_structure.md)
  [`perfect_competition()`](https://mjorden.github.io/econscape/reference/market_structure.md)
  : Market equilibrium under monopoly, oligopoly and perfect competition
- [`compare_structures()`](https://mjorden.github.io/econscape/reference/compare_structures.md)
  : Compare market structures on the same demand and cost
- [`first_degree()`](https://mjorden.github.io/econscape/reference/price_discrimination.md)
  [`third_degree()`](https://mjorden.github.io/econscape/reference/price_discrimination.md)
  : Price discrimination
- [`two_part_tariff()`](https://mjorden.github.io/econscape/reference/two_part_tariff.md)
  : Two-part tariffs

## Econometrics

Estimation and time-series tools for the series you fetched.

- [`ols()`](https://mjorden.github.io/econscape/reference/ols.md) :
  Ordinary least squares with robust standard errors

- [`coef_table()`](https://mjorden.github.io/econscape/reference/coef_table.md)
  :

  Coefficient table for an `econ_fit`

- [`plot_coefficients()`](https://mjorden.github.io/econscape/reference/plot_coefficients.md)
  : Draw a coefficient table

- [`hp_filter()`](https://mjorden.github.io/econscape/reference/trend_cycle.md)
  [`hamilton_filter()`](https://mjorden.github.io/econscape/reference/trend_cycle.md)
  : Trend-cycle decompositions

- [`plot_trend_cycle()`](https://mjorden.github.io/econscape/reference/plot_trend_cycle.md)
  : Draw a trend-cycle decomposition

- [`adf_test()`](https://mjorden.github.io/econscape/reference/adf_test.md)
  : Augmented Dickey-Fuller test for a unit root

- [`transform_series()`](https://mjorden.github.io/econscape/reference/transform_series.md)
  : Transform a tidy series the way FRED does

## Diagrams

Textbook figures in the house style, and the layers to build your own.

- [`plot_consumer_choice()`](https://mjorden.github.io/econscape/reference/plot_consumer_choice.md)
  : Draw the consumer's choice in one call
- [`plot_producer_choice()`](https://mjorden.github.io/econscape/reference/plot_producer_choice.md)
  : Draw the producer's cost-minimising choice
- [`plot_price_change()`](https://mjorden.github.io/econscape/reference/plot_price_change.md)
  : Draw the substitution and income effects of a price change
- [`plot_cost_curves()`](https://mjorden.github.io/econscape/reference/plot_cost_curves.md)
  : Draw average and marginal cost
- [`plot_market()`](https://mjorden.github.io/econscape/reference/plot_market.md)
  : Draw a market outcome
- [`plot_two_part_tariff()`](https://mjorden.github.io/econscape/reference/plot_two_part_tariff.md)
  : Draw a two-part tariff
- [`geom_indifference()`](https://mjorden.github.io/econscape/reference/geom_micro.md)
  [`geom_budget()`](https://mjorden.github.io/econscape/reference/geom_micro.md)
  [`geom_optimum()`](https://mjorden.github.io/econscape/reference/geom_micro.md)
  : Chart layers for consumer and producer theory
- [`geom_demand()`](https://mjorden.github.io/econscape/reference/geom_demand.md)
  [`geom_engel()`](https://mjorden.github.io/econscape/reference/geom_demand.md)
  : Draw a demand or Engel curve
- [`geom_consumption_path()`](https://mjorden.github.io/econscape/reference/geom_consumption_path.md)
  : Draw the locus of optimal bundles

## Extending

- [`econscape-extending`](https://mjorden.github.io/econscape/reference/econscape-extending.md)
  [`extending`](https://mjorden.github.io/econscape/reference/econscape-extending.md)
  : Extending econscape with your own preferences, demand and cost
