## Similar
Base.similar(x::ComponentArray) = ComponentArray(similar(getdata(x)), getaxes(x)...)
Base.similar(x::ComponentArray, ::Type{T}) where T = ComponentArray(similar(getdata(x), T), getaxes(x)...)
function Base.similar(::Type{CA}) where CA<:ComponentArray{Axes,T,N,A} where {Axes,T,N,A}
    axs = getaxes(CA)
    return ComponentArray(similar(A, length.(axs)...), axs...)
end

Base.zeros(x::ComponentArray) = (similar(x) .= 0)
Base.ones(x::ComponentArray) = (similar(x) .= 1)


## Copy
Base.copy(x::ComponentArray) = ComponentArray(copy(getdata(x)), getaxes(x), )

Base.copyto!(dest::AbstractArray, src::ComponentArray) = copyto!(dest, getdata(src))
Base.copyto!(dest::ComponentArray, src::AbstractArray) = copyto!(getdata(dest), src)
Base.copyto!(dest::ComponentArray, src::ComponentArray) = copyto!(getdata(dest), getdata(src))

Base.deepcopy(x::ComponentArray) = ComponentArray(deepcopy(getdata(x)), getaxes(x))

Base.convert(::Type{CA}, A::AbstractArray) where CA<:ComponentArray = ComponentArray(A, getaxes(CA))
Base.convert(::Type{CA}, x::ComponentArray) where CA<:ComponentArray = ComponentArray(getdata(x), getaxes(CA))

## Conversion to NamedTuple (note, does not preserve numeric types of original NamedTuple)
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
