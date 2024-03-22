using Documenter, ComponentArrays

makedocs(;
    modules=[ComponentArrays],
    format=Documenter.HTML(
        canonical="https://jonniedie.github.io/ComponentArrays.jl/stable",
        ),
    pages=[
        "Home" => "index.md",
        "Quick Start" => "quickstart.md",
        "Indexing Behavior" => "indexing_behavior.md",
        "Unpacking to StaticArrays" => "static_unpack.md",
        "Examples" => [
            "examples/DiffEqFlux.md",
            "examples/adaptive_control.md",
            "examples/ODE_jac.md",
        ],
        "API" => "api.md",
    ],
    repo="https://github.com/jonniedie/ComponentArrays.jl/blob/{commit}{path}#L{line}",
    sitename="ComponentArrays.jl",
    authors="Jonnie Diegelman",
)

deploydocs(;
    repo="github.com/jonniedie/ComponentArrays.jl.git",
)
