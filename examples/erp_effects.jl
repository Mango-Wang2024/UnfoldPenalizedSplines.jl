using Unfold, UnfoldPenalizedSplines, DataFrames, DelimitedFiles, Random, Statistics

# Add a time course to the original two-predictor example. Values are simulated µV.
function known_erp(t, x1, x2)
    p1 = 5.5 * exp(-0.5 * ((t - 0.085) / 0.016)^2)
    n1 = -6.0 * exp(-0.5 * ((t - 0.155) / 0.025)^2)
    amplitude = 5.0 + 4.0 * (sin(1.7x1) + 0.15x1) + 0.5cos(1.2x2)
    p3 = amplitude * exp(-0.5 * ((t - 0.285) / 0.055)^2)
    return p1 + n1 + p3
end

function save_table(file, table)
    open(file, "w") do io
        writedlm(io, permutedims(names(table)), ',')
        writedlm(io, Matrix(table), ',')
    end
end

values, header = readdlm(joinpath(@__DIR__, "data", "training.csv"), ',', Float64; header=true)
original = DataFrame(values, Symbol.(vec(header)))
rng = MersenneTwister(2026)
events = original[randperm(rng, nrow(original)), [:x1, :x2]]
events.latency = 50 .+ cumsum(rand(rng, 20:50, nrow(events)))
sfreq = 100
lags = -10:50
signal = zeros(last(events.latency) + last(lags) + 50)
for event in eachrow(events), lag in lags
    signal[event.latency + lag] += known_erp(lag / sfreq, event.x1, event.x2)
end
data = reshape(signal + 0.8randn(rng, length(signal)), 1, :)

# Both fits use exactly the same basis size, observations and time-expanded design.
formula = @formula(0 ~ 1 + pspl(x1, 8) + pspl(x2, 8))
basis = firbasis(τ=(-0.1, 0.5), sfreq=sfreq; interpolate=false)
println("Fitting fixed-basis unpenalized model...")
flush(stdout)
fixed = fit(UnfoldModel, formula, events, data, basis;
            solver=(X, y) -> Unfold.solver_default(X.X, y))
println("Fitting REML-smoothed model...")
flush(stdout)
smoothed = fit(UnfoldModel, formula, events, data, basis)

# Each row of the reference grid generates an event-related curve without overlap.
reference = Dict(:x1 => collect(range(-2, 2; length=21)), :x2 => [0.0])
tables = DataFrame[]
for (name, model) in [("Unpenalized", fixed), ("REML", smoothed)]
    table = effects(reference, model)
    table.method = fill(name, nrow(table))
    table.truth = known_erp.(table.time, table.x1, table.x2)
    push!(tables, table)
end
curves = vcat(tables...)
summary = combine(groupby(curves, :method),
                  [:yhat, :truth] => ((p, t) -> sqrt(mean(abs2, p - t))) => :rmse)
outdir = joinpath(@__DIR__, "..", "results", "erp_effects")
mkpath(outdir)
save_table(joinpath(outdir, "curves.csv"), curves)
save_table(joinpath(outdir, "summary.csv"), summary)
save_table(joinpath(outdir, "smoothing_parameters.csv"), smoothing_parameters(smoothed))
save_table(joinpath(outdir, "events.csv"), events)
save_table(joinpath(outdir, "recording.csv"),
           DataFrame(sample=1:length(signal), clean=signal, observed=vec(data)))
println(summary)
println(smoothing_parameters(smoothed))
figure = joinpath(@__DIR__, "..", "assets", "erp_effects.png")
run(`Rscript $(joinpath(@__DIR__, "..", "assets", "plot_erp_effects.R")) $outdir $figure`)
