# Usage: julia plot_erp_effects.jl /path/to/curves.csv erp-effects.png
# Uses the reference tutorial's UnfoldMakie / CairoMakie rendering stack.
# Reference: https://mango-wang2024.github.io/UnfoldDocs/Unfold.jl/stable/generated/HowTo/effects/
import Makie
using CairoMakie, UnfoldMakie, DelimitedFiles

values, _ = readdlm(ARGS[1], ',', Any; header=true)
curves = UnfoldMakie.DataFrame(time=Float64.(values[:,3]), x1=Float64.(values[:,4]),
                              yhat=Float64.(values[:,6]), method=String.(values[:,7]))

# Match the demo's font size and line widths.
figure_size = (900, 390)
scale = figure_size[1] / 600
font_size = 16
figure = Figure(size=figure_size, fontsize=font_size, figure_padding=16scale,
                fonts=(; regular="TeX Gyre Heros Makie"))
titles = ["(a) Unpenalized spline model", "(b) Penalized spline model"]
for (panel, method) in enumerate(["Unpenalized", "REML"])
    table = curves[curves.method .== method, :]
    plot_erp!(figure[1,panel], table;
        mapping=(; x=:time, y=:yhat, color=:x1, group=:x1 => nonnumeric),
        layout=(; show_legend=false),
        visual=(; colormap=:roma, linewidth=1.6),
        axis=(; title=titles[panel], titlefont=:regular, titlesize=font_size,
                titlealign=:left, titlegap=4scale,
                xlabel="Time [s]", ylabel=panel==1 ? "Voltage [µV]" : "",
                xlabelfont=:regular, ylabelfont=:regular,
                xticklabelfont=:regular, yticklabelfont=:regular,
                xlabelsize=font_size, ylabelsize=font_size,
                xticklabelsize=font_size, yticklabelsize=font_size,
                xlabelpadding=3scale, ylabelpadding=5scale,
                xticklabelpad=2scale, yticklabelpad=4scale,
                spinewidth=1, leftspinecolor=:black, bottomspinecolor=:black,
                xtickwidth=1, ytickwidth=1,
                xticksize=5, yticksize=5,
                xticks=[0.0,0.2,0.4], yticks=Float64.([-3,0,3,6,9]),
                limits=(-0.1,0.5,-7.5,10.5)))
end
Colorbar(figure[1,3]; colormap=:roma, limits=(-2,2), width=12,
         ticklabelsize=font_size, ticklabelfont=:regular,
         topspinecolor=:transparent, ticksvisible=false, ticklabelpad=7.5, ticks=[-2,0,2])
Label(figure[1,3,Top()], "x₁"; fontsize=font_size, font=:regular,
      padding=(0,0,4scale,0))
colgap!(figure.layout, 18scale)
save(ARGS[2], figure; px_per_unit=2)
save(replace(ARGS[2], r"\.png$" => ".svg"), figure)
println("Matching demo style: 16-unit text, 1.6-unit curves, 1-unit axes.")
