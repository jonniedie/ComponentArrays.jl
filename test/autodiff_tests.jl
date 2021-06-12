import FiniteDiff
import ForwardDiff
import ReverseDiff
import Zygote

using Test

F(x, θ, deg) = (θ[1] - x[1])^deg + θ[2] * (x[2] - x[1]^deg)^deg
F_idx_val(ca) = F(ca[Val(:x)], ca[Val(:θ)], ca[Val(:deg)])
F_idx_sym(ca) = F(ca[:x], ca[:θ], ca[:deg])
F_prop(ca) = F(ca.x, ca.θ, ca.deg)

ca = ComponentArray(x = [1, 2], θ = [1.0, 100.0], deg = 2)
truth = [-400, 200]

@testset "$(nameof(F_))" for F_ in (F_idx_val, F_idx_sym, F_prop)
    finite = FiniteDiff.finite_difference_gradient(ca -> F_(ca), ca).x
    @test finite ≈ truth

    forward = ForwardDiff.gradient(ca -> F_(ca), ca).x
    @test forward ≈ truth

    reverse = ReverseDiff.gradient(ca -> F_(ca), ca).x
    if F_ in (F_idx_val, F_idx_sym)
        @test_broken reverse ≈ truth
    else
        @test reverse ≈ truth
    end

    zygote = Zygote.gradient(ca -> F_(ca), ca)[1].x
    @test zygote ≈ truth
end
