using ChainRulesCore: NO_FIELDS

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

# ChainRulesCore.frule(::typeof(getdata), x::ComponentArray) = getdata(x), Δ->ComponentArray(Δ, getaxes(x))
ChainRulesCore.rrule(::typeof(getdata), x::ComponentArray) = getdata(x), Δ->(NO_FIELDS, ComponentArray(Δ, getaxes(x)))

ChainRulesCore.rrule(::typeof(getaxes), x::ComponentArray) = getaxes(x), Δ->(NO_FIELDS, ComponentArray(getdata(x), Δ))

ChainRulesCore.rrule(::Type{ComponentArray}, data, axes) = ComponentArray(data, axes), Δ->(NO_FIELDS, getdata(Δ), getaxes(Δ))

ChainRulesCore.rrule(::Type{Axis}, nt) = Axis(nt), Δ->(NO_FIELDS, ComponentArrays.indexmap(Δ))
ChainRulesCore.rrule(::Type{Axis}; kwargs...) = Axis(; kwargs...), Δ->(NO_FIELDS, (; ComponentArrays.indexmap(Δ)...))
