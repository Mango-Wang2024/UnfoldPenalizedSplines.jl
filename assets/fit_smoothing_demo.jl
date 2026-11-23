using DataFrames, LinearAlgebra, StatsModels, Unfold, UnfoldPenalizedSplines

function smoothing_fits(model, data)
    X, response = Unfold.equalize_size(Unfold.modelmatrix(model), data)
    adapter = UnfoldPenalizedSplines.REMLAdapter(X, Unfold.formulas(model))
    gram = Matrix(X'X)
    rhs = Vector(X' * vec(response))

    x = collect(range(-2, 2; length=21))
    grid = DataFrame(x1=vcat(x, zeros(21)), x2=vcat(zeros(21), x))
    term = only(Unfold.formulas(model)).rhs.term
    design = Matrix(StatsModels.modelcols(term, grid))

    lambda = smoothing_parameters(model).lambda
    factors = [0.0, 0.001, 0.01, 0.1, 1.0, 10.0, 100.0, 1000.0]
    coefficients = Vector{Float64}[]
    for a in factors, b in factors
        penalized = copy(gram)
        for (columns, strength) in zip(adapter.random, lambda .* [a, b])
            for column in columns
                penalized[column, column] += strength
            end
        end
        push!(coefficients, cholesky!(Symmetric(penalized)) \ rhs)
    end

    # Use the same precision as the published demo inputs.
    return (; design=round.(design; digits=9),
            coefficients=[round.(coef; digits=6) for coef in coefficients])
end
