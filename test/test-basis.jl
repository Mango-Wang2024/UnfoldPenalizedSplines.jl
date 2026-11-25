using LinearAlgebra: eigmin, issymmetric

@testset "Cubic spline basis and penalty" begin
    # Build six cubic basis functions on a small grid with enough distinct points.
    x = range(-2, 2; length=11)
    k = 6
    knots = UnfoldPenalizedSplines.default_knots(x, k)
    spline = UnfoldPenalizedSplines.build_spline(x, knots)

    # The original basis sums to one at each point. Centering removes one column.
    @test length(knots) == k + 4
    @test size(spline.B_raw) == (length(x), k)
    @test vec(sum(spline.B_raw; dims=2)) ≈ ones(length(x))
    @test size(spline.B) == (length(x), k - 1)
    @test sum(spline.B; dims=1) ≈ zeros(1, k - 1) atol=1e-12

    # A squared-curvature penalty is symmetric and nonnegative up to roundoff.
    @test size(spline.S) == (k - 1, k - 1)
    @test issymmetric(spline.S)
    @test eigmin(spline.S) >= -1e-12
end
