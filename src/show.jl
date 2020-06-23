# Show AbstractAxis types
Base.show(io::IO, ::MIME"text/plain", ::Axis{IdxMap}) where IdxMap = print(io, "Axis$IdxMap")
Base.show(io::IO, ::Axis{IdxMap}) where IdxMap = print(io, "$IdxMap")

Base.show(io::IO, ::FlatAxis) = print(io, "FlatAxis()")

Base.show(io::IO, ::NullAxis) = print(io, "NullAxis()")

Base.show(io::IO, ::MIME"text/plain", ::PartitionedAxis{PartSz, IdxMap, Ax}) where {PartSz, IdxMap, Ax} =
    print(io, "PartitionedAxis($PartSz, $(Ax()))")
Base.show(io::IO, ::PartitionedAxis{PartSz, IdxMap, Ax}) where {PartSz, IdxMap, Ax} =
    print(io, "Partition($PartSz, $(Ax()))")

Base.show(io::IO, ::ShapedAxis{Shape, IdxMap}) where {Shape, IdxMap} =
    print(io, "ShapedAxis($Shape, $IdxMap)")

Base.show(io::IO, ::MIME"text/plain", ::ViewAxis{Inds, IdxMap, Ax}) where {Inds, IdxMap, Ax} = 
    print(io, "ViewAxis($Inds, $(Ax()))")
Base.show(io::IO, ::ViewAxis{Inds, IdxMap, <:Ax}) where {Inds, IdxMap, Ax} = 
    print(io, "View($Inds, $(Ax()))")
Base.show(io::IO, ::ViewAxis{Inds, IdxMap, <:NullorFlatAxis}) where {Inds, IdxMap} = 
    print(io, Inds)

Base.show(io::IO, ci::ComponentIndex) = print(io, "ComponentIndex($(ci.idx), $(ci.ax))")


# Show ComponentArrays
function Base.show(io::IO, x::ComponentVector)
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
function Base.show(io::IO, ::MIME"text/plain", x::ComponentVector{T,A,Axes}) where {A<:Vector{T},Axes} where T
    print(io, "ComponentVector{" , T, "}")
    show(io, x)
    return nothing
end
function Base.show(io::IO, ::MIME"text/plain", x::ComponentVector{T,A,Axes}) where {T,A,Axes}
    print(io, "ComponentVector{" , A, "}")
    show(io, x)
    return nothing
end
function Base.show(io::IO, a::AbstractVector{<:T}) where T<:ComponentVector
    elem = a[1]
    print(io, "[$elem")
    for idx in 2:length(a)
        print(io, ", $(a[idx])")
    end
    print(io, "]")
    return nothing
end