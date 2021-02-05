## Field access through these functions to reserve dot-getting for keys
@inline getaxes(x::VarAxes) = getaxes(typeof(x))
@inline getaxes(Ax::Type{<:Axes}) where {Axes<:VarAxes} = map(x->x(), (Ax.types...,))

getaxes(x) = ()


# Since we aren't really using the standard approach to indexing, this will forward things to
# the correct methods
Base.to_indices(x::ComponentArray, i::Tuple) = i
Base.to_indices(x::ComponentArray, i::Tuple{Vararg{Union{Integer, CartesianIndex}, N}}) where N = i
Base.to_indices(x::ComponentArray, i::Tuple{Vararg{Int64}}) where N = i
Base.to_index(x::ComponentArray, i) = i

# Get AbstractAxis index
@inline Base.getindex(::AbstractAxis, idx::FlatIdx) = ComponentIndex(idx)
@inline Base.getindex(ax::AbstractAxis, ::Colon) = ComponentIndex(:, ax)
@inline Base.getindex(::AbstractAxis{IdxMap}, s::Symbol) where IdxMap =
    ComponentIndex(getproperty(IdxMap, s))

# Get ComponentArray index
Base.@propagate_inbounds Base.getindex(x::ComponentArray, idx::CartesianIndex) = getdata(x)[idx]
Base.@propagate_inbounds Base.getindex(x::ComponentArray, idx::FlatIdx...) = getdata(x)[idx...]
Base.@propagate_inbounds function Base.getindex(x::ComponentArray, idx::FlatOrColonIdx...)
    axs = map((ax, i) -> getindex(ax, i).ax, getaxes(x), idx)
    axs = remove_nulls(axs...)
    return ComponentArray(getdata(x)[idx...], axs...)
end
Base.@propagate_inbounds Base.getindex(x::ComponentArray, ::Colon) = getdata(x)[:]
@inline Base.getindex(x::ComponentArray, ::Colon...) = x
Base.@propagate_inbounds Base.getindex(x::ComponentArray, idx...) = getindex(x, toval.(idx)...)
@inline Base.getindex(x::ComponentArray, idx::Val...) = _getindex(x, idx...)

# Set ComponentArray index
Base.@propagate_inbounds Base.setindex!(x::ComponentArray, v, idx::FlatIdx...) = setindex!(getdata(x), v, idx...)
Base.@propagate_inbounds Base.setindex!(x::ComponentArray, v, ::Colon) = setindex!(getdata(x), v, :)
Base.@propagate_inbounds Base.setindex!(x::ComponentArray, v, idx...) = setindex!(x, v, toval.(idx)...)
@inline Base.setindex!(x::ComponentArray, v, idx::Val...) = _setindex!(x, v, idx...)


# Property access for CVectors goes through _get/_setindex
@inline Base.getproperty(x::ComponentVector, s::Symbol) = _getindex(x, Val(s))
@inline Base.getproperty(x::ComponentVector, s::Val) = _getindex(x, s)

@inline Base.setproperty!(x::ComponentVector, s::Symbol, v) = _setindex!(x, v, Val(s))
@inline Base.setproperty!(x::ComponentVector, s::Val, v) = _setindex!(x, v, s)


# Generated get and set index methods to do all of the heavy lifting in the type domain
@generated function _getindex(x::ComponentArray, idx...)
    ci = getindex.(getaxes(x), getval.(idx))
    inds = map(i -> i.idx, ci)
    axs = map(i -> i.ax, ci)
    axs = remove_nulls(axs...)
    # the index must be valid after computing `ci`
    :(Base.@_inline_meta; @inbounds ComponentArray(Base.maybeview(getdata(x), $inds...), $axs...))
end

@generated function _setindex!(x::ComponentArray, v, idx...)
    ci = getindex.(getaxes(x), getval.(idx))
    inds = map(i -> i.idx, ci)
    # the index must be valid after computing `ci`
    return :(Base.@_inline_meta; @inbounds setindex!(getdata(x), v, $inds...))
end

Base.@propagate_inbounds Base.view(x::ComponentArray, idx::ComponentArrays.FlatIdx...) = view(getdata(x), idx...)
Base.@propagate_inbounds Base.view(x::ComponentArray, idx...) = _getindex(x, toval.(idx)...)