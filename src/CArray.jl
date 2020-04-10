using LinearAlgebra: Adjoint

const FlatIdx = Union{UnitRange, Int, CartesianIndex}


# Axis
struct Axis{L,IdxMap} end
NullAxis = Axis{0, NamedTuple()}
FlatAxis{L} = Axis{L, NamedTuple()}

Axis{L,IdxMap}(x) where {L,IdxMap} = Axis{IdxMap}()
Axis(x::Type{Axis{L,IdxMap}}) where {L,IdxMap} = Axis{L,IdxMap}()
Axis(L, IdxMap) = Axis{length(L),IdxMap}()
Axis(::Number, IdxMap) = NullAxis()
Axis(::Colon, IdxMap) = Axis{lastof(IdxMap),IdxMap}()
Axis(tup) = Axis(tup...)

idxmap(::Axis{L,IdxMap}) where {L,IdxMap} = IdxMap
idxmap(::Type{Axis{L,IdxMap}}) where {L,IdxMap} = IdxMap

Base.getindex(::Axis{L,IdxMap}, x::FlatIdx) where {L,IdxMap} = totuple(x)
Base.getindex(::Axis{L,IdxMap}, x::Symbol) where {L,IdxMap} = totuple(getfield(IdxMap, x))
Base.getindex(::Axis{L,IdxMap}, x::Colon) where {L,IdxMap} = (:, IdxMap)
Base.getindex(::Type{Axis{L,IdxMap}}, x::FlatIdx) where {L,IdxMap} = totuple(x)
Base.getindex(::Type{Axis{L,IdxMap}}, x::Symbol) where {L,IdxMap} = totuple(getfield(IdxMap, x))
Base.getindex(::Type{Axis{L,IdxMap}}, x::Colon) where {L,IdxMap} = (:, IdxMap)

totuple(x) = (x, NamedTuple())
totuple(x::Tuple) = x

lastof(x) = x[end]
lastof(x::Union{Tuple, NamedTuple}) = lastof(x[end])

Base.length(::Axis{L,IdxMap}) where {L,IdxMap} = L
Base.length(::Type{Axis{L,IdxMap}}) where {L,IdxMap} = L

Base.IndexStyle(::Type{<:Axis}) = IndexLinear()

# Base.UnitRange(x::Axis) where T = 1:length(x)
# Base.UnitRange{T}(x::Axis) where T = 1:length(x)
# Base.UnitRange{T}(x::Axis) where T<:Real = 1:length(x)

# Base.checkindex(tb, x1::Axis, x2) = checkindex(tb, UnitRange(x1), x2)
# Base.checkindex(tb, x1, x2::Axis) = checkindex(tb, x1, UnitRange(x2))
# Base.checkindex(tb, x1::Axis, x2::Axis) = checkindex(tb, UnitRange(x1), UnitRange(x2))

Base.firstindex(x::Axis) = 1
Base.lastindex(x::Axis{L,IdxMap}) where {L,IdxMap} = lastof(IdxMap)

Base.first(x::Axis) = 1
Base.last(x::Axis{L,IdxMap}) where {L,IdxMap} = lastof(IdxMap)

remove_nulls() = ()
remove_nulls(x) = (x,)
remove_nulls(x::NullAxis) = ()
remove_nulls(x1, x2, args...) = (x1, remove_nulls(x2, args...)...)
remove_nulls(x1::NullAxis, x2, args...) = (remove_nulls(x2, args...)...,)



# CArray
struct CArray{Axes,T,N,A<:AbstractArray{T,N}} <: DenseArray{T,N}
    data::A
    axes::Axes
    CArray(data::A, ax::Axes) where {A<:AbstractArray{T,N},Axes<:Tuple{Vararg{Axis}}} where {T,N} = new{Axes,T,N,A}(data, ax)
end
CArray(data, ::Tuple{}) = data
CArray(data, ax...) = CArray(data, remove_nulls(ax...))
CArray(data, ax::FlatAxis...) = data
CArray{Axes}(data) where Axes = CArray(data, map(Axis, (Axes.types...,))...)
# CArray(data::Number, ax) = data
# CArray(data::AbstractArray, ax::Tuple{Vararg{Axis{L,NamedTuple()}}}) where L = data
# CArray(tup::Tuple) = CArray(tup...)
CArray{Axes,T,N,A}(::UndefInitializer) where {Axes,T,N,A} = similar(CArray{Axes,T,N,A})

const CVector{Axes,T,A} = CArray{Axes,T,1,A}
const CMatrix{Axes,T,A} = CArray{Axes,T,2,A}

_axes(x::CArray) = getfield(x, :axes)
_axes(::Type{CArray{Axes,T,N,A}}) where {Axes,T,N,A} = map(x->x(), (Axes.types...,))
_axes(::Type{Axes}) where {Axes<:Tuple{Vararg{Axis}}} = map(x->x(), (Axes.types...,))

_data(x::CArray) = getfield(x, :data)

getval(::Val{x}) where x = x
getval(::Type{Val{x}}) where x = x

Base.to_index(x::CArray, i) = i

Base.@inline Base.getindex(x::CArray, idx::FlatIdx...) = _data(x)[idx...]
Base.@inline Base.getindex(x::CVector, idx::Colon) = x
Base.@inline Base.getindex(x::CArray, idx::Colon) = view(_data(x), :)
Base.@inline Base.getindex(x::CArray, idx...) = getindex(x, Val.(idx)...)
Base.@inline Base.getindex(x::CArray, idx::Val...) = CArray(_getindex(x, idx...)...)
@generated function _getindex(x::CArray, args...)
    axs = _axes(x)
    ind_tups = @. getindex(axs, getval(args))
    inds = first.(ind_tups)
    new_axs = @. Axis(ind_tups)
    return :(Base.@_pure_meta; (Base.maybeview(_data(x), $inds...), $new_axs...))
end

Base.@inline Base.setindex!(x::CArray, v, idx::FlatIdx...) = setindex!(_data(x), v, idx...)
Base.@inline Base.setindex!(x::CArray, v, idx::Colon) = setindex!(_data(x), v, :)
Base.@inline Base.setindex!(x::CArray, v, idx...) = setindex!(x, v, Val.(idx)...)
Base.@inline Base.setindex!(x::CArray, v, idx::Val...) = _setindex!(x, v, idx...)
@generated function _setindex!(x::CArray, v, args...)
    axs = _axes(x)
    ind_tups = @. getindex(axs, getval(args))
    inds = first.(ind_tups)
    new_axs = @. Axis(ind_tups)
    return :(Base.@_pure_meta; setindex!(_data(x), v, $inds...))
end

Base.@inline Base.getproperty(x::CVector, s::Symbol) = CArray(_getindex(x, Val(s))...)
Base.@inline Base.setproperty!(x::CVector, s::Symbol, v) = _setindex!(x, v, Val(s))

Base.dotview(x::CArray, args...) = getindex(x, args...)

Base.size(x::CArray) = size(_data(x))

Base.similar(x::CArray) = CArray(similar(_data(x)), _axes(x)...)
Base.similar(x::CArray, ::Type{T}) where T = CArray(similar(_data(x), T), _axes(x)...)
function Base.similar(::Type{CA}) where CA<:CArray{Axes,T,N,A} where {Axes,T,N,A}
    axs = _axes(CA)
    return CArray(similar(A, length.(axs)...), axs...)
end


Base.copy(x::CArray) = CArray(copy(_data(x)), _axes(x), )

Base.copyto!(dest::AbstractArray, src::CArray) = copyto!(dest, _data(src))

Base.deepcopy(x::CArray) = CArray(deepcopy(_data(x)), _axes(x))

Base.pointer(x::CArray) = pointer(_data(x))

Base.unsafe_convert(::Type{Ptr{T}}, x::CArray) where T = Base.unsafe_convert(Ptr{T}, _data(x))

Base.adjoint(x::CVector) = CArray(adjoint(_data(x)), Axis{1,NamedTuple()}(), _axes(x)[1])
Base.transpose(x::CVector) = CArray(transpose(_data(x)), Axis{1,NamedTuple()}(), _axes(x)[1])
Base.adjoint(x::CMatrix) = CArray(adjoint(_data(x)), reverse(_axes(x))...)
Base.transpose(x::CMatrix) = CArray(transpose(_data(x)), reverse(_axes(x))...)



# Broadcasting
struct CAStyle{Axes,T,N,A} <: Broadcast.AbstractArrayStyle{N} end
const BroadCAStyle{Axes,T,N,A} = Broadcast.Broadcasted{CAStyle{Axes,T,N,A}}
const DefArrStyle{N} = Base.Broadcast.DefaultArrayStyle{N}

Base.BroadcastStyle(::Type{<:CArray{Axes,T,N,A}}) where {Axes,T,N,A} = CAStyle{Axes,T,N,A}()
CAStyle{Axes,T,N,A}(x::Val{i}) where {Axes,T,N,A,i} = CAStyle{Axes,T,N,A}()
Base.BroadcastStyle(::CAStyle{Axes,T,N,A}, ::CAStyle{Axes,TT,N,A}) where {Axes,T,N,A,TT} =
    CAStyle{Axes,promote_type(T,TT),N,A}()
Base.BroadcastStyle(::CAStyle{Axes,T,N,A}, ::TT) where {Axes,T,N,A,TT<:DefArrStyle} = TT()
# Base.BroadcastStyle(::CAStyle{Axes,T,N,A}, ::TT) where {Axes,T,N,A,TT<:DefArrStyle{0}} =
#     CAStyle{Axes,T,N,A}()
# Base.BroadcastStyle(::TT, ::CAStyle{Axes,T,N,A}) where {Axes,T,N,A,TT<:DefArrStyle{0}} =
#     CAStyle{Axes,T,N,A}()

function Base.similar(bc::BroadCAStyle{Axes,T,N,A}, ::Type{TT}) where {Axes,T,N,A,TT}
    # return :(Base.@_pure_meta; CArray{Axes}(similar(Array{TT,N}, axes(bc))))
    # x = bc.args[1]
    # return similar(x, TT)
    ax = _axes(Axes)
    # try
    #     return CArray(similar(A(), TT, length.(ax)...), ax...)
    # catch
        return CArray(Array{TT,N}(undef, length.(ax)...), ax...)
    # end
end

# function Base.Broadcast.combine_axes(x1::Axis, x2::Axis, args...)
#
# end
# function Base.Broadcast.combine_axes(x::Axis...)
#
# end
