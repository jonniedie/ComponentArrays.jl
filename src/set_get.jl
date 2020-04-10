getval(::Val{x}) where x = x
getval(::Type{Val{x}}) where x = x

Base.to_index(x::CArray, i) = i


## Axis indexing
Base.getindex(::Axis{L,IdxMap}, x::FlatIdx) where {L,IdxMap} = totuple(x)
Base.getindex(::Axis{L,IdxMap}, x::Symbol) where {L,IdxMap} = totuple(getfield(IdxMap, x))
Base.getindex(::Axis{L,IdxMap}, x::Colon) where {L,IdxMap} = (:, IdxMap)
Base.getindex(::Type{Axis{L,IdxMap}}, x::FlatIdx) where {L,IdxMap} = totuple(x)
Base.getindex(::Type{Axis{L,IdxMap}}, x::Symbol) where {L,IdxMap} = totuple(getfield(IdxMap, x))
Base.getindex(::Type{Axis{L,IdxMap}}, x::Colon) where {L,IdxMap} = (:, IdxMap)



## CArray indexing
# Get index
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
    return :(Base.@_pure_meta; setindex!(_data(x), v, $inds...))
end

# Property access for CVectors goes through _get/_setindex
Base.@inline Base.getproperty(x::CVector, s::Symbol) = CArray(_getindex(x, Val(s))...)
Base.@inline Base.setproperty!(x::CVector, s::Symbol, v) = _setindex!(x, v, Val(s))

# Need this for faster x.key .= val index setting
Base.dotview(x::CArray, args...) = getindex(x, args...)
