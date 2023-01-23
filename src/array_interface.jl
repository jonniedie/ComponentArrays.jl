Base.parent(x::ComponentArray) = getfield(x, :data)

Base.size(x::ComponentArray) = size(getdata(x))
ArrayInterface.size(A::ComponentArray) = ArrayInterface.size(parent(A))

Base.elsize(x::Type{<:ComponentArray{T,N,A,Axes}}) where {T,N,A,Axes} = Base.elsize(A)

# Base.axes(x::ComponentArray) = axes(getdata(x))
Base.axes(x::ComponentArray) = CombinedAxis.(getaxes(x), axes(getdata(x)))

Base.reinterpret(::Type{T}, x::ComponentArray, args...) where T = ComponentArray(reinterpret(T, getdata(x), args...), getaxes(x))

Base.reshape(A::AbstractArray, axs::NTuple{N,<:CombinedAxis}) where {N} = reshape(A, _array_axis.(axs))

ArrayInterfaceCore.indices_do_not_alias(::Type{ComponentArray{T,N,A,Axes}}) where {T,N,A,Axes} = ArrayInterfaceCore.indices_do_not_alias(A)
ArrayInterfaceCore.instances_do_not_alias(::Type{ComponentArray{T,N,A,Axes}}) where {T,N,A,Axes} = ArrayInterfaceCore.instances_do_not_alias(A)

# Cats
function Base.cat(inputs::ComponentArray...; dims::Int)
    combined_data = cat(getdata.(inputs)...; dims=dims)
    axes_to_merge = [(getaxes(i)..., FlatAxis())[dims] for i in inputs]
    rest_axes = [getaxes(i)[1:end .!= dims] for i in inputs]
    no_duplicate_keys = (length(inputs) == 1 || allunique(vcat(collect.(keys.(axes_to_merge))...)))
    if no_duplicate_keys && length(Set(rest_axes)) == 1
        offsets = (0, cumsum(size.(inputs, dims))[1:(end - 1)]...)
        merged_axis = Axis(merge(indexmap.(reindex.(axes_to_merge, offsets))...))
        result_axes = (first(rest_axes)[1:(dims - 1)]..., merged_axis, first(rest_axes)[dims:end]...)
        return ComponentArray(combined_data, result_axes...)
    else
        return combined_data
    end
end

Base.hcat(inputs::ComponentArray...) = Base.cat(inputs...; dims=2)
Base.vcat(inputs::ComponentArray...) = Base.cat(inputs...; dims=1)
function Base._typed_hcat(::Type{T}, inputs::Base.AbstractVecOrTuple{ComponentArray}) where {T}
    return Base.cat(map(i -> T.(i), inputs)...; dims=2)
end
function Base._typed_vcat(::Type{T}, inputs::Base.AbstractVecOrTuple{ComponentArray}) where {T}
    return Base.cat(map(i -> T.(i), inputs)...; dims=1)
end

function Base.hvcat(row_lengths::NTuple{N,Int}, xs::AbstractComponentVecOrMat...) where {N}
    i = 1
    idxs = UnitRange{Int}[]
    for row_length in row_lengths
        i_last = i + row_length - 1
        push!(idxs, i:i_last)
        i = i_last + 1
    end
    rows = [reduce(hcat, xs[idx]) for idx in idxs]
    return vcat(rows...)
end

function Base.permutedims(x::ComponentArray, dims)
    axs = getaxes(x)
    return ComponentArray(permutedims(getdata(x), dims), map(i->axs[i], dims)...)
end

## Indexing
Base.IndexStyle(::Type{<:ComponentArray{T,N,<:A,<:Axes}}) where {T,N,A,Axes} = IndexStyle(A)

# Since we aren't really using the standard approach to indexing, this will forward things to
# the correct methods
Base.to_indices(x::ComponentArray, i::Tuple) = i
Base.to_indices(x::ComponentArray, i::NTuple{N,Union{Integer, CartesianIndex}}) where N = i
Base.to_indices(x::ComponentArray, i::NTuple{N,Int64}) where N = i
Base.to_index(x::ComponentArray, i) = i

# Get ComponentArray index
Base.@propagate_inbounds Base.getindex(x::ComponentArray, idx::CartesianIndex) = getdata(x)[idx]
Base.@propagate_inbounds Base.getindex(x::ComponentArray, idx::FlatIdx...) = getdata(x)[idx...]
Base.@propagate_inbounds function Base.getindex(x::ComponentArray, idx::FlatOrColonIdx...)
    axs = map((ax, i) -> getindex(ax, i).ax, getaxes(x), idx)
    axs = remove_nulls(axs...)
    return ComponentArray(getdata(x)[idx...], axs...)
end
Base.@propagate_inbounds Base.getindex(x::ComponentArray, ::Colon) = getdata(x)[:]
Base.@propagate_inbounds Base.getindex(x::ComponentArray, ::Colon...) = x
@inline Base.getindex(x::ComponentArray, idx...) = getindex(x, toval.(idx)...)
@inline Base.getindex(x::ComponentArray, idx::Val...) = _getindex(getindex, x, idx...)

# Set ComponentArray index
Base.@propagate_inbounds Base.setindex!(x::ComponentArray, v, idx::FlatOrColonIdx...) = setindex!(getdata(x), v, idx...)
Base.@propagate_inbounds Base.setindex!(x::ComponentArray, v, ::Colon) = setindex!(getdata(x), v, :)
@inline Base.setindex!(x::ComponentArray, v, idx...) = setindex!(x, v, toval.(idx)...)
@inline Base.setindex!(x::ComponentArray, v, idx::Val...) = _setindex!(x, v, idx...)

# Explicitly view
Base.@propagate_inbounds Base.view(x::ComponentArray, idx::ComponentArrays.FlatIdx...) = view(getdata(x), idx...)
Base.@propagate_inbounds Base.view(x::ComponentArray, idx...) = _getindex(view, x, toval.(idx)...)

Base.@propagate_inbounds Base.maybeview(x::ComponentArray, idx::ComponentArrays.FlatIdx...) = Base.maybeview(getdata(x), idx...)
Base.@propagate_inbounds Base.maybeview(x::ComponentArray, idx...) = _getindex(Base.maybeview, x, toval.(idx)...)

# Generated get and set index methods to do all of the heavy lifting in the type domain
@generated function _getindex(index_fun, x::ComponentArray, idx...)
    ci = getindex.(getaxes(x), getval.(idx))
    inds = map(i -> i.idx, ci)
    axs = map(i -> i.ax, ci)
    axs = remove_nulls(axs...)
    return :(ComponentArray(index_fun(getdata(x), $inds...), $axs...))
end

@generated function _setindex!(x::ComponentArray, v, idx...)
    ci = getindex.(getaxes(x), getval.(idx))
    inds = map(i -> i.idx, ci)
    return :(setindex!(getdata(x), v, $inds...))
end

## Linear Algebra
Base.pointer(x::ComponentArray{T,N,A,Axes}) where {T,N,A<:DenseArray,Axes} = pointer(getdata(x))

Base.unsafe_convert(::Type{Ptr{T}}, x::ComponentArray{T,N,A,Axes}) where {T,N,A,Axes} = Base.unsafe_convert(Ptr{T}, getdata(x))

Base.strides(x::ComponentArray) = strides(getdata(x))
for f in [:device, :stride_rank, :contiguous_axis, :contiguous_batch_size, :dense_dims] 
    @eval ArrayInterface.$f(::Type{ComponentArray{T,N,A,Axes}}) where {T,N,A,Axes} = ArrayInterface.$f(A)
end

Base.stride(x::ComponentArray, k) = stride(getdata(x), k)
Base.stride(x::ComponentArray, k::Int64) = stride(getdata(x), k)

ArrayInterfaceCore.parent_type(::Type{ComponentArray{T,N,A,Axes}}) where {T,N,A,Axes} = A
