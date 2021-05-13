## ComponentArrays
# Similar
Base.similar(x::ComponentArray) = ComponentArray(similar(getdata(x)), getaxes(x)...)
Base.similar(x::ComponentArray, ::Type{T}) where T = ComponentArray(similar(getdata(x), T), getaxes(x)...)
# Base.similar(x::ComponentArray, ::Type{T}, ax::Tuple{Vararg{Int64,N}}) where {T,N} = similar(x, T, ax...)
# function Base.similar(x::ComponentArray, ::Type{T}, ax::Union{Integer, Base.OneTo}...) where T
#     A = similar(getdata(x), T, ax...)
#     if size(getdata(x)) == size(A)
#         return ComponentArray(A, getaxes(x))
#     else
#         return A
#     end
# end
function Base.similar(x::ComponentArray{T1,N,A,Ax}, ::Type{T}, dims::NTuple{N,Int}) where {T,T1,N,A,Ax}
    arr = similar(getdata(x), T, dims)
    return ComponentArray(arr, getaxes(x))
end
function Base.similar(x::ComponentArray{T1,N1,A,Ax}, ::Type{T}, dims::NTuple{N2,Int}) where {T,T1,N1,N2,A,Ax}
    return similar(getdata(x), T, dims)
end

## TODO: write length method for AbstractAxis so we can do this?
    # function Base.similar(::Type{CA}) where CA<:ComponentArray{T,N,A,Axes} where {T,N,A,Axes}
#     axs = getaxes(CA)
#     return ComponentArray(similar(A, length.(axs)...), axs...)
# end

Base.zero(x::ComponentArray) = zero.(x)

## FIXME: waiting on similar(::Type{<:ComponentArray})
# Base.zeros(CA::Type{<:ComponentArray}) = (similar(CA) .= 0)

# Base.ones(CA::Type{<:ComponentArray}) = (similar(CA) .= 1)


# Copy
Base.copy(x::ComponentArray) = ComponentArray(copy(getdata(x)), getaxes(x))

Base.copyto!(dest::AbstractArray, src::ComponentArray) = copyto!(dest, getdata(src))
function Base.copyto!(dest::ComponentArray, src::AbstractArray)
    copyto!(getdata(dest), src)
    return dest
end
function Base.copyto!(dest::ComponentArray, src::ComponentArray)
    copyto!(getdata(dest), getdata(src))
    return dest
end

Base.deepcopy(x::ComponentArray) = ComponentArray(deepcopy(getdata(x)), getaxes(x))


function Base.convert(::Type{ComponentArray{T,N,AA,Ax}}, A::AbstractArray) where {T,N,AA,Ax}
    return ComponentArray{Ax}(A)
end
function Base.convert(::Type{ComponentArray{T,N,A,Ax1}}, x::ComponentArray{T,N,A,Ax2}) where {T,N,A,Ax1,Ax2}
    return x
end
function Base.convert(::Type{ComponentArray{T1,N,A1,Ax1}}, x::ComponentArray{T2,N,A2,Ax2}) where {T1,T2,N,A1,A2,Ax1,Ax2}
    return T1.(x)
end
Base.convert(::Type{<:Array}, x::ComponentArray) = convert(Array, getdata(x))


# Conversion to from ComponentArray to NamedTuple (note, does not preserve numeric types of
# original NamedTuple)
function _namedtuple(x::ComponentVector)
    data = []
    idxmap = indexmap(getaxes(x)[1])
    for key in valkeys(x)
        idx = idxmap[getval(key)]
        # if idx isa AliasAxis
        #     val = idx.f
        # else
            val = getproperty(x, key) |> _namedtuple
        # end
        push!(data, getval(key) => val)
    end
    return (; data...)
end
_namedtuple(v::AbstractVector) = _namedtuple.(v)
_namedtuple(x) = x

Base.convert(::Type{NamedTuple}, x::ComponentVector) = _namedtuple(x)
Base.NamedTuple(x::ComponentVector) = _namedtuple(x)


## AbstractAxis conversion and promotion
Base.convert(::Type{AbstractAxis}, ax::AbstractAxis) = ax
Base.convert(::Type{Ax}, ::AbstractAxis) where {Ax<:AbstractAxis} = Ax()
Base.convert(::Type{Ax}, ax::AbstractAxis) where {Ax<:VarAxes} = convert.(typeof.(getaxes(Ax)), (ax,))

Base.promote_rule(AA::Type{<:Axis}, ::Type{<:NullAxis}) = AA
Base.promote_rule(AA::Type{<:Axis}, ::Type{<:FlatAxis}) = AA
Base.promote_rule(FA::Type{FlatAxis}, ::Type{NullAxis}) = FA
Base.promote_rule(FA::Type{FlatAxis}, ::Type{FlatAxis}) = FA
Base.promote_rule(NA::Type{NullAxis}, ::Type{NullAxis}) = NA
function Base.promote_rule(A1::Type{<:VarAxes}, A2::Type{<:VarAxes})
    ax = first.(promote.(getaxes(A1), getaxes(A2))) |> typeof
end
