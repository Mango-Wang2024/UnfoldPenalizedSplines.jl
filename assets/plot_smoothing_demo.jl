# Usage: julia --project=assets assets/plot_smoothing_demo.jl fits_file output_folder
import Makie
using CairoMakie, Serialization

fits = deserialize(ARGS[1])
design = fits.design
times = -0.1:0.01:0.5
predictor_values = get(fits, :predictor_values, (-2:0.2:2, -2:0.2:2))
out = ARGS[2]
mkpath(out)

mktempdir() do temporary
    row_offset = 0
    for (panel, (label, values)) in enumerate(zip(("x₁", "x₂"), predictor_values))
        colors = Makie.resample_cmap(:roma, length(values))
        bounds = extrema(values)
        fig = Figure(size=(420, 380), fontsize=16, backgroundcolor=:white)
        ax = Axis(fig[1, 1]; xlabel="Time [s]", ylabel="Voltage [µV]",
            xticks=[0.0, 0.2, 0.4], yticks=[-3.0, 0.0, 3.0, 6.0, 9.0],
            limits=(-0.1, 0.5, -7.5, 10.5), xgridvisible=false, ygridvisible=false)
        hidespines!(ax, :t, :r)
        Colorbar(fig[1, 2]; colormap=:roma, limits=bounds, ticks=range(bounds...; length=3),
            width=11, topspinecolor=:transparent, ticksvisible=false, ticklabelpad=7)
        Label(fig[1, 2, Top()], label)

        traces = [Observable(zeros(length(times))) for _ in values]
        for (trace, color) in zip(traces, colors)
            lines!(ax, times, trace; color, linewidth=1.6)
        end

        for (state, coefficients) in enumerate(fits.coefficients)
            weights = reshape(Float64.(coefficients), length(times), :)
            for (curve, trace) in enumerate(traces)
                trace[] = weights * Float64.(design[row_offset + curve, :])
            end
            png = joinpath(temporary, "plot.png")
            save(png, fig; px_per_unit=2)
            image = joinpath(out, "x$(panel)-$(state - 1).webp")
            run(`cwebp -quiet -lossless -z 6 $png -o $image`)
        end
        row_offset += length(values)
    end
end
