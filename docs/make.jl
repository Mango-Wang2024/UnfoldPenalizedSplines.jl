using Documenter

makedocs(;
    root=@__DIR__,
    sitename="UnfoldPenalizedSplines.jl",
    format=Documenter.HTML(; inventory_version="1.0.0"),
    pages=["Penalized splines" => "index.md"],
)

deploydocs(;
    root=@__DIR__,
    repo="github.com/Mango-Wang2024/UnfoldPenalizedSplines.jl.git",
    devbranch="main",
    versions=nothing,
)
