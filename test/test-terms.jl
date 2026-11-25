using StatsModels: @formula, StatisticalModel, apply_schema, modelcols, schema

@testset "The pspl formula term" begin
    # Eight cubic basis functions require twelve full knot entries.
    @test_throws ArgumentError pspl(:x, 8; knots=[0.0, 1.0])

    # Apply the formula to numeric data and build the centered spline columns.
    training = (x=collect(range(-2, 2; length=11)),)
    formula = @formula(0 ~ 0 + pspl(x, 6))
    term = apply_schema(formula, schema(formula, training), StatisticalModel).rhs
    columns = modelcols(term, training)
    @test size(columns) == (11, 5)

    # Evaluating a row on its own should reuse the same fitted spline basis.
    point = (x=[training.x[3]],)
    @test modelcols(term, point) ≈ columns[3:3, :]
end
