using Documenter

makedocs(;
    root=@__DIR__,
    sitename="UnfoldPenalizedSplines.jl",
    format=Documenter.HTML(; inventory_version="1.0.0"),
    pages=["Penalized splines" => "index.md"],
)
