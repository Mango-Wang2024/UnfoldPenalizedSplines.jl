using DataFrames: DataFrame
using Random: MersenneTwister, randn
using StatsModels: @formula
import Unfold

@testset "Continuous fit and time expansion" begin
    # Place three-sample responses five samples apart so they never overlap.
    events = DataFrame(x=range(-2, 2; length=40), latency=3:5:198)
    waveform = [1.0, 2.0, 1.0]
    data = 0.02 .* randn(MersenneTwister(1), 1, last(events.latency) + 4)
    for (x, onset) in zip(events.x, events.latency)
        data[1, onset:(onset + 2)] .+= sin(x) .* waveform
    end

    # The three response lags share one smoothing strength for this spline.
    formula = @formula(0 ~ 1 + pspl(x, 6))
    basis = Unfold.firbasis(τ=(0.0, 0.02), sfreq=100; interpolate=false)
    model = fit_pspl(formula, events, data, basis)
    parameters = smoothing_parameters(model)
    @test parameters.predictor == ["x"]
    @test ismissing(only(parameters.time))

    # Predict one response and check its requested times and known shape.
    curve = Unfold.effects(Dict(:x => [1.0]), model)
    @test curve.time ≈ [0.0, 0.01, 0.02]
    @test curve.yhat ≈ sin(1.0) .* waveform atol=0.1
end
