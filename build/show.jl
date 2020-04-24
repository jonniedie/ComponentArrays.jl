function Base.show(io::IO, ::MIME"text/plain", x::CVector)
    print(io, "CArray{$(eltype(x))}$(NamedTuple(x))")
    return nothing
end
function Base.show(io::IO, x::CVector)
    print(io, NamedTuple(x))
    return nothing
end