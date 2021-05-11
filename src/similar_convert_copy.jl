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


Base.convert(::Type{CA}, A::AbstractArray) where CA<:ComponentArray = ComponentArray(A, getaxes(CA))
Base.convert(::Type{CA}, x::ComponentArray) where CA<:ComponentArray = ComponentArray(getdata(x), getaxes(CA))
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
# Base.convert(TypeAx::Type{<:Ax1}, ::Ax2) where {Ax1<:AbstractAxis,Ax2<:AbstractAxis} = promote_type(TypeAx,Ax2)()
# Base.convert(::Type{Ax1}, ax::Ax2) where {Ax1<:AbstractAxis,Ax2<:AbstractAxis} = Ax1()

# Could not figure out promote_rule for these.
Base.promote(ax::AbstractAxis, ::NullAxis) = ax
Base.promote(ax::AbstractAxis, ::FlatAxis) = ax
Base.promote(::NullAxis, ax::AbstractAxis) = ax
Base.promote(::FlatAxis, ax::AbstractAxis) = ax
Base.promote(::FlatAxis, ::NullAxis) = FlatAxis()
Base.promote(::NullAxis, ::FlatAxis) = FlatAxis()
Base.promote(::FlatAxis, ::FlatAxis) = FlatAxis()
Base.promote(::NullAxis, ::NullAxis) = NullAxis()
Base.promote(ax::Ax, ::Ax) where {Ax<:AbstractAxis} = ax
function Base.promote(ax1::AbstractAxis, ax2::AbstractAxis)
    @warn "Tried to promote dissimilar axes of types $(typeof(ax1)) and $(typeof(ax2)). Falling back to FlatAxis."
    return FlatAxis()
end