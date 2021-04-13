ChainRulesCore.rrule(::typeof(getproperty), x::ComponentArray, ::Val{s}) where s = ChainRulesCore.rrule(getproperty, x, s)
function ChainRulesCore.rrule(::typeof(getproperty), x::ComponentArray, s::Symbol)
    function getproperty_adjoint(Δ)
        zero_x = zero(x)
        setproperty!(zero_x, s, Δ)
        return (ChainRulesCore.NO_FIELDS, zero_x)
    end

    return getproperty(x, s), getproperty_adjoint
end

ChainRulesCore.rrule(::typeof(getdata), x::ComponentArray) = getdata(x), Δ->(ChainRulesCore.NO_FIELDS, ComponentArray(Δ, getaxes(x)))

ChainRulesCore.rrule(::Type{ComponentArray}, data, axes) = ComponentArray(data, axes), Δ->(ChainRulesCore.NO_FIELDS, getdata(Δ), getaxes(Δ))
