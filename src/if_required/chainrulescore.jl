function ChainRulesCore.rrule(::typeof(getproperty), x::ComponentArray, ::Val{s}) where {s}
    function getproperty_adjoint(Δ)
        zero_x = zero(x)
        setproperty!(zero_x, s, Δ)
        return (ChainRulesCore.NoTangent(), zero_x, ChainRulesCore.NoTangent())
    end

    return getproperty(x, s), getproperty_adjoint
end

function ChainRulesCore.rrule(::typeof(getproperty), x::ComponentArray, s::Symbol)
    function getproperty_adjoint(Δ)
        zero_x = zero(x)
        setproperty!(zero_x, s, Δ)
        return (ChainRulesCore.NoTangent(), zero_x, ChainRulesCore.NoTangent())
    end

    return getproperty(x, s), getproperty_adjoint
end

ChainRulesCore.rrule(::typeof(getdata), x::ComponentArray) = getdata(x), Δ->(ChainRulesCore.NoTangent(), ComponentArray(Δ, getaxes(x)))

ChainRulesCore.rrule(::Type{ComponentArray}, data, axes) = ComponentArray(data, axes), Δ->(ChainRulesCore.NoTangent(), getdata(Δ), getaxes(Δ))
