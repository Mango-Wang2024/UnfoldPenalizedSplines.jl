struct REMLAdapter{M<:AbstractMatrix}
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

"""
    fit_pspl(formula, events, data, basis_or_times; kwargs...)
    fit_pspl(design, events, data; kwargs...)

Fit penalized spline terms with REML and return a standard Unfold model.
Pass a FIR basis for continuous recordings or a vector of times for epoched data.
"""
fit_pspl(formula::StatsModels.FormulaTerm, events, data, basis_or_times; kwargs...) =
    fit_pspl([Any => (formula, basis_or_times)], events, data; kwargs...)

function fit_pspl(design::Vector, events, data::AbstractArray; kwargs...)
    model = Unfold.fit(Unfold.UnfoldModel, design, events, data; fit=false, kwargs...)
    response = Unfold.check_data(typeof(model), data)
    forms = Unfold.formulas(model)
    if ndims(response) == 3
        # Unfold calls the solver once per event design for epoched data.
        by_matrix = IdDict(zip(Unfold.modelmatrix(model), forms))
        solver = (X, y) -> solve_reml(X, y, [by_matrix[X]])
    else
        solver = (X, y) -> solve_reml(X, y, forms)
    end
    Unfold.fit!(model, response; solver)
    return model
end

function solve_reml(X::AbstractMatrix, data, forms)
    adapter = REMLAdapter(X, forms)
    isempty(adapter.random) && return Unfold.solver_default(X, data)
    return solve_reml(adapter, data)
end

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

# With bychannel(), Unfold passes a separate design matrix for each channel.
function solve_reml(matrices::AbstractVector{<:AbstractMatrix}, data::AbstractArray{T,3},
                    forms) where {T}
    adapters = [REMLAdapter(X, forms) for X in matrices]
    isempty(first(adapters).random) && return Unfold.solver_default(matrices, data)
    results = [solve_reml(adapter, view(data, ch:ch, :, :))
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
