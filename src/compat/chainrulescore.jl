function ChainRulesCore.rrule(::typeof(getproperty), x::ComponentArray, s::Union{Symbol,Val})
    function getproperty_adjoint(Δ)
        zero_x = zero(similar(x, eltype(Δ)))
        setproperty!(zero_x, s, Δ)
        return (ChainRulesCore.NoTangent(), zero_x, ChainRulesCore.NoTangent())
    end

    return getproperty(x, s), getproperty_adjoint
end

ChainRulesCore.rrule(::typeof(getdata), x::ComponentArray) = getdata(x), Δ -> (ChainRulesCore.NoTangent(), ComponentArray(Δ, getaxes(x)))

ChainRulesCore.rrule(::Type{ComponentArray}, data, axes) = ComponentArray(data, axes), Δ -> (ChainRulesCore.NoTangent(), getdata(Δ), ChainRulesCore.NoTangent())

function ChainRulesCore.ProjectTo(ca::ComponentArray)
    return ChainRulesCore.ProjectTo{ComponentArray}(; project=ChainRulesCore.ProjectTo(getdata(ca)), axes=getaxes(ca))
end

(p::ChainRulesCore.ProjectTo{ComponentArray})(dx::AbstractArray) = ComponentArray(p.project(dx), p.axes)

function (p::ChainRulesCore.ProjectTo{ComponentArray})(t::ChainRulesCore.Tangent{A, <:NamedTuple}) where {A}
    nt = Functors.fmap(ChainRulesCore.backing, ChainRulesCore.backing(t))
    return ComponentArray(nt)
end
