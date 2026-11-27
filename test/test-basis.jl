using LinearAlgebra: eigmin, issymmetric

@testset "Cubic spline basis and penalty" begin
    # The training grid spans 0 to 20. The default knots extend beyond it.
    x = [0.0, 1.0, 2.0, 3.0, 5.0, 9.0, 20.0]
    k = 6
    knots = UnfoldPenalizedSplines.default_knots(x, k)
    spline = UnfoldPenalizedSplines.build_spline(x, knots)

    # The restored mgcv convention expands the range by 0.1% on each side.
    @test length(knots) == k + 4
    @test knots[[4, end - 3]] ≈ [-0.02, 20.02]
    @test diff(knots) ≈ fill(20.04 / (k - 3), k + 3)
    @test_throws ArgumentError UnfoldPenalizedSplines.default_knots(zeros(7), k)

    # The original basis sums to one at each point. Centering removes one column.
    @test size(spline.B_raw) == (length(x), k)
    @test vec(sum(spline.B_raw; dims=2)) ≈ ones(length(x))
    @test size(spline.B) == (length(x), k - 1)
    @test sum(spline.B; dims=1) ≈ zeros(1, k - 1) atol=1e-12

    # A squared-curvature penalty is symmetric and nonnegative up to roundoff.
    @test size(spline.S) == (k - 1, k - 1)
    @test issymmetric(spline.S)
    @test eigmin(spline.S) >= -1e-12
end
