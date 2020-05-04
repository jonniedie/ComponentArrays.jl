Base.to_index(x::ComponentArray, i) = i

totuple(x) = (x, NamedTuple())
totuple(x::Tuple) = x


## Field access through these functions to reserve dot-getting for keys
"""
    getaxes(x::ComponentArray)

Access ```.axes``` field of a ```ComponentArray```. This is different than ```axes(x::ComponentArray)```, which
    returns the axes of the contained array.

# Examples

```jldoctest
julia> using ComponentArrays

julia> ax = Axis(a=1:3, b=(4:6, (a=1, b=2:3)))
Axis{(a = 1:3, b = (4:6, (a = 1, b = 2:3)))}()

julia> A = zeros(6,6);

julia> ca = ComponentArray(A, (ax, ax))
6×6 ComponentArray{Tuple{Axis{(a = 1:3, b = (4:6, (a = 1, b = 2:3)))},Axis{(a = 1:3, b = (4:6, (a = 1, b = 2:3)))}},Float64,2,Array{Float64,2}}:
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
@inline getaxes(x::ComponentArray) = getfield(x, :axes)
@inline getaxes(::Type{ComponentArray{Axes,T,N,A}}) where {Axes,T,N,A} = map(x->x(), (Axes.types...,))
@inline getaxes(x::VarAxes) = getaxes(typeof(x))
@inline getaxes(::Type{<:Axes}) where {Axes<:VarAxes} = map(x->x(), (Axes.types...,))

"""
    getdata(x::ComponentArray)

Access ```.data``` field of a ```ComponentArray```, which contains the array that ```ComponentArray``` wraps.
"""
getdata(x::ComponentArray) = getfield(x, :data)
getdata(x) = x


Base.keys(x::CVector) = keys(idxmap(getaxes(x)[1]))


## Axis indexing
@inline Base.getindex(::Ax, x::Union{FlatIdx, Symbol, Colon}) where Ax<:Axis = getindex(Ax, x)
@inline Base.getindex(::Type{Axis{IdxMap}}, x::FlatIdx) where IdxMap = totuple(x)
@inline Base.getindex(::Type{Axis{IdxMap}}, x::Symbol) where IdxMap = totuple(getfield(IdxMap, x))
@inline Base.getindex(::Type{Axis{IdxMap}}, x::Colon) where IdxMap = (:, IdxMap)


## ComponentArray indexing
# Get index
@inline Base.getindex(x::ComponentArray, idx::FlatIdx...) = getdata(x)[idx...]
@inline Base.getindex(x::CVector, idx::Colon) = x
@inline Base.getindex(x::ComponentArray, idx::Colon) = view(getdata(x), :)
@inline Base.getindex(x::ComponentArray, idx) = getindex(x, Val(idx))
@inline Base.getindex(x::ComponentArray, idx...) = getindex(x, fastindices(idx)...) #Val.(idx)...)
@inline Base.getindex(x::ComponentArray, idx::Val...) = _getindex(x, idx...) #ComponentArray(_getindex(x, idx...)...)
@generated function _getindex(x::ComponentArray, args...)
    axs = getaxes(x)
    ind_tups = @. getindex(axs, getval(args))
    inds = first.(ind_tups)
    new_axs = @. Axis(ind_tups)
    return :(Base.@_inline_meta; ComponentArray(Base.maybeview(getdata(x), $inds...), $new_axs...))
end

# Set index
@inline Base.setindex!(x::ComponentArray, v, idx::FlatIdx...) = setindex!(getdata(x), v, idx...)
@inline Base.setindex!(x::ComponentArray, v, idx::Colon) = setindex!(getdata(x), v, :)
@inline Base.setindex!(x::ComponentArray, v, idx...) = setindex!(x, v, fastindices(idx)...)
@inline Base.setindex!(x::ComponentArray, v, idx::Val...) = _setindex!(x, v, idx...)
@generated function _setindex!(x::ComponentArray, v, args...)
    axs = getaxes(x)
    ind_tups = @. getindex(axs, getval(args))
    inds = first.(ind_tups)
    new_axs = @. Axis(ind_tups)
    return :(Base.@_inline_meta; setindex!(getdata(x), v, $inds...))
end

# Need this for faster x.key .= val index setting
Base.dotview(x::ComponentArray, args...) = getindex(x, args...)

# Property access for CVectors goes through _get/_setindex
@inline Base.getproperty(x::CVector, s::Symbol) = _getindex(x, Val(s)) #ComponentArray(_getindex(x, Val(s))...)
@inline Base.setproperty!(x::CVector, s::Symbol, v) = _setindex!(x, v, Val(s))
