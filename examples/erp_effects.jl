using Unfold, UnfoldPenalizedSplines, DataFrames, DelimitedFiles, Random, Serialization, Statistics
import UnfoldSim

# Pass the original predictor pairs through UnfoldSim's event design interface.
struct ERPDesign <: UnfoldSim.AbstractDesign
    events::DataFrame
end
Base.size(design::ERPDesign) = (nrow(design.events),)
UnfoldSim.generate_events(::AbstractRNG, design::ERPDesign) = copy(design.events)

p3_amplitude(x1, x2) = 5.0 + 4.0 * (sin(1.7x1) + 0.15x1) + 0.5cos(1.2x2)
at_lag(wave, lag) = get(wave, lag + 1, 0.0)

function save_table(file, table)
    open(file, "w") do io
        writedlm(io, permutedims(names(table)), ',')
        writedlm(io, Matrix(table), ',')
    end
end

values, header = readdlm(joinpath(@__DIR__, "data", "training.csv"), ',', Float64; header=true)
original = DataFrame(values, Symbol.(vec(header)))
rng = MersenneTwister(2026)
predictors = original[randperm(rng, nrow(original)), [:x1, :x2]]
predictors.p3_amplitude = p3_amplitude.(predictors.x1, predictors.x2)
sfreq = 100
p1 = UnfoldSim.p100(; sfreq)
n1 = UnfoldSim.n170(; sfreq)
p3 = UnfoldSim.p300(; sfreq)
# Keep the recording long enough for the full response window after the last event.
p3 = vcat(p3, zeros(51 - length(p3)))
components = [
    UnfoldSim.LinearModelComponent(; basis=p1, formula=@formula(0 ~ 1), β=[5.5]),
    UnfoldSim.LinearModelComponent(; basis=n1, formula=@formula(0 ~ 1), β=[6.0]),
    UnfoldSim.LinearModelComponent(; basis=p3, formula=@formula(0 ~ 0 + p3_amplitude), β=[1.0]),
]
design = ERPDesign(predictors)
onset = UnfoldSim.UniformOnset(; offset=20, width=30)
signal, _ = UnfoldSim.simulate(rng, design, components, onset)
observed, events = UnfoldSim.simulate(rng, design, components, onset,
                                      UnfoldSim.WhiteNoise(; noiselevel=0.8))
select!(events, :x1, :x2, :latency)
data = reshape(observed, 1, :)

function known_erp(t, x1, x2)
    lag = round(Int, t * sfreq)
    return 5.5at_lag(p1, lag) + 6.0at_lag(n1, lag) + p3_amplitude(x1, x2) * at_lag(p3, lag)
end

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
assets = joinpath(@__DIR__, "..", "assets")
plot_script = joinpath(assets, "plot_erp_effects.jl")
curves_file = joinpath(outdir, "curves.csv")
figure = joinpath(assets, "erp_effects.png")
run(`$(Base.julia_cmd()) --project=$assets $plot_script $curves_file $figure`)

# Pass a folder to also render both demo panels for every slider setting.
if !isempty(ARGS)
    include(joinpath(assets, "fit_smoothing_demo.jl"))
    fits = smoothing_fits(smoothed, data)
    mktemp() do path, io
        serialize(io, fits)
        close(io)
        demo_script = joinpath(assets, "plot_smoothing_demo.jl")
        run(`$(Base.julia_cmd()) --project=$assets $demo_script $path $(only(ARGS))`)
    end
end
