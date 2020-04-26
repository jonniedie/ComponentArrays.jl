using Documenter, ComponentArrays

makedocs(;
    modules=[ComponentArrays],
    format=Documenter.HTML(
        canonical = "https://jonniedie.github.io/ComponentArrays.jl/stable",
        ),
    pages=[
        "Home" => "index.md",
    ],
    repo="https://github.com/jonniedie/ComponentArrays.jl/blob/{commit}{path}#L{line}",
    sitename="ComponentArrays.jl",
    authors="Jonnie Diegelman",
    assets=String[],
)

deploydocs(;
    repo="github.com/jonniedie/ComponentArrays.jl.git",
)
