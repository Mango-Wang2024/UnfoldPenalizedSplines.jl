# Adjust spline smoothing

This demo uses the data and spline basis from the [EEG tutorial](../tutorials/erp_effects.md).

Both sliders start at the REML estimates. Move either one to change how much its spline can bend across predictor values. The left plot varies x₁ at x₂ = 0.5, and the right plot varies x₂ from 0 to 1 at x₁ = 0.

```@raw html
<iframe id="spline-smoothing-demo" src="../../assets/smoothing-demo.htm?v=quantile-knots" title="Adjust the smoothing strengths of the x1 and x2 splines" loading="lazy" style="display: block; width: 100%; height: 720px; border: 0; background: white; color-scheme: only light;"></iframe>
<script src="../../assets/embed-demo.js"></script>
```

[Demo fitting](https://github.com/Mango-Wang2024/UnfoldPenalizedSplines.jl/blob/main/docs/scripts/fit_smoothing_demo.jl) · [Demo plots](https://github.com/Mango-Wang2024/UnfoldPenalizedSplines.jl/blob/main/docs/scripts/plot_smoothing_demo.jl)
