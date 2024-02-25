function Functors.functor(::Type{<:ComponentArray}, c)
    return (
        NamedTuple{propertynames(c)}(getproperty.((c,), propertynames(c))), ComponentArray)
end
