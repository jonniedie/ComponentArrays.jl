Base.to_index(x::CArray, i) = i

totuple(x) = (x, NamedTuple())
totuple(x::Tuple) = x


## Field access through these functions to reserve dot-getting for keys
"""
    getaxes(x::CArray)

Access ```.axes``` field of a ```CArray```. This is different than ```axes(x::CArray)```, which
    returns the axes of the contained array.
"""
getaxes(x::CArray) = getfield(x, :axes)
getaxes(::Type{CArray{Axes,T,N,A}}) where {Axes,T,N,A} = map(x->x(), (Axes.types...,))
getaxes(x::VarAxes) = getaxes(typeof(x))
getaxes(::Type{<:Axes}) where {Axes<:VarAxes} = map(x->x(), (Axes.types...,))

"""
    getdata(x::CArray)

Access ```.data``` field of a ```CArray```, which contains the array that ```CArray``` wraps.

# Examples

```jldoctest
julia> using ComponentArrays

julia> ax = Axis(a=1:3, b=(4:6, (a=1, b=2:3)))
Axis{(a = 1:3, b = (4:6, (a = 1, b = 2:3)))}()

julia> A = zeros(6,6);

julia> ca = CArray(A, (ax, ax))
6×6 CArray{Tuple{Axis{(a = 1:3, b = (4:6, (a = 1, b = 2:3)))},Axis{(a = 1:3, b = (4:6, (a = 1, b = 2:3)))}},Float64,2,Array{Float64,2}}:
 0.0  0.0  0.0  0.0  0.0  0.0
 0.0  0.0  0.0  0.0  0.0  0.0
 0.0  0.0  0.0  0.0  0.0  0.0
 0.0  0.0  0.0  0.0  0.0  0.0
 0.0  0.0  0.0  0.0  0.0  0.0
 0.0  0.0  0.0  0.0  0.0  0.0

julia> getaxes(ca)
(Axis{(a = 1:3, b = (4:6, (a = 1, b = 2:3)))}(), Axis{(a = 1:3, b = (4:6, (a = 1, b = 2:3)))}())
```
"""
getdata(x::CArray) = getfield(x, :data)
getdata(x) = x


## Axis indexing
Base.@inline Base.getindex(::Ax, x::Union{FlatIdx, Symbol, Colon}) where Ax<:Axis = getindex(Ax, x)
Base.@inline Base.getindex(::Type{Axis{IdxMap}}, x::FlatIdx) where IdxMap = totuple(x)
Base.@inline Base.getindex(::Type{Axis{IdxMap}}, x::Symbol) where IdxMap = totuple(getfield(IdxMap, x))
Base.@inline Base.getindex(::Type{Axis{IdxMap}}, x::Colon) where IdxMap = (:, IdxMap)


## CArray indexing
# Get index
Base.@inline Base.getindex(x::CArray, idx::FlatIdx...) = getdata(x)[idx...]
Base.@inline Base.getindex(x::CVector, idx::Colon) = x
Base.@inline Base.getindex(x::CArray, idx::Colon) = view(getdata(x), :)
@noinline Base.getindex(x::CArray, idx) = getindex(x, Val(idx))
@noinline Base.getindex(x::CArray, idx...) = getindex(x, fastindices(idx)...) #Val.(idx)...)
Base.@inline Base.getindex(x::CArray, idx::Val...) = _getindex(x, idx...) #CArray(_getindex(x, idx...)...)
@generated function _getindex(x::CArray, args...)
    axs = getaxes(x)
    ind_tups = @. getindex(axs, getval(args))
    inds = first.(ind_tups)
    new_axs = @. Axis(ind_tups)
    return :(Base.@_inline_meta; CArray(Base.maybeview(getdata(x), $inds...), $new_axs...))
end

# Set index
Base.@inline Base.setindex!(x::CArray, v, idx::FlatIdx...) = setindex!(getdata(x), v, idx...)
Base.@inline Base.setindex!(x::CArray, v, idx::Colon) = setindex!(getdata(x), v, :)
Base.@inline Base.setindex!(x::CArray, v, idx...) = setindex!(x, v, fastindices(idx)...)
Base.@inline Base.setindex!(x::CArray, v, idx::Val...) = _setindex!(x, v, idx...)
@generated function _setindex!(x::CArray, v, args...)
    axs = getaxes(x)
    ind_tups = @. getindex(axs, getval(args))
    inds = first.(ind_tups)
    new_axs = @. Axis(ind_tups)
    return :(Base.@_inline_meta; setindex!(getdata(x), v, $inds...))
end

# Need this for faster x.key .= val index setting
Base.dotview(x::CArray, args...) = getindex(x, args...)

# Property access for CVectors goes through _get/_setindex
Base.@inline Base.getproperty(x::CVector, s::Symbol) = _getindex(x, Val(s)) #CArray(_getindex(x, Val(s))...)
Base.@inline Base.setproperty!(x::CVector, s::Symbol, v) = _setindex!(x, v, Val(s))
