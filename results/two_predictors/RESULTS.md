# Two-predictor integration results

These archived results used uniformly spaced knots. The current [example](../../examples/two_predictors.jl) uses quantile breakpoints with repeated endpoints.

- Observations used for fitting: **200**.
- Prediction grid points: **961**.
- Grid RMSE against the known surface: **0.07937981372990364**.
- Largest absolute grid error: **0.25307961385335764**.

| Predictor | Smoothing strength λ | Spline variance r² | Noise variance σ² |
| --- | ---: | ---: | ---: |
| x1 | 0.5617707583442179 | 0.2508498037902852 | 0.1409200845057668 |
| x2 | 5.41940260834967 | 0.026002881625486047 | 0.1409200845057668 |

[Predictions and errors](predictions.csv), [fitted coefficients](coefficients.csv), [smoothing and variance estimates](smoothing_parameters.csv), and [execution log](run.log).

The saved results used Unfold 0.8.12. Standard Unfold 0.8.13 reproduces the grid predictions exactly. RMSE is measured in response units.

## Recorded solver dispatch checks

The example now uses `fit_pspl(...)`, which supplies the REML solver through standard Unfold's `fit!` interface.

| Unfold source | Passed checks | Record |
| --- | ---: | --- |
| Pinned integration copy | 52/52 | [Checks](checks.log) |
| `feature-bychannel` | 65/65 | [Checks](bychannel_checks.log) |
| `feature-denseDesign` | 63/63 | [Checks](dense_checks.log) |

The recorded checks used a formula-aware `modelmatrix` extension and custom optimizer tolerances. They cover the five saved R-reference cases, variable predictor counts, continuous-time fitting and ordinary Unfold regression. Branch checks also cover multiple event designs, per-channel matrices or dense continuous matrices.

Historical Unfold snapshots: [integration copy](https://github.com/Mango-Wang2024/Unfold.jl/commit/55a451d6e44257c70d99e694db6205499535b3cc), [feature-bychannel](https://github.com/unfoldtoolbox/Unfold.jl/tree/df0058ecf599690065c227691d32d0a0fb754443) and [feature-denseDesign](https://github.com/unfoldtoolbox/Unfold.jl/tree/4edc81005ae69e0ad33e7331e0a8ff46bcbc3bac).
