using Test, UnfoldPenalizedSplines

# Run the matrix and column checks before the full model fits.
include("test-basis.jl")
include("test-terms.jl")
include("test-adapter.jl")
include("test-fit.jl")
include("test-continuous.jl")
