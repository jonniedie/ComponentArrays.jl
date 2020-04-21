# ComponentArrays

## What is this useful for?
```ComponentArrays``` are useful for composing models together on the fly. The main targets are differential equations and optimization, but really anything that requires flat vectors is fair game.

### Differential equation example
This example uses ```@unpack``` from Parameters.jl for nice syntax. Example taken from:
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
lorenz_ic = (x=0.0, y=0.0, z=0.0)
lorenz_prob = ODEProblem(lorenz!, CArray(lorenz_ic), tspan, (lorenz_p, 0.0))


## Lotka-Volterra system
function lotka!(D, u, (p, f), t)
    @unpack α, β, γ, δ = p
    @unpack x, y = u
    
    D.x =  α*x - β*x*y + f
    D.y = -γ*y + δ*x*y
    return nothing
end

lotka_p = (α=2/3, β=4/3, γ=1.0, δ=1.0)
lotka_ic = (x=1.0, y=1.0)
lotka_prob = ODEProblem(lotka!, CArray(lotka_ic), tspan, (lotka_p, 0.0))


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
