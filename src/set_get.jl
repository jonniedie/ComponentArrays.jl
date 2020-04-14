getval(::Val{x}) where x = x
getval(::Type{Val{x}}) where x = x

Base.to_index(x::CArray, i) = i

totuple(x) = (x, NamedTuple())
totuple(x::Tuple) = x


## Axis indexing
Base.@inline Base.getindex(::Ax, x::Union{FlatIdx, Symbol, Colon}) where Ax<:Axis = getindex(Ax, x)
Base.@inline Base.getindex(::Type{Axis{IdxMap}}, x::FlatIdx) where IdxMap = totuple(x)
Base.@inline Base.getindex(::Type{Axis{IdxMap}}, x::Symbol) where IdxMap = totuple(getfield(IdxMap, x))
Base.@inline Base.getindex(::Type{Axis{IdxMap}}, x::Colon) where IdxMap = (:, IdxMap)


## CArray indexing
# Get index
Base.@inline Base.getindex(x::CArray, idx::FlatIdx...) = _data(x)[idx...]
Base.@inline Base.getindex(x::CVector, idx::Colon) = x
Base.@inline Base.getindex(x::CArray, idx::Colon) = view(_data(x), :)
@noinline Base.getindex(x::CArray, idx) = getindex(x, Val(idx))
@noinline Base.getindex(x::CArray, idx...) = getindex(x, map(Val, idx)...) #Val.(idx)...)
Base.@inline Base.getindex(x::CArray, idx::Val...) = _getindex(x, idx...) #CArray(_getindex(x, idx...)...)
@generated function _getindex(x::CArray, args...)
    axs = _axes(x)
    ind_tups = @. getindex(axs, getval(args))
    inds = first.(ind_tups)
    new_axs = @. Axis(ind_tups)
    return :(Base.@_inline_meta; CArray(Base.maybeview(_data(x), $inds...), $new_axs...))
end

# Set index
Base.@inline Base.setindex!(x::CArray, v, idx::FlatIdx...) = setindex!(_data(x), v, idx...)
Base.@inline Base.setindex!(x::CArray, v, idx::Colon) = setindex!(_data(x), v, :)
Base.@inline Base.setindex!(x::CArray, v, idx...) = setindex!(x, v, Val.(idx)...)
Base.@inline Base.setindex!(x::CArray, v, idx::Val...) = _setindex!(x, v, idx...)
@generated function _setindex!(x::CArray, v, args...)
    axs = _axes(x)
    ind_tups = @. getindex(axs, getval(args))
    inds = first.(ind_tups)
    new_axs = @. Axis(ind_tups)
    return :(Base.@_inline_meta; setindex!(_data(x), v, $inds...))
end

# Need this for faster x.key .= val index setting
Base.dotview(x::CArray, args...) = getindex(x, args...)

# Property access for CVectors goes through _get/_setindex
Base.@inline Base.getproperty(x::CVector, s::Symbol) = _getindex(x, Val(s)) #CArray(_getindex(x, Val(s))...)
Base.@inline Base.setproperty!(x::CVector, s::Symbol, v) = _setindex!(x, v, Val(s))
