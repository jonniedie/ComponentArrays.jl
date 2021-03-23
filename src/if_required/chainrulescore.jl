using ChainRulesCore: NO_FIELDS

# ChainRulesCore.frule(Δ, ::typeof(getproperty), x::ComponentArray, s::Symbol) = frule((_, Δ), getproperty, x, Val(s))
# function ChainRulesCore.frule(Δ, ::typeof(getproperty), x::ComponentArray, ::Val{s}) where s
#     zero_x = zero(x)
#     setproperty!(zero_x, s, Δ)
#     return getproperty(x, s), zero_x
# end
ChainRulesCore.rrule(::typeof(getproperty), x::ComponentArray, ::Val{s}) where s = ChainRulesCore.rrule(getproperty, x, s)
function ChainRulesCore.rrule(::typeof(getproperty), x::ComponentArray, s::Symbol)
    function getproperty_adjoint(Δ)
        zero_x = zero(x)
        setproperty!(zero_x, s, Δ)
        return (ChainRulesCore.NO_FIELDS, zero_x)
    end

    return getproperty(x, s), getproperty_adjoint
end

ChainRulesCore.rrule(::typeof(getdata), x::ComponentArray) = getdata(x), Δ->ComponentArray(Δ, getaxes(x))

ChainRulesCore.rrule(::Type{ComponentArray}, data, axes) = ComponentArray(data, axes), Δ->(NO_FIELDS, getdata(Δ), getaxes(Δ))

ChainRulesCore.rrule(::Type{ComponentArray}, data, axes) = ComponentArray(data, axes), Δ->(getdata(Δ), getaxes(Δ))
