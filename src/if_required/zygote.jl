# Should I be using ZygoteRules instead?

Zygote.@adjoint function Zygote.literal_getproperty(x::ComponentArray, ::Val{s}) where s
    function getproperty_adjoint(Δ)
        zero_x = zero(x)
        setproperty!(zero_x, s, Δ)
        return (zero_x, nothing)
    end

    return getproperty(x, s), getproperty_adjoint
end

Zygote.@adjoint getdata(x::ComponentArray) = getdata(x), Δ->ComponentArray(Δ, getaxes(x))

Zygote.@adjoint getaxes(x::ComponentArray) = getaxes(x), Δ->ComponentArray(getdata(x), Δ)

Zygote.@adjoint ComponentArray(data, axes) = ComponentArray(data, axes), Δ->(getdata(Δ), getaxes(Δ))

Zygote.@adjoint function Base.convert(::Type{CA}, x::ComponentArray) where CA<:ComponentArray
    return ComponentArray(getdata(x), getaxes(CA)), Δ->(CA, ComponentArray(getdata(Δ), getaxes(x)))
end

Zygote.refresh()