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
# function Base.similar(x::ComponentArray{T1,N,A,Ax}, ::Type{T}, dims::Union{Integer, AbstractUnitRange}...) where {T,T1,N,A,Ax}
#     arr = similar(getdata(x), T, dims)
#     return ComponentArray(arr, getaxes(x))
# end
# function Base.similar(x::ComponentArray{T1,N,A,Ax}, ::Type{T}, dims::Union{Integer, AbstractUnitRange}...) where {T,T1,N,A,Ax}
#     return similar(getdata(x), T, dims)
# end
function Base.similar(x::AbstractArray, dims::Tuple{<:CombinedAxis, Vararg{<:CombinedOrRegularAxis}})
    arr = similar(getdata(x), length.(_array_axis.(dims)))
    return ComponentArray(arr, _component_axis.(dims)...)
end
function Base.similar(x::AbstractArray, dims::Tuple{<:Union{Integer,AbstractUnitRange}, <:CombinedAxis, Vararg{<:CombinedOrRegularAxis}})
    arr = similar(getdata(x), length.(_array_axis.(dims)))
    return ComponentArray(arr, _component_axis.(dims)...)
end
function Base.similar(x::AbstractArray, dims::Tuple{<:CombinedAxis, <:CombinedAxis, Vararg{<:CombinedOrRegularAxis}})
    arr = similar(getdata(x), length.(_array_axis.(dims)))
    return ComponentArray(arr, _component_axis.(dims)...)
end
function Base.similar(x::AbstractArray, ::Type{T}, dims::Tuple{<:CombinedAxis, Vararg{<:CombinedOrRegularAxis}}) where {T}
    arr = similar(getdata(x), T, length.(_array_axis.(dims)))
    return ComponentArray(arr, _component_axis.(dims)...)
end
function Base.similar(x::AbstractArray, ::Type{T}, dims::Tuple{<:Union{Integer,AbstractUnitRange}, <:CombinedAxis, Vararg{<:CombinedOrRegularAxis}}) where {T}
    arr = similar(getdata(x), T, length.(_array_axis.(dims)))
    return ComponentArray(arr, _component_axis.(dims)...)
end
function Base.similar(x::Type{<:AbstractArray}, dims::Tuple{<:CombinedAxis, Vararg{<:CombinedOrRegularAxis}})
    arr = similar(x, length.(_array_axis.(dims)))
    return ComponentArray(arr, _component_axis.(dims)...)
end
function Base.similar(x::Type{<:AbstractArray}, dims::Tuple{<:CombinedOrRegularAxis, <:CombinedAxis, Vararg{<:CombinedOrRegularAxis}})
    arr = similar(x, length.(_array_axis.(dims)))
    return ComponentArray(arr, _component_axis.(dims)...)
end
function Base.similar(x::Type{<:AbstractArray}, dims::Tuple{<:CombinedAxis, <:CombinedAxis, Vararg{<:CombinedOrRegularAxis}})
    arr = similar(x, length.(_array_axis.(dims)))
    return ComponentArray(arr, _component_axis.(dims)...)
end

# function Base.similar(A::Type{<:AbstractArray}, dims::Tuple{<:AbstractAxis,Vararg{<:AbstractAxis}})
#     arr = similar(A, length.(dims))
#     return ComponentArray(arr, Axis.(dims))
# end
# function Base.similar(A::Type{<:AbstractArray}, ::Type{T}, dims::Tuple{<:AbstractAxis,Vararg{<:AbstractAxis}}) where {T}
#     arr = similar(A, T, length.(dims))
#     return ComponentArray(arr, Axis.(dims))
# end
# function Base.similar(A::Type{<:AbstractArray}, dims::Tuple{<:UnitRange,Vararg{<:AbstractAxis}})
#     arr = similar(A, length.(dims))
#     return ComponentArray(arr, Axis.(dims))
# end
# function Base.similar(A::Type{<:AbstractArray}, ::Type{T}, dims::Tuple{<:UnitRange,Vararg{<:AbstractAxis}}) where {T}
#     arr = similar(A, T, length.(dims))
#     return ComponentArray(arr, Axis.(dims))
# end

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
Base.convert(::Type{Ax}, ax::AbstractAxis) where {Ax<:AbstractAxis} = ax #Ax()
# Base.convert(::Type{Axis}, ax::AbstractAxis) = ax #Ax()
Base.convert(::Type{Ax}, ax::AbstractAxis) where {Ax<:VarAxes} = convert.(typeof.(getaxes(Ax)), (ax,))

Base.promote_rule(AA::Type{<:Axis}, ::Type{NullAxis}) = AA
Base.promote_rule(AA::Type{<:Axis}, ::Type{FlatAxis}) = AA
Base.promote_rule(FA::Type{FlatAxis}, ::Type{NullAxis}) = FA
Base.promote_rule(FA::Type{FlatAxis}, ::Type{FlatAxis}) = FA
Base.promote_rule(NA::Type{NullAxis}, ::Type{NullAxis}) = NA
function Base.promote_rule(A1::Type{<:VarAxes}, A2::Type{<:VarAxes})
    # promote_type.(typeof.(getaxes(A1)), typeof.(getaxes(A2)))
    ax = typeof(first.(promote.(getaxes(A1), getaxes(A2))))
end

broadcast_promote_type(::Type{FlatAxis}, ax2::Type{<:Axis}) = ax2
broadcast_promote_type(ax1::Type{<:Axis}, ::Type{FlatAxis}) = ax1
broadcast_promote_type(ax1::Type{FlatAxis}, ::Type{NullAxis}) = ax1
broadcast_promote_type(::Type{NullAxis}, ax2::Type{FlatAxis}) = ax2
broadcast_promote_type(::Type{<:Axis}, ::Type{<:Axis}) = FlatAxis
broadcast_promote_type(ax1::Type{Ax}, ::Type{Ax}) where {Ax<:Axis} = ax1
function broadcast_promote_type(A1::Type{<:VarAxes}, A2::Type{<:VarAxes})
    ax = Tuple{broadcast_promote_typeof.(getaxes(A1), getaxes(A2))...}
end

broadcast_promote_typeof(ax1, ax2) = broadcast_promote_type(typeof(ax1), typeof(ax2))

broadcast_promote(ax1, ax2) = broadcast_promote_typeof(ax1, ax2)()