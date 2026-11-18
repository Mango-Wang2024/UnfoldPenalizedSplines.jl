# Marginal ERP effects: fixed basis and REML smoothing

<img src="../../assets/erp_effects.svg" alt="Unpenalized and REML-smoothed marginal ERP effects" width="1000">

Both panels use **8 basis functions per predictor**, the same simulated recording and the same time-expanded design. The left fit has no smoothing penalty; the right fit estimates each predictor's smoothing strength with REML. The basis size stays fixed.

Each colored curve is Unfold's `effects` prediction at one $x_1$ value, with $x_2=0$. These are predicted responses to an individual event, without overlap from other events. Colors identify predictor values, not error or smoothing strength. Curves need not follow the color order vertically because the simulated effect of $x_1$ is nonlinear.

## Results

RMSE against the known simulated response, across the **21 predictor values × 61 time points shown**:

| Fit | RMSE (µV) |
| --- | ---: |
| Unpenalized, $k=8$ | 0.20825 |
| REML smoothing, $k=8$ | 0.15229 |

REML selected $\lambda_1=0.72330$ and $\lambda_2=93.33883$. Each value is shared across that predictor's lag columns. This penalizes curvature across predictor values; it does not add a separate smoothness penalty along time. These results describe this simulation, rather than a general accuracy guarantee.

## Data and workflow

The example reuses the original **200 pairs of predictor values**, randomly orders them into events, and simulates a continuous EEG recording with overlapping responses. Sampling is **100 Hz**, the response window is **−0.1 to 0.5 s**, event intervals are **0.2–0.5 s**, and Gaussian noise has standard deviation **0.8 µV** (seed 2026).

The early positive and negative peaks are shared across events. The later positive peak's amplitude depends on the project's original additive function, $\sin(1.7x_1)+0.15x_1+0.5\cos(1.2x_2)$; the exact simulation is defined in [known_erp](../../examples/erp_effects.jl).

`Continuous recording + events → Unfold time expansion → fit → effects → predicted ERP curves`

This is the same figure as in the [penalized spline tutorial](https://mango-wang2024.github.io/UnfoldDocs/UnfoldPenalizedSplines.jl/). It uses UnfoldMakie and CairoMakie to plot the predictions from both fits.

## Files and reproduction

| File | Contents |
| --- | --- |
| [erp_effects.jl](../../examples/erp_effects.jl) | Simulation, both fits and native Unfold `effects` calls. |
| [plot_erp_effects.jl](../../assets/plot_erp_effects.jl) | Makie figure layout and colors. |
| [curves.csv](curves.csv) | Both fits' plotted predictions and known responses. |
| [summary.csv](summary.csv) | RMSE values. |
| [smoothing_parameters.csv](smoothing_parameters.csv) | REML smoothing and variance estimates. |
| [events.csv](events.csv) | Event onsets and predictor values. |
| [recording.csv](recording.csv) | Clean and noisy simulated recording. |
| [run.log](run.log) | Execution output. |

To redraw the saved predictions, run these commands from the repository root:

```sh
julia --project=assets -e 'using Pkg; Pkg.instantiate()'
julia --project=assets assets/plot_erp_effects.jl results/erp_effects/curves.csv assets/erp_effects.png
```

To repeat the simulation and both fits before drawing the figure, install the plotting dependencies as above, then run `julia --project=. examples/erp_effects.jl` from the package environment.
