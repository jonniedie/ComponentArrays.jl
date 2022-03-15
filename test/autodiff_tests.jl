import FiniteDiff
import ForwardDiff
import ReverseDiff
import Zygote

using Test

F(x, θ, deg) = (θ[1] - x[1])^deg + θ[2] * (x[2] - x[1]^deg)^deg
F_idx_val(ca) = F(ca[Val(:x)], ca[Val(:θ)], ca[Val(:deg)])
F_idx_sym(ca) = F(ca[:x], ca[:θ], ca[:deg])
F_view_val(ca) = F(@view(ca[Val(:x)]), @view(ca[Val(:θ)]), ca[Val(:deg)])
F_view_sym(ca) = F(@view(ca[:x]), @view(ca[:θ]), ca[:deg])
F_prop(ca) = F(ca.x, ca.θ, ca.deg)

ca = ComponentArray(x = [1, 2], θ = [1.0, 100.0], deg = 2)
truth = [-400, 200]

@testset "$(nameof(F_))" for F_ in (F_idx_val, F_idx_sym, F_view_val, F_view_sym, F_prop)
    finite = FiniteDiff.finite_difference_gradient(ca -> F_(ca), ca).x
    @test finite ≈ truth

    forward = ForwardDiff.gradient(ca -> F_(ca), ca).x
    @test forward ≈ truth

    reverse = ReverseDiff.gradient(ca -> F_(ca), ca).x
    @test reverse ≈ truth

    zygote_full = Zygote.gradient(ca -> F_(ca), ca)[1]
    if F_ == F_prop && VERSION < v"1.3"
        @test_broken zygote_full.x ≈ truth
    else
        @test zygote_full.x ≈ truth
    end

    @test ComponentArray(x=4,) == Zygote.gradient(ComponentArray(x=2,)) do c
        (;c...,).x^2
    end[1]
end
