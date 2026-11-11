# Two-predictor integration results

Produced by running this package's [example](../../examples/two_predictors.jl) through Unfold and its REML adapter.

- Observations used for fitting: **200**.
- Prediction grid points: **961**.
- Grid RMSE against the known surface: **0.07937975097818956**.
- Largest absolute grid error: **0.2530795813063291**.

| Predictor | Smoothing strength λ | Spline variance r² | Noise variance σ² |
| --- | ---: | ---: | ---: |
| x1 | 0.5617645543845714 | 0.2508525386621085 | 0.14092006459775783 |
| x2 | 5.419441605131286 | 0.02600269084260094 | 0.14092006459775783 |

[Predictions and errors](predictions.csv), [fitted coefficients](coefficients.csv), [smoothing and variance estimates](smoothing_parameters.csv), and [execution log](run.log).

Unfold version: 0.8.12. RMSE is measured in response units.
