## Similar
Base.similar(x::CArray) = CArray(similar(getdata(x)), getaxes(x)...)
Base.similar(x::CArray, ::Type{T}) where T = CArray(similar(getdata(x), T), getaxes(x)...)
function Base.similar(::Type{CA}) where CA<:CArray{Axes,T,N,A} where {Axes,T,N,A}
    axs = getaxes(CA)
    return CArray(similar(A, length.(axs)...), axs...)
end

Base.zeros(x::CArray) = (similar(x) .= 0)
Base.ones(x::CArray) = (similar(x) .= 1)


## Copy
Base.copy(x::CArray) = CArray(copy(getdata(x)), getaxes(x), )

Base.copyto!(dest::AbstractArray, src::CArray) = copyto!(dest, getdata(src))
Base.copyto!(dest::CArray, src::AbstractArray) = copyto!(getdata(dest), src)
Base.copyto!(dest::CArray, src::CArray) = copyto!(getdata(dest), getdata(src))

Base.deepcopy(x::CArray) = CArray(deepcopy(getdata(x)), getaxes(x))


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
