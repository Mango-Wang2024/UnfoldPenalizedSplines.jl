# Run with CairoMakie, Makie and JSON in the Julia environment, and cwebp on PATH.
import Makie
using CairoMakie, JSON

fits = JSON.parsefile(joinpath(@__DIR__, "smoothing-fits.json"))
# Each row of the design evaluates one of the 21 curves in one panel.
design = reduce(vcat, permutedims.(fits["design"]))
times = -0.1:0.01:0.5
predictor_values = -2:0.2:2
colors = Makie.resample_cmap(:roma, length(predictor_values))
out = joinpath(@__DIR__, "smoothing-plots")
mkpath(out)

mktempdir() do temporary
    for (panel, label) in enumerate(("x₁", "x₂"))
        fig = Figure(size=(420, 380), fontsize=16, backgroundcolor=:white)
        ax = Axis(fig[1, 1]; xlabel="Time [s]", ylabel="Voltage [µV]",
            xticks=[0.0, 0.2, 0.4], yticks=[-3.0, 0.0, 3.0, 6.0, 9.0],
            limits=(-0.1, 0.5, -7.5, 10.5), xgridvisible=false, ygridvisible=false)
        hidespines!(ax, :t, :r)
        Colorbar(fig[1, 2]; colormap=:roma, limits=(-2, 2), ticks=[-2, 0, 2],
            width=11, topspinecolor=:transparent, ticksvisible=false, ticklabelpad=7)
        Label(fig[1, 2, Top()], label)

        traces = [Observable(zeros(length(times))) for _ in predictor_values]
        for (trace, color) in zip(traces, colors)
            lines!(ax, times, trace; color, linewidth=1.6)
        end

        for (state, coefficients) in enumerate(fits["coefficients"])
            weights = reshape(Float64.(coefficients), length(times), :)
            for (curve, trace) in enumerate(traces)
                row = (panel - 1) * length(traces) + curve
                trace[] = weights * Float64.(design[row, :])
            end
            png = joinpath(temporary, "plot.png")
            save(png, fig; px_per_unit=2)
            image = joinpath(out, "x$(panel)-$(state - 1).webp")
            run(`cwebp -quiet -lossless -z 6 $png -o $image`)
        end
    end
end
