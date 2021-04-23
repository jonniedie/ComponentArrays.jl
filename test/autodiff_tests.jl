import FiniteDiff
import ForwardDiff
import ReverseDiff
# import Zygote

using Test

grads = let 
    F(x, θ, deg) = (θ[1] - x[1])^deg + θ[2] * (x[2] - x[1]^deg)^deg

    F_idx_val(ca) = F(ca[Val(:x)], ca[Val(:θ)], ca[Val(:deg)])
    F_idx_sym(ca) = F(ca[:x], ca[:θ], ca[:deg])
    F_prop(ca) = F(ca.x, ca.θ, ca.deg)

    ca = ComponentArray(x = [1, 2], θ = [1.0, 100.0], deg = 2)

    (
        truth = [-400, 200],
        finite = FiniteDiff.finite_difference_gradient(ca -> F_prop(ca), ca).x,
        forward = ForwardDiff.gradient(ca -> F_prop(ca), ca).x,
        reverse = ReverseDiff.gradient(ca -> F_prop(ca), ca).x,
        # zygote = Zygote.gradient(ca -> F(ca), ca)[1].x,
    )
end

@test grads.finite ≈ grads.truth
@test grads.forward ≈ grads.truth
@test grads.reverse ≈ grads.truth
# @test grads.zygote ≈ grads.truth