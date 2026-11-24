# Usage: julia --project=docs/scripts docs/scripts/plot_smoothing_demo.jl fits_file output_folder
using CairoMakie, DataFrames, Serialization, UnfoldMakie

fits = deserialize(ARGS[1])
design = fits.design
times = -0.1:0.01:0.5
tick_format = "{:.1f}"
predictor_values = fits.predictor_values
out = ARGS[2]
mkpath(out)

mktempdir() do temporary
    row_offset = 0
    for (panel, (label, values)) in enumerate(zip(("x₁", "x₂"), predictor_values))
        rows = (row_offset + 1):(row_offset + length(values))
        bounds = extrema(values)
        curves = DataFrame(time=repeat(times; outer=length(values)),
                           predictor=repeat(values; inner=length(times)))

        for (state, coefficients) in enumerate(fits.coefficients)
            weights = reshape(coefficients, length(times), :)
            curves.yhat = vec(weights * transpose(design[rows, :]))
            fig = Figure(size=(420, 380), fontsize=16, backgroundcolor=:white)
            plot_erp!(fig[1, 1], curves;
                mapping=(; y=:yhat, color=:predictor, group=:predictor => nonnumeric),
                axis=(; limits=(-0.1, 0.5, -7.5, 10.5), yticklabelsize=16,
                      xticks=[0.0, 0.2, 0.4], yticks=[-3, 0, 3, 6, 9],
                      xtickformat=tick_format, ytickformat=tick_format),
                visual=(; colormap=:roma, linewidth=1.6), layout=(; show_legend=false))
            Colorbar(fig[1, 2]; colormap=:roma, limits=bounds, ticks=range(bounds...; length=3),
                tickformat=tick_format, ticklabelspace=34, ticklabelpad=7,
                width=11, topspinecolor=:transparent, ticksvisible=false)
            Label(fig[1, 2, Top()], label)
            png = joinpath(temporary, "plot.png")
            save(png, fig; px_per_unit=2)
            image = joinpath(out, "x$(panel)-$(state - 1).webp")
            run(`cwebp -quiet -lossless -z 6 $png -o $image`)
        end
        row_offset += length(values)
    end
end
