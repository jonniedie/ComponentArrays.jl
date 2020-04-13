## CArray type
struct CArray{Axes,T,N,A<:AbstractArray{T,N}} <: AbstractArray{T,N}
    data::A
    axes::Axes
    CArray(data::A, ax::Axes) where {A<:AbstractArray{T,N},Axes<:Tuple} where {T,N} = new{Axes,T,N,A}(data, ax)
end
CArray(data, ::Tuple{}) = data
CArray(data, ax::Axis...) = CArray(data, remove_nulls(ax...))
CArray(data, ax::FlatAxis...) = data
CArray{Axes}(data) where Axes = CArray(data, map(Axis, (Axes.types...,))...)
# CArray(data::Number, ax) = data
# CArray(data::AbstractArray, ax::Tuple{Vararg{Axis{L,NamedTuple()}}}) where L = data
# CArray(tup::Tuple) = CArray(tup...)
CArray{Axes,T,N,A}(::UndefInitializer) where {Axes,T,N,A} = similar(CArray{Axes,T,N,A})

const CVector{Axes,T,A} = CArray{Axes,T,1,A}
const CMatrix{Axes,T,A} = CArray{Axes,T,2,A}


## Field access through these functions to reserve dot-getting for keys
_axes(x::CArray) = getfield(x, :axes)
_axes(::Type{CArray{Axes,T,N,A}}) where {Axes,T,N,A} = map(x->x(), (Axes.types...,))

_data(x::CArray) = getfield(x, :data)
_data(x) = x


## Copying and such
Base.size(x::CArray) = size(_data(x))

Base.similar(x::CArray) = CArray(similar(_data(x)), _axes(x)...)
Base.similar(x::CArray, ::Type{T}) where T = CArray(similar(_data(x), T), _axes(x)...)
function Base.similar(::Type{CA}) where CA<:CArray{Axes,T,N,A} where {Axes,T,N,A}
    axs = _axes(CA)
    return CArray(similar(A, length.(axs)...), axs...)
end

Base.copy(x::CArray) = CArray(copy(_data(x)), _axes(x), )

Base.copyto!(dest::AbstractArray, src::CArray) = copyto!(dest, _data(src))
Base.copyto!(dest::CArray, src::AbstractArray) = copyto!(_data(dest), src)
Base.copyto!(dest::CArray, src::CArray) = copyto!(_data(dest), _data(src))

Base.deepcopy(x::CArray) = CArray(deepcopy(_data(x)), _axes(x))

Base.pointer(x::CArray) = pointer(_data(x))

Base.unsafe_convert(::Type{Ptr{T}}, x::CArray) where T = Base.unsafe_convert(Ptr{T}, _data(x))
