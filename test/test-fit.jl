using DataFrames: DataFrame, select
using DelimitedFiles: readdlm
using Statistics: mean
using StatsModels: @formula
import Unfold

@testset "Epoched fit and prediction" begin
    # Reuse the example's saved observations and its grid of known responses.
    folder = joinpath(@__DIR__, "..", "examples", "data")
    training_values, training_names = readdlm(joinpath(folder, "training.csv"), ',', Float64; header=true)
    grid_values, grid_names = readdlm(joinpath(folder, "prediction_grid.csv"), ',', Float64; header=true)
    training = DataFrame(training_values, Symbol.(vec(training_names)))
    grid = DataFrame(grid_values, Symbol.(vec(grid_names)))

    # Fit one channel at one time point and check both smoothing estimates.
    events = select(training, :x1, :x2)
    data = reshape(training.y, 1, 1, :)
    formula = @formula(0 ~ 1 + pspl(x1, 8) + pspl(x2, 8))
    model = fit_pspl(formula, events, data, [0.0])
    parameters = smoothing_parameters(model)
    @test sort(parameters.predictor) == ["x1", "x2"]
    @test all(λ -> isfinite(λ) && λ > 0, parameters.lambda)

    # The saved benchmark has an RMSE of about 0.0794. Allow room for solver variation.
    prediction = vec(only(Unfold.predict(model, select(grid, :x1, :x2); overlap=true)))
    @test length(prediction) == size(grid, 1)
    @test sqrt(mean(abs2, prediction - grid.truth)) < 0.1
end
