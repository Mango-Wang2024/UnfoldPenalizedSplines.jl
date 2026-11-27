using DataFrames: DataFrame
using StatsModels: @formula
import Unfold

@testset "REML adapter column groups" begin
    # Build one epoched design matrix without estimating any coefficients.
    events = DataFrame(x1=range(-2, 2; length=12), x2=sin.(1:12))
    data = zeros(1, 1, size(events, 1))
    formula = @formula(0 ~ 1 + pspl(x1, 5) + pspl(x2, 5))
    model = Unfold.fit(Unfold.UnfoldModel, formula, events, data, [0.0]; fit=false)
    adapter = only(Unfold.modelmatrix(model))

    # The intercept and each spline's linear part stay unpenalized.
    # Each five-function spline contributes three penalized columns of its own.
    @test adapter isa UnfoldPenalizedSplines.REMLAdapter
    @test size(adapter.X) == (12, 9)
    @test adapter.components == ["x1", "x2"]
    @test adapter.fixed == [1, 2, 6]
    @test adapter.random == [collect(3:5), collect(7:9)]
end
