Base.parent(x::ComponentArray) = getfield(x, :data)

Base.size(x::ComponentArray) = size(getdata(x))
ArrayInterface.size(A::ComponentArray) = ArrayInterface.size(parent(A))

Base.elsize(x::Type{<:ComponentArray{T,N,A,Axes}}) where {T,N,A,Axes} = Base.elsize(A)

Base.axes(x::ComponentArray) = axes(getdata(x))

Base.reinterpret(::Type{T}, x::ComponentArray, args...) where T = ComponentArray(reinterpret(T, getdata(x), args...), getaxes(x))

Base.hcat(x::CV...) where {CV<:ComponentVector} = ComponentArray(reduce(hcat, getdata.(x)), getaxes(x[1])[1], FlatAxis())

Base.vcat(x::ComponentVector, y::AbstractVector) = vcat(getdata(x), y)
Base.vcat(x::AbstractVector, y::ComponentVector) = vcat(x, getdata(y))
function Base.vcat(x::ComponentVector, y::ComponentVector)
    if reduce((accum, key) -> accum || (key in keys(x)), keys(y); init=false)
        return vcat(getdata(x), getdata(y))
    else
        data_x, data_y = getdata.((x, y))
        ax_x, ax_y = only.(getaxes.((x, y)))
        ax_y = reindex(ax_y, length(x))
        idxmap_x, idxmap_y = indexmap.((ax_x, ax_y))
        return ComponentArray(vcat(data_x, data_y), Axis((;idxmap_x..., idxmap_y...)))
    end
end
Base.vcat(x::CV...) where {CV<:AdjOrTransComponentArray} = ComponentArray(reduce(vcat, map(y->getdata(y.parent)', x)), getaxes(x[1]))
Base.vcat(x::ComponentVector...) = reduce(vcat, x)
Base.vcat(x::ComponentVector, args...) = vcat(getdata(x), getdata.(args)...)
Base.vcat(x::ComponentVector, args::Vararg{AbstractVector{T}, N}) where {T,N} = vcat(getdata(x), getdata.(args)...)

function Base.permutedims(x::ComponentArray, dims)
    axs = getaxes(x)
    return ComponentArray(permutedims(getdata(x), dims), map(i->axs[i], dims)...)
end

## Indexing
Base.IndexStyle(::Type{<:ComponentArray{T,N,<:A,<:Axes}}) where {T,N,A,Axes} = IndexStyle(A)

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
@inline Base.setindex!(x::ComponentArray, v, idx::FlatIdx...) = setindex!(getdata(x), v, idx...)
Base.@propagate_inbounds Base.setindex!(x::ComponentArray, v, ::Colon) = setindex!(getdata(x), v, :)
Base.@propagate_inbounds Base.setindex!(x::ComponentArray, v, idx...) = setindex!(x, v, toval.(idx)...)
@inline Base.setindex!(x::ComponentArray, v, idx::Val...) = _setindex!(x, v, idx...)

# Explicitly view
Base.@propagate_inbounds Base.view(x::ComponentArray, idx::ComponentArrays.FlatIdx...) = view(getdata(x), idx...)
Base.@propagate_inbounds Base.view(x::ComponentArray, idx...) = _getindex(x, toval.(idx)...)

# Generated get and set index methods to do all of the heavy lifting in the type domain
@generated function _getindex(x::ComponentArray, idx...)
    ci = getindex.(getaxes(x), getval.(idx))
    inds = map(i -> i.idx, ci)
    axs = map(i -> i.ax, ci)
    axs = remove_nulls(axs...)
    # the index must be valid after computing `ci`
    :(Base.@_inline_meta; ComponentArray(Base.maybeview(getdata(x), $inds...), $axs...))
end

@generated function _setindex!(x::ComponentArray, v, idx...)
    ci = getindex.(getaxes(x), getval.(idx))
    inds = map(i -> i.idx, ci)
    # the index must be valid after computing `ci`
    return :(Base.@_inline_meta; setindex!(getdata(x), v, $inds...))
end

## Linear Algebra
Base.pointer(x::ComponentArray{T,N,A,Axes}) where {T,N,A<:DenseArray,Axes} = pointer(getdata(x))

Base.unsafe_convert(::Type{Ptr{T}}, x::ComponentArray{T,N,A,Axes}) where {T,N,A,Axes} = Base.unsafe_convert(Ptr{T}, getdata(x))

Base.strides(x::ComponentArray) = strides(getdata(x))
ArrayInterface.strides(A::ComponentArray) = ArrayInterface.strides(parent(A))
for f in [:device, :stride_rank, :contiguous_axis, :contiguous_batch_size, :dense_dims] 
    @eval ArrayInterface.$f(::Type{ComponentArray{T,N,A,Axes}}) where {T,N,A,Axes} = ArrayInterface.$f(A)
end

Base.stride(x::ComponentArray, k) = stride(getdata(x), k)
Base.stride(x::ComponentArray, k::Int64) = stride(getdata(x), k)

ArrayInterface.lu_instance(jac_prototype::ComponentArray) = ArrayInterface.lu_instance(getdata(jac_prototype))

ArrayInterface.parent_type(::Type{ComponentArray{T,N,A,Axes}}) where {T,N,A,Axes} = A



# While there are some cases where these were faster, it is going to be almost impossible to
# to keep up with method ambiguity errors due to other array types overloading *, /, and \.
# Leaving these here and commented out for now, but will delete them later.

# # Avoid slower fallback
# for f in [:(*), :(/), :(\)]
#     @eval begin
#         # The normal stuff
#         Base.$f(x::ComponentArray, y::AbstractArray) = $f(getdata(x), y)
#         Base.$f(x::AbstractArray, y::ComponentArray) = $f(x, getdata(y))
#         Base.$f(x::ComponentArray, y::ComponentArray) = $f(getdata(x), getdata(y))

#         # A bunch of special cases to avoid ambiguous method errors
#         Base.$f(x::ComponentArray, y::AbstractMatrix) = $f(getdata(x), y)
#         Base.$f(x::AbstractMatrix, y::ComponentArray) = $f(x, getdata(y))

#         Base.$f(x::ComponentArray, y::AbstractVector) = $f(getdata(x), y)
#         Base.$f(x::AbstractVector, y::ComponentArray) = $f(x, getdata(y))
#     end
# end

# # Adjoint/transpose special cases
# for f in [:(*), :(/)]
#     @eval begin
#         Base.$f(x::Adjoint, y::ComponentArray) = $f(getdata(x), getdata(y))
#         Base.$f(x::Transpose, y::ComponentArray) = $f(getdata(x), getdata(y))

#         Base.$f(x::Adjoint{T,<:AbstractVector{T}}, y::ComponentVector) where T = $f(x, getdata(y))
#         Base.$f(x::Transpose{T,<:AbstractVector{T}}, y::ComponentVector) where T = $f(x, getdata(y))

#         Base.$f(x::Adjoint{T,<:AbstractVector{T}}, y::ComponentMatrix{T,A,Axes}) where {T,A,Axes} = $f(x, getdata(y))
#         Base.$f(x::Transpose{T,<:AbstractVector{T}}, y::ComponentMatrix{T,A,Axes}) where {T,A,Axes} = $f(x, getdata(y))

#         Base.$f(x::Adjoint{T,<:AbstractMatrix{T}}, y::ComponentVector) where {T} = $f(x, getdata(y))
#         Base.$f(x::Transpose{T,<:AbstractMatrix{T}}, y::ComponentVector) where {T} = $f(x, getdata(y))

#         Base.$f(x::ComponentArray, y::Adjoint{T,<:AbstractVector{T}}) where T = $f(getdata(x), y)
#         Base.$f(x::ComponentArray, y::Transpose{T,<:AbstractVector{T}}) where T = $f(getdata(x), y)

#         Base.$f(x::ComponentArray, y::Adjoint{T,<:ComponentVector}) where T = $f(getdata(x), getdata(y))
#         Base.$f(x::ComponentArray, y::Transpose{T,<:ComponentVector}) where T = $f(getdata(x), getdata(y))

#         # There seems to be a new method in Julia > v.1.4 that specializes on this
#         Base.$f(x::Adjoint{T,<:AbstractVector{T}}, y::ComponentVector{T,A,Axes}) where {T<:Number,A,Axes} = $f(x, getdata(y))
#         Base.$f(x::Transpose{T,<:AbstractVector{T}}, y::ComponentVector{T,A,Axes}) where {T<:Number,A,Axes} = $f(x, getdata(y))

#         Base.$f(x::Adjoint{T,<:AbstractVector{T}}, y::ComponentVector{T,A,Axes}) where {T<:Real,A,Axes} = $f(getdata(x), getdata(y))
#         Base.$f(x::Transpose{T,<:AbstractVector{T}}, y::ComponentVector{T,A,Axes}) where {T<:Real,A,Axes} = $f(getdata(x), getdata(y))
#     end
# end