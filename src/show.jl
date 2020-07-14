# Show AbstractAxis types
Base.show(io::IO, ::MIME"text/plain", ::Axis{IdxMap}) where IdxMap = print(io, "Axis$IdxMap")
Base.show(io::IO, ::Axis{IdxMap}) where IdxMap = print(io, "Axis($IdxMap)")

Base.show(io::IO, ::FlatAxis) = print(io, "FlatAxis()")

Base.show(io::IO, ::NullAxis) = print(io, "NullAxis()")

Base.show(io::IO, ::MIME"text/plain", ::PartitionedAxis{PartSz, IdxMap, Ax}) where {PartSz, IdxMap, Ax} =
    print(io, "PartitionedAxis($PartSz, $(Ax()))")
Base.show(io::IO, ::PartitionedAxis{PartSz, IdxMap, Ax}) where {PartSz, IdxMap, Ax} =
    print(io, "PartitionedAxis($PartSz, $(Ax()))")

Base.show(io::IO, ::ShapedAxis{Shape, IdxMap}) where {Shape, IdxMap} =
    print(io, "ShapedAxis($Shape, $IdxMap)")

Base.show(io::IO, ::MIME"text/plain", ::ViewAxis{Inds, IdxMap, Ax}) where {Inds, IdxMap, Ax} = 
    print(io, "ViewAxis($Inds, $(Ax()))")
Base.show(io::IO, ::ViewAxis{Inds, IdxMap, <:Ax}) where {Inds, IdxMap, Ax} = 
    print(io, "ViewAxis($Inds, $(Ax()))")
Base.show(io::IO, ::ViewAxis{Inds, IdxMap, <:NullorFlatAxis}) where {Inds, IdxMap} = 
    print(io, Inds)

Base.show(io::IO, ci::ComponentIndex) = print(io, "ComponentIndex($(ci.idx), $(ci.ax))")


# Show ComponentArrays
function Base.show(io::IO, x::ComponentVector)
    print(io, "(")
    for (i,key) in enumerate(keys(x))
        if i==1
            print(io, "$key = ")
        else
            print(io, ", $key = ")
        end
        show(io, x[key])
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


function Base.show(io::IO, ::MIME"text/plain", x::ComponentMatrix{T,A,Axes}) where {A<:Matrix{T},Axes} where T
    if !haskey(io, :compact) && length(axes(x, 2)) > 1
        io = IOContext(io, :compact => true)
    end
    axs = indexmap.(getaxes(x))
    println(io, "ComponentMatrix{" , T, "} with axes $(axs[1]) × $(axs[2])")
    Base.print_matrix(io, getdata(x))
    return nothing
end
function Base.show(io::IO, ::MIME"text/plain", x::ComponentMatrix{T,A,Axes}) where {T,A,Axes}
    if !haskey(io, :compact) && length(axes(x, 2)) > 1
        io = IOContext(io, :compact => true)
    end
    axs = indexmap.(getaxes(x))
    println(io, "ComponentMatrix{" , A, "} with axes $(axs[1]) × $(axs[2])")
    Base.print_matrix(io, getdata(x))
    return nothing
end