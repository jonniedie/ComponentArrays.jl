# ComponentArrays.jl
The main export of this package is the ````CArray```` type. "Components" of ````CArray````s
are really just matrix blocks that can be accessed through a named index. The magic here is
that this named indexing can create a new ```CArray``` whose data is a view into the original,
allowing for standalone models to be composed together by simple function composition. In
essence, ```CArray```s allow you to do the things you would usually need a modeling
language for, but without actually needing a modeling language. The main targets are for use
in [DifferentialEquations.jl](https://github.com/SciML/DifferentialEquations.jl) and
[Optim.jl](https://github.com/JuliaNLSolvers/Optim.jl), but anything that requires
flat vectors is fair game.

## General use
The easiest way to construct 1-dimensional ```CArray```s is as if they were ```NamedTuple```s. In fact, a good way to think about them is as arbitrarily nested, mutable ```NamedTuple```s that can be passed through a solver.
```julia
julia> c = (a=2, b=[1, 2]);
  
julia> x = CArray(a=1, b=[2, 1, 4], c=c)
CArray{Float64}(a = 1.0, b = [2.0, 1.0, 4.0], c = (a = 2.0, b = [1.0, 2.0]))
  
julia> x.c.a = 400; x
CArray{Float64}(a = 1.0, b = [2.0, 1.0, 4.0], c = (a = 400.0, b = [1.0, 2.0]))
  
julia> x[5]
400.0
  
julia> collect(x)
7-element Array{Float64,1}:
   1.0
   2.0
   1.0
   4.0
 400.0
   1.0
   2.0

julia> typeof(similar(x, Int32)) === typeof(CArray{Int32}(a=1, b=[2, 1, 4], c=c))
true
```

Higher dimensional ```CArray```s can be created too, but it's a little messy at the moment. The nice thing for modeling is that dimension expansion through broadcasted operations can create higher-dimensional ```CArray```s automatically, so Jacobian cache arrays that are created internally with ```false .* x .* x'``` will be ```CArray```s with proper axes.
```julia
julia> x2 = x .* x'
7×7 CArray{Tuple{Axis{(a = 1, b = 2:4, c = (5:7, (a = 1, b = 2:3)))},Axis{(a = 1, b = 2:4, c = (5:7, (a = 1, b = 2:3)))}},Float64,2,Array{Float64,2}}:
 1.0  2.0  1.0   4.0  2.0  1.0  2.0
 2.0  4.0  2.0   8.0  4.0  2.0  4.0
 1.0  2.0  1.0   4.0  2.0  1.0  2.0
 4.0  8.0  4.0  16.0  8.0  4.0  8.0
 2.0  4.0  2.0   8.0  4.0  2.0  4.0
 1.0  2.0  1.0   4.0  2.0  1.0  2.0
 2.0  4.0  2.0   8.0  4.0  2.0  4.0
 
julia> x2[:c,:c]
3×3 CArray{Tuple{Axis{(a = 1, b = 2:3)},Axis{(a = 1, b = 2:3)}},Float64,2,SubArray{Float64,2,Array{Float64,2},Tuple{UnitRange{Int64},UnitRange{Int64}},false}}:
 4.0  2.0  4.0
 2.0  1.0  2.0
 4.0  2.0  4.0
 
julia> x2[:a,:a]
 1.0
 
julia> x2[:a,:c]
CArray{Float64}(a = 2.0, b = [1.0, 2.0])

julia> x2[:b,:c]
3×3 CArray{Tuple{Axis{NamedTuple()},Axis{(a = 1, b = 2:3)}},Float64,2,SubArray{Float64,2,Array{Float64,2},Tuple{UnitRange{Int64},UnitRange{Int64}},false}}:
 4.0  2.0  4.0
 2.0  1.0  2.0
 8.0  4.0  8.0
```


## Examples
### Differential equation example
This example uses ```@unpack``` from [Parameters.jl](https://github.com/mauro3/Parameters.jl)
for nice syntax. Example taken from:
https://github.com/JuliaDiffEq/ModelingToolkit.jl/issues/36#issuecomment-536221300
```julia
using ComponentArrays
using DifferentialEquations
using Parameters: @unpack


tspan = (0.0, 20.0)


## Lorenz system
function lorenz!(D, u, (p, f), t)
    @unpack σ, ρ, β = p
    @unpack x, y, z = u
    
    D.x = σ*(y - x)
    D.y = x*(ρ - z) - y - f
    D.z = x*y - β*z
    return nothing
end

lorenz_p = (σ=10.0, ρ=28.0, β=8/3)
lorenz_ic = CArray(x=0.0, y=0.0, z=0.0)
lorenz_prob = ODEProblem(lorenz!, lorenz_ic, tspan, (lorenz_p, 0.0))


## Lotka-Volterra system
function lotka!(D, u, (p, f), t)
    @unpack α, β, γ, δ = p
    @unpack x, y = u
    
    D.x =  α*x - β*x*y + f
    D.y = -γ*y + δ*x*y
    return nothing
end

lotka_p = (α=2/3, β=4/3, γ=1.0, δ=1.0)
lotka_ic = CArray(x=1.0, y=1.0)
lotka_prob = ODEProblem(lotka!, lotka_ic, tspan, (lotka_p, 0.0))


## Composed Lorenz and Lotka-Volterra system
function composed!(D, u, p, t)
    c = p.c #coupling parameter
    @unpack lorenz, lotka = u
    
    lorenz!(D.lorenz, lorenz, (p.lorenz, c*lotka.x), t)
    lotka!(D.lotka, lotka, (p.lotka, c*lorenz.x), t)
    return nothing
end

comp_p = (lorenz=lorenz_p, lotka=lotka_p, c=0.01)
comp_ic = CArray(lorenz=lorenz_ic, lotka=lotka_ic)
comp_prob = ODEProblem(composed!, comp_ic, tspan, comp_p)


## Solve problem
# We can solve the composed system...
comp_sol = solve(comp_prob)

# ...or we can unit test one of the component systems
lotka_sol = solve(lotka_prob)
```

Notice how cleanly the ```composed!``` function can pass variables from one function to another with no array index juggling in sight. This is especially useful for large models as it becomes harder to keep track top-level model array position when adding new or deleting old components from the model. We could go further and compose ```composed!``` with other components ad (practically) infinitum with no mental bookkeeping.

The main benefit, however, is now our differential equations are unit testable. Both ```lorenz``` and ```lotka``` can be run as their own ```ODEProblem``` with ```f``` set to zero to see the unforced response.
