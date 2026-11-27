using Documenter

makedocs(;
    root=@__DIR__,
    sitename="UnfoldPenalizedSplines.jl",
    format=Documenter.HTML(; inventory_version="1.0.0"),
    pages=[
        "Home" => "index.md",
        "Tutorials" => ["Penalized splines for EEG" => "tutorials/erp_effects.md"],
        "How-to" => ["Adjust spline smoothing" => "howto/adjust_spline_smoothing.md"],
    ],
)
