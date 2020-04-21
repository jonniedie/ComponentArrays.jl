using ComponentArrays
using Optim

rosen(u) = (1.0 - u.x)^2 + 100.0 * (u.y - u.x^2)^2

u₀ = CArray(x=0, y=0)
lb = CArray(x=-0.5, y=-0.5)
ub = CArray(x=0.5, y=0.5)

df = TwiceDifferentiable(rosen, u₀; autodiff=:forward)
dfc = TwiceDifferentiableConstraints(lb, ub)

val = optimize(df, dfc, u₀, IPNewton())
