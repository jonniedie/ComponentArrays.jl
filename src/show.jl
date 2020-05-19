# function Base.show(io::IO, ::MIME"text/plain", x::CVector)
#     print(io, "ComponentArray{$(eltype(x))}$(NamedTuple(x))")
#     return nothing
# end
# function Base.show(io::IO, x::CVector)
#     print(io, NamedTuple(x))
#     return nothing
# end

function Base.show(io::IO, x::CVector)
    K = keys(x)
    key = K[1]
    print(io, "($key = $(x[key])")
    for idx in 2:length(K)
        key = K[idx]
        print(io, ", $key = $(x[key])")
    end
    print(io, ")")
    return nothing
end
function Base.show(io::IO, ::MIME"text/plain", x::CVector{Axes,T,A}) where {Axes,T,A}
    print(io, "ComponentArray{" , T, "}")
    show(io, x)
    return nothing
end
function Base.show(io::IO, a::AbstractVector{<:T}) where T<:CVector
    elem = a[1]
    print(io, "[$elem")
    for idx in 2:length(a)
        print(io, ", $(a[idx])")
    end
    print(io, "]")
    return nothing
end