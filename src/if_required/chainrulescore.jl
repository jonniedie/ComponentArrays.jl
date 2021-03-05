# ChainRulesCore.frule(Δ, ::typeof(getproperty), x::ComponentArray, s::Symbol) = frule((_, Δ), getproperty, x, Val(s))
# function ChainRulesCore.frule(Δ, ::typeof(getproperty), x::ComponentArray, ::Val{s}) where s
#     zero_x = zero(x)
#     setproperty!(zero_x, s, Δ)
#     return getproperty(x, s), zero_x
# end
ChainRulesCore.rrule(::typeof(getproperty), x::ComponentArray, s::Symbol) = ChainRulesCore.rrule(getproperty, x, Val(s))
function ChainRulesCore.rrule(::typeof(getproperty), x::ComponentArray, ::Val{s}) where s
    function getproperty_adjoint(Δ)
        zero_x = zero(x)
        setproperty!(zero_x, s, Δ)
        return (ChainRulesCore.NO_FIELDS, zero_x)
    end

    return getproperty(x, s), getproperty_adjoint
end

ChainRulesCore.rrule(::typeof(getdata), x::ComponentArray) = getdata(x), Δ->ComponentArray(Δ, getaxes(x))

ChainRulesCore.rrule(::typeof(getaxes), x::ComponentArray) = getaxes(x), Δ->ComponentArray(getdata(x), Δ)

# This won't work because typeof(ComponentArray) is a UnionAll. Do we even need it, though?
# ChainRulesCore.rrule(::typeof(ComponntArray), data, axes) = ComponentArray(data, axes), Δ->(getdata(Δ), getaxes(Δ))
