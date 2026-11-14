struct REMLAdapter{T,M<:AbstractMatrix{T}} <: AbstractMatrix{T}
    X::M
    fixed::Vector{Int}
    random::Vector{Vector{Int}}
    components::Vector{String}
end

function REMLAdapter(X::AbstractMatrix, forms::AbstractVector{<:StatsModels.FormulaTerm})
    random = Vector{Int}[]
    components = String[]
    offset = 0
    for form in forms
        names = StatsModels.coefnames(form.rhs)
        # Expanded column names are "event : predictor column : lag".
        base_names = form.rhs isa Unfold.TimeExpandedTerm ?
            [split(name, " : ")[2] for name in names] : names
        for t in spline_terms(StatsModels.collect_matrix_terms(form.rhs))
            penalized = Set(StatsModels.coefnames(t)[2:end])
            push!(random, findall(in(penalized), base_names) .+ offset)
            push!(components, string(only(StatsModels.termvars(t))))
        end
        offset += length(names)
    end
    fixed = setdiff(collect(axes(X, 2)), reduce(vcat, random; init=Int[]))
    return REMLAdapter(X, fixed, random, components)
end

# The term owns these methods. Unfold calls this hook after assembling its matrix.
StatsModels.modelmatrix(::PenalizedSplineTerm, X::AbstractMatrix, forms) =
    REMLAdapter(X, forms)
StatsModels.modelmatrix(::PenalizedSplineTerm, X::REMLAdapter, forms) = X

# Keep Unfold's normal dimension checks, row alignment and prediction operations.
Base.size(adapter::REMLAdapter) = size(adapter.X)
Base.getindex(adapter::REMLAdapter, indices...) = getindex(adapter.X, indices...)
function Base.getindex(adapter::REMLAdapter, rows::AbstractVector, ::Colon)
    return REMLAdapter(adapter.X[rows, :], adapter.fixed, adapter.random, adapter.components)
end
Base.Matrix(adapter::REMLAdapter) = Matrix(adapter.X)
Base.Matrix{T}(adapter::REMLAdapter) where {T} = Matrix{T}(adapter.X)

Unfold.predict(adapter::REMLAdapter, coefficients::AbstractMatrix) =
    Unfold.predict(adapter.X, coefficients)
Unfold.predict(adapter::REMLAdapter{Tx}, coefficients::AbstractArray{Tc,3}) where
    {Tx<:Union{Missing,Number},Tc<:Union{Missing,Number}} =
    Unfold.predict(adapter.X, coefficients)

Unfold.solver_default(adapter::REMLAdapter, data::AbstractMatrix; kwargs...) =
    solve_reml(adapter, data)
Unfold.solver_default(adapter::REMLAdapter, data::AbstractArray{T,3}; kwargs...) where {T} =
    solve_reml(adapter, data)

function solve_reml(adapter::REMLAdapter, data::AbstractArray{T,N}) where {T,N}
    X = adapter.X
    Xf = Matrix{Float64}(X[:, adapter.fixed])
    Zs = [Matrix{Float64}(X[:, columns]) for columns in adapter.random]
    channels = size(data, 1)
    times = N == 3 ? size(data, 2) : 1
    shape = N == 3 ? (channels, times, size(X, 2)) : (channels, size(X, 2))
    coefficients = zeros(Float64, shape)
    fits = Matrix{NamedTuple}(undef, channels, times)
    for ch in 1:channels, t in 1:times
        y = N == 3 ? view(data, ch, t, :) : view(data, ch, :)
        fitted = SplineFit.fit_reml(y, Xf, Zs)
        # Match Unfold's column order for native prediction and coefficient tables.
        combined = zeros(size(X, 2))
        combined[adapter.fixed] = fitted.b
        for (columns, tau) in zip(adapter.random, fitted.tau)
            combined[columns] = tau
        end
        if N == 3
            coefficients[ch, t, :] = combined
        else
            coefficients[ch, :] = combined
        end
        fits[ch, t] = (; lambda=fitted.lambda, r2=fitted.r2, sigma2=fitted.sigma2,
                        objective=fitted.objective, status=fitted.status)
    end
    info = (; method=:REML, components=adapter.components, fits)
    return Unfold.LinearModelFit{Float64,N}(; estimate=coefficients, info)
end

# feature-bychannel supplies one matrix per channel to the default solver.
function Unfold.solver_default(adapters::AbstractVector{<:REMLAdapter},
                               data::AbstractArray{T,3}; kwargs...) where {T}
    results = [Unfold.solver_default(adapter, view(data, ch:ch, :, :); kwargs...)
               for (ch, adapter) in enumerate(adapters)]
    coefficients = cat((result.estimate for result in results)...; dims=1)
    fits = vcat((result.info.fits for result in results)...)
    info = (; method=:REML, components=first(adapters).components, fits)
    return Unfold.LinearModelFit{Float64,3}(; estimate=coefficients, info)
end

"""
    smoothing_parameters(uf)

Return the fitted lambda, spline variance and noise variance for each spline,
channel and epoched time point. For a time-expanded fit, each spline shares one
lambda across its lag columns; `time` is missing in the returned table.
"""
function smoothing_parameters(uf::Unfold.UnfoldModel)
    info = Unfold.modelfit(uf).info
    blocks = info isa NamedTuple ? [info] : info
    continuous = Unfold.SimpleTraits.istrait(Unfold.ContinuousTimeTrait{typeof(uf)})
    rows = NamedTuple[]
    for (event, block) in enumerate(blocks)
        block isa NamedTuple && block.method == :REML || continue
        for ch in axes(block.fits, 1), t in axes(block.fits, 2), j in eachindex(block.components)
            fitted = block.fits[ch, t]
            time = continuous ? missing : last(last(Unfold.design(uf)[event]))[t]
            push!(rows, (; event=continuous ? "combined" : string(first(Unfold.design(uf)[event])),
                          channel=ch, time, predictor=block.components[j],
                          lambda=fitted.lambda[j], r2=fitted.r2[j], sigma2=fitted.sigma2))
        end
    end
    return DataFrame(rows)
end
