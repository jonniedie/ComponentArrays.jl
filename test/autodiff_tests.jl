import FiniteDiff, ForwardDiff, ReverseDiff, Tracker, Zygote

using Test

F(a, x) = sum(abs2, a) * x^3
F_idx_val(ca) = F(ca[Val(:a)], ca[Val(:x)])
F_idx_sym(ca) = F(ca[:a], ca[:x])
F_view_val(ca) = F(@view(ca[Val(:a)]), ca[Val(:x)])
F_view_sym(ca) = F(@view(ca[:a]), ca[:x])
F_prop(ca) = F(ca.a, ca.x)

ca = ComponentArray(a=[2, 3], x=2.0)
truth = ComponentArray(a = [32, 48], x = 156)

@testset "$(nameof(F_))" for F_ in (F_idx_val, F_idx_sym, F_view_val, F_view_sym, F_prop)
    finite = FiniteDiff.finite_difference_gradient(F_, ca)
    @test finite ≈ truth

    forward = ForwardDiff.gradient(F_, ca)
    @test forward ≈ truth

    reverse = ReverseDiff.gradient(F_, ca)
    @test reverse ≈ truth

    tracker = Tracker.gradient(F_, ca)[1]
    @test tracker ≈ truth

    zygote_full = Zygote.gradient(F_, ca)[1]
    @test zygote_full ≈ truth

    @test ComponentArray(x=4.0,) ≈ Zygote.gradient(ComponentArray(x=2,)) do c
        (;c...,).x^2
    end[1]

    # Issue #148
    ps = ComponentArray(;bias = rand(4))
    out = Zygote.gradient(x -> sum(x.^3 .+ ps.bias), Zygote.seed(rand(4),Val(12)))[1]
    @test out isa Vector{<:ForwardDiff.Dual}
end

@testset "Projection" begin
    gs_ca = Zygote.gradient(sum, ca)[1]

    @test gs_ca isa ComponentArray
end

@testset "Higher Order" begin
    r = rand(Float32, 1, 128)
    ps = (; weight = rand(Float32, 1, 1), bias = rand(Float32, 1))
    ps2 = ComponentArray(ps)

    function loss_function(weight, bias, r)
        mz, back = Zygote.pullback(r) do r
            weight * r .+ bias
        end
        ep = only(back(ones(size(r))))
        return sum(mz) + sum(ep)
    end

    function loss_function(p, r)
        mz, back = Zygote.pullback(r) do r
            p.weight * r .+ p.bias
        end
        ep = only(back(ones(size(r))))
        return sum(mz) + sum(ep)
    end

    loss_function(ps2, r)

    ∂w, ∂b, ∂r = Zygote.jacobian(loss_function, ps.weight, ps.bias, r)

    ∂ps_ca, ∂r_ca = Zygote.jacobian(loss_function, ps2, r)

    @test ∂w[1] ≈ ∂ps_ca[1]
    @test ∂b[1] ≈ ∂ps_ca[2]
    @test ∂r ≈ ∂r_ca
end


# # This is commented out because the gradient operation itself is broken due to Zygote's inability
# # to support mutation and ComponentArray's use of mutation for construction from a NamedTuple.
# # It would be nice to support this eventually, so I'll just leave this commented (because @test_broken
# # wouldn't work here because the error happens before the test)
# @testset "Issues" begin
#     function mysum(x::AbstractVector)
#         y = ComponentVector(x=x)
#         return sum(y)
#     end

#     Δ = Zygote.gradient(mysum, rand(10))

#     @test Δ isa Vector{Float64}
# end
