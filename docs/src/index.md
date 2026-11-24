# Penalized splines

Use the same spline basis to fit the simulated EEG with and without a smoothing penalty. The penalized fit estimates one smoothing strength per predictor using REML.

## Setup

```@raw html
<details><summary>Install the packages</summary>
```

```julia
using Pkg
Pkg.activate(mktempdir())
Pkg.add([
    Pkg.PackageSpec(name="Unfold"),
    Pkg.PackageSpec(url="https://github.com/unfoldtoolbox/UnfoldSim.jl",
                    rev="994f253c2fa0d918357c94180b206732e0b7b2ae"),
    Pkg.PackageSpec(url="https://github.com/Mango-Wang2024/UnfoldPenalizedSplines.jl"),
    Pkg.PackageSpec(name="CairoMakie"),
])
```

```@raw html
</details>
```

```julia
using Unfold
using UnfoldSim
using UnfoldPenalizedSplines
using CairoMakie
```

## Simulate EEG with a nonlinear effect

Use UnfoldSim to set the P300 amplitude to 5 + x₁ + 0.2x₁². The second predictor, x₂, is generated after the EEG, so its true effect is zero.

```julia
p3 = (
    p300(; sfreq = 100),
    @formula(0 ~ 1 + continuous + continuous^2),
    [5, 1, 0.2],
    Dict(),
    0,
)
data, evts = UnfoldSim.predef_eeg(; noiselevel = 8, p3 = p3)
evts.x1 = evts.continuous
evts.x2 = rand(UnfoldSim.MersenneTwister(1), size(evts, 1))
```

## Fit the spline models

Fit both models over the same window, from −100 to +500 ms relative to each event.

```julia
formula = @formula(0 ~ 1 + pspl(x1, 8) + pspl(x2, 8))
basis = firbasis(τ=(-0.1, 0.5), sfreq=100; interpolate=false)

unpenalized = Unfold.fit(UnfoldModel, formula, evts, data, basis)
penalized = fit_pspl(formula, evts, data, basis)
```

## Plot the marginal effects

Predict the EEG at 21 values of x₁ while holding x₂ at 0.5. Each color represents one x₁ value.

```julia
grid = Dict(:x1 => collect(range(-2, 2; length=21)), :x2 => [0.5])
predictions = (effects(grid, unpenalized), effects(grid, penalized))
colors = CairoMakie.Makie.resample_cmap(:roma, length(grid[:x1]))
figure = Figure(size=(850, 380), fontsize=16, backgroundcolor=:white)

for (panel, (title, curves)) in enumerate(zip(("Unpenalized", "Penalized"), predictions))
    ax = Axis(figure[1, panel]; title, titlefont=:regular, titlealign=:left,
        xlabel="Time [s]", ylabel="Voltage [µV]",
        xticks=[0.0, 0.2, 0.4], yticks=[-3.0, 0.0, 3.0, 6.0, 9.0],
        limits=(-0.1, 0.5, -7.5, 10.5), xgridvisible=false, ygridvisible=false)
    hidespines!(ax, :t, :r)
    for (x1, color) in zip(grid[:x1], colors)
        curve = curves[curves.x1 .== x1, :]
        lines!(ax, curve.time, curve.yhat; color, linewidth=1.6)
    end
end

Colorbar(figure[1, 3]; colormap=:roma, limits=(-2, 2), ticks=[-2, 0, 2],
    width=11, topspinecolor=:transparent, ticksvisible=false, ticklabelpad=7)
Label(figure[1, 3, Top()], "x₁")
figure
```

![Predicted EEG responses across x₁ from the unpenalized and penalized fits, with x₂ held at 0.5](assets/erp-effects.svg)

## Adjust spline smoothing

Both sliders start at the REML estimates. Move either one to change how much its spline can bend across predictor values. The left plot varies x₁ at x₂ = 0.5, and the right plot varies x₂ from 0 to 1 at x₁ = 0.

```@raw html
<iframe id="spline-smoothing-demo" src="assets/smoothing-demo.htm?v=pluto" title="Adjust the smoothing strengths of the x1 and x2 splines" loading="lazy" style="display: block; width: 100%; height: 720px; border: 0; background: white; color-scheme: only light;"></iframe>
<script src="assets/embed-demo.js"></script>
```

[Demo fitting](https://github.com/Mango-Wang2024/UnfoldPenalizedSplines.jl/blob/main/assets/fit_smoothing_demo.jl) · [Demo plots](https://github.com/Mango-Wang2024/UnfoldPenalizedSplines.jl/blob/main/assets/plot_smoothing_demo.jl)
