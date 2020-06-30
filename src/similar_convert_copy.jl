## ComponentArrays
# Similar
Base.similar(x::ComponentArray) = ComponentArray(similar(getdata(x)), getaxes(x)...)
Base.similar(x::ComponentArray, ::Type{T}) where T = ComponentArray(similar(getdata(x), T), getaxes(x)...)
Base.similar(x::ComponentArray, ::Type{T}, ax::Union{Integer, Base.OneTo}...) where T =
    ComponentArray(similar(getdata(x), T, ax...), getaxes(x)...)
Base.similar(x::ComponentVector, ::Type{T}, ax::Union{Integer, Base.OneTo}...) where T =
    ComponentArray(similar(getdata(x), T, ax...), fill_flat(getaxes(x), length(ax)))
function Base.similar(::Type{CA}) where CA<:ComponentArray{T,N,A,Axes} where {T,N,A,Axes}
    axs = getaxes(CA)
    return ComponentArray(similar(A, length.(axs)...), axs...)
end

Base.zeros(x::ComponentArray) = (similar(x) .= 0)
Base.ones(x::ComponentArray) = (similar(x) .= 1)


# Copy
Base.copy(x::ComponentArray) = ComponentArray(copy(getdata(x)), getaxes(x), )

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


# Base.promote_rule(A::Type{<:AbstractArray}, ::Type{<:ComponentArray}) = A
# Base.convert(::Type{<:AbstractArray}, x::ComponentArray) = getdata(x)


# Conversion to from ComponentArray to NamedTuple (note, does not preserve numeric types of
# original NamedTuple)
function _namedtuple(x::CVector)
    data = []
    for key in propertynames(x)
        val = getproperty(x, key) |> _namedtuple
        push!(data, key => val)
    end
    return (; data...)
end
_namedtuple(v::AbstractVector) = _namedtuple.(v)
_namedtuple(x) = x

Base.convert(::Type{NamedTuple}, x::CVector) = _namedtuple(x)
Base.NamedTuple(x::CVector) = _namedtuple(x)

## AbstractAxis conversion and promotion
Base.convert(::Type{<:Ax1}, ax::Ax2) where {Ax1<:AbstractAxis,Ax2<:AbstractAxis} = promote_type(Ax1,Ax2)()

Base.promote_rule(Ax1::Type{<:AbstractAxis}, Ax2::Type{<:AbstractAxis}) = promote_type(Ax1, Ax2)

# We may not need this anymore
Base.promote_type(Ax1::VarAxes, Ax2::VarAxes) = promote_type.(typeof.(getaxes(Ax1)), typeof.(getaxes(Ax2)))
Base.promote_type(Ax1::Type{VarAxes}, Ax2::Type{VarAxes}) = promote_type(getaxes(Ax1), getaxes(Ax2))
Base.promote_type(::Type{<:NullorFlatAxis}, Ax::Type{<:AbstractAxis{I1}}) where {I1} = Ax
Base.promote_type(Ax::Type{<:AbstractAxis{I1}}, ::Type{<:NullorFlatAxis}) where {I1} = Ax
Base.promote_type(::Type{<:NullorFlatAxis}, ::Type{<:NullorFlatAxis}) = FlatAxis
Base.promote_type(::Type{NullAxis}, ::Type{NullAxis}) = NullAxis