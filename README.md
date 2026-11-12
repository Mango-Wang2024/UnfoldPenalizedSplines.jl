# UnfoldPenalizedSplines.jl

A standalone companion package for additive penalized splines in [Unfold.jl](https://github.com/unfoldtoolbox/Unfold.jl). Each predictor has its own cubic spline and REML-estimated smoothing strength. It depends on standard Unfold; no modified copy or fork is required.

## Files

The numerical code is reused from [Penalized-Splines](https://github.com/Mango-Wang2024/Penalized-Splines/tree/4d8d6e2159bd7a571f32de7b0561f8482f6cf5f4). The integration code connects these calculations to Unfold's formulas, fitting and prediction.

| Group | File | Purpose |
| --- | --- | --- |
| **Reused numerical code** | [BSpline.jl](src/BSpline.jl) | Constructs the cubic B-spline basis and curvature penalty, including centering and scaling, to obtain $B,S$. |
| | [ModelInputs.jl](src/ModelInputs.jl) | Transforms $B,S$ into unpenalized columns $X_0$ and penalized columns $Z$. |
| | [SharedVariance.jl](src/SharedVariance.jl) | Gives each spline's penalized coefficients one shared variance in MixedModels. |
| | [SplineFit.jl](src/SplineFit.jl) | Fits $y,X_f,Z_j$ through MixedModels REML and returns coefficients, smoothing strengths and variances. |
| **Unfold integration** | [UnfoldPenalizedSplines.jl](src/UnfoldPenalizedSplines.jl) | Package entry point: loads the components and exposes the public functions. |
| | [terms.jl](src/terms.jl) | Defines `pspl` and its StatsModels term; supplies spline columns through `modelcols` and retains settings for new-data prediction. |
| | [fit.jl](src/fit.jl) | Defines `REMLAdapter` and `fit_reml!`; selects matrix blocks, calls the fitter and returns results in Unfold's format. |
| **Example and data** | [two_predictors.jl](examples/two_predictors.jl) | Runs spline construction, fitting and prediction through Unfold using two predictors. |
| | [training.csv](examples/data/training.csv) | The 200 observations used for fitting: predictor values, responses and the known surface. |
| | [prediction_grid.csv](examples/data/prediction_grid.csv) | The 961 predictor combinations and known surface values used to evaluate predictions. |
| **Saved results** | [RESULTS.md](results/two_predictors/RESULTS.md) | Reports the example's results and links to predictions, coefficients, smoothing estimates and the execution log. |
| **Package setup** | [Project.toml](Project.toml) | Declares the package dependencies and compatible versions. |

## Workflow

1. **Construct:** `pspl(x, k)` calls the BSplineKit-based construction and prepares the unpenalized columns $X_{0,j}$ and penalized columns $Z_j$ from $B_j,S_j$.
2. **Assemble:** Unfold combines these columns with ordinary predictors and, for continuous data, applies its existing time expansion.
3. **Fit:** `fit_reml!` supplies a solver adapter through Unfold's existing `solver(X, data)` interface. The adapter selects $X_f,Z_1,\ldots,Z_m$ and calls the existing MixedModels REML fitter.
4. **Return:** coefficients are placed in Unfold's column order, so native `predict` and `coeftable` work. `smoothing_parameters` returns each fitted $\lambda_j=\sigma^2/r_j^2$ and its variance estimates.

Training knots, centering and coefficient transformations are retained for new-data prediction. The number of predictors is determined by the formula. Supplied full knot vectors can be used with `pspl(:x, k; knots=...)` in programmatically constructed formulas.

Channels and epoched time points are fitted separately. In continuous models, each spline term has one shared smoothing strength across its time-expanded columns. This applies the predictor-spline penalty; regularization along the TRF time axis is a separate modelling step.

## Example

From this repository's root, use Julia 1.11 or later:

```sh
julia --project=. -e 'using Pkg; Pkg.instantiate()'
julia --project=. examples/two_predictors.jl
```

The example uses the research project's 200 saved observations and 961 prediction points for $f(x_1,x_2)=\sin(1.7x_1)+0.15x_1+0.5\cos(1.2x_2)$. It builds an Unfold model without fitting, then calls:

```julia
formula = @formula(0 ~ 1 + pspl(x1, 8) + pspl(x2, 8))
model = fit(UnfoldModel, formula, events, data, [0.0]; fit=false)
fit_reml!(model, data)
smoothing_parameters(model)
```

As in ordinary Unfold formulas, `0` on the left is a placeholder; the responses are supplied in `data`.

The bundled example retains the original grid RMSE of **0.0794**. [Example results and output data](results/two_predictors/RESULTS.md) include this package's predictions, coefficients, smoothing estimates and execution log. Across the research project's five saved cases, the largest absolute difference from its R-reference grid predictions is **1.2 × 10⁻⁸**. Native Unfold prediction and coefficient reporting are used in these comparisons.

## Dependencies and sources

The fitter retains the research project's pinned BSplineKit 0.19.3 and MixedModels 5.9.0 versions. R is used for the original reference comparisons, rather than as a runtime dependency.

Sources: [StatsModels formula extensions](https://juliastats.org/StatsModels.jl/stable/internals/#Extending-@formula-syntax), [Unfold spline terms](https://github.com/unfoldtoolbox/Unfold.jl/blob/ce1c795faf5968dc623e015fb25af03954e61047/ext/UnfoldBSplineKitExt/splinepredictors.jl), [Unfold custom solver interface](https://github.com/unfoldtoolbox/Unfold.jl/blob/ce1c795faf5968dc623e015fb25af03954e61047/src/fit.jl), and [mgcv smooth-to-random preparation](https://stat.ethz.ch/R-manual/R-devel/library/mgcv/html/smooth2random.html).
