using DataFrames, LinearAlgebra, StatsModels, Unfold, UnfoldPenalizedSplines

function smoothing_fits(model, data;
                        predictor_values=(range(-2, 2; length=21), range(0, 1; length=21)),
                        held_values=(0.0, 0.5))
    adapter, response = Unfold.equalize_size(Unfold.modelmatrix(model), data)
    X = adapter.X
    gram = Matrix(X'X)
    rhs = Vector(X' * vec(response))

    x1, x2 = predictor_values
    grid = DataFrame(x1=vcat(x1, fill(held_values[1], length(x2))),
                     x2=vcat(fill(held_values[2], length(x1)), x2))
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
    return (; predictor_values, design=round.(design; digits=9),
            coefficients=[round.(coef; digits=6) for coef in coefficients])
end
