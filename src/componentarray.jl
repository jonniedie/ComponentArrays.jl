"""
    x = ComponentArray(nt::NamedTuple)
    x = ComponentArray(;kwargs...)
    x = ComponentArray(data::AbstractVector, ax)
    x = ComponentArray{T}(args...; kwargs...) where T

Array type that can be accessed like an arbitrary nested mutable struct.

# Examples

```jldoctest
julia> using ComponentArrays

julia> x = ComponentArray(a=1, b=[2, 1, 4], c=(a=2, b=[1, 2]))
ComponentVector{Int64}(a = 1, b = [2, 1, 4], c = (a = 2, b = [1, 2]))

julia> x.c.a = 400; x
ComponentVector{Int64}(a = 1, b = [2, 1, 4], c = (a = 400, b = [1, 2]))

julia> x[5]
400

julia> collect(x)
7-element Array{Int64,1}:
   1
   2
   1
   4
 400
   1
   2
```
"""
struct ComponentArray{T,N,A<:AbstractArray{T,N},Axes<:Tuple{Vararg{<:AbstractAxis}}} <: DenseArray{T,N}
    data::A
    axes::Axes
end

# Entry from type (used for broadcasting)
ComponentArray{Axes}(data) where Axes = ComponentArray(data, getaxes(Axes)...)
ComponentArray(::UndefInitializer, ax::Axes) where Axes<:Tuple =
    ComponentArray(similar(Array{Float64}, last_index.(ax)), ax...)
ComponentArray{A}(::UndefInitializer, ax::Axes) where {A<:AbstractArray,Axes<:Tuple} =
    ComponentArray(similar(A, last_index.(ax)), ax...)
ComponentArray{T}(::UndefInitializer, ax::Axes) where {T,Axes<:Tuple} =
    ComponentArray(similar(Array{T}, last_index.(ax)), ax...)

# Entry from data array and AbstractAxis types dispatches to correct shapes and partitions
# then packs up axes into a tuple for inner constructor
ComponentArray(data, ::FlatAxis...) = data
ComponentArray(data, ax::NotShapedOrPartitionedAxis...) = ComponentArray(data, ax)
ComponentArray(data, ax::NotPartitionedAxis...) = ComponentArray(maybe_reshape(data, ax...), unshape.(ax)...)
function ComponentArray(data, ax::AbstractAxis...)
    part_axs = filter_by_type(PartitionedAxis, ax...)
    part_data = partition(data, size.(part_axs)...)
    axs = Axis.(ax)
    return LazyArray(ComponentArray(x, axs) for x in part_data)
end

# Entry from NamedTuple, Dict, or kwargs
ComponentArray{T}(nt::NamedTuple) where T = ComponentArray(make_carray_args(T, nt)...)
ComponentArray(nt::NamedTuple) = ComponentArray(make_carray_args(nt)...)
ComponentArray(d::AbstractDict) = ComponentArray(NamedTuple{Tuple(keys(d))}(values(d)))
ComponentArray{T}(;kwargs...) where T = ComponentArray{T}((;kwargs...))
ComponentArray(;kwargs...) = ComponentArray((;kwargs...))

ComponentArray(x::ComponentArray) = x
ComponentArray{T}(x::ComponentArray) where {T} = T.(x)
(CA::Type{<:ComponentArray{T,N,A,Ax}})(x::ComponentArray) where {T,N,A,Ax} = ComponentArray(T.(getdata(x)), getaxes(x))

## Some aliases
"""
    x = ComponentVector(nt::NamedTuple)
    x = ComponentVector(;kwargs...)
    x = ComponentVector(data::AbstractVector, ax)
    x = ComponentVector{T}(args...; kwargs...) where T

A `ComponentVector` is an alias for a one-dimensional `ComponentArray`.
"""
const ComponentVector{T,A,Axes} = ComponentArray{T,1,A,Axes}
ComponentVector(nt) = ComponentArray(nt)
ComponentVector{T}(nt) where {T} = ComponentArray{T}(nt)
ComponentVector(;kwargs...) = ComponentArray(;kwargs...)
ComponentVector{T}(;kwargs...) where {T} = ComponentArray{T}(;kwargs...)
ComponentVector{T}(::UndefInitializer, ax) where {T} = ComponentArray{T}(undef, ax)
ComponentVector(data::AbstractVector, ax) = ComponentArray(data, ax)
ComponentVector(data::AbstractArray, ax) = throw(DimensionMismatch("A `ComponentVector` must be initialized with a 1-dimensional array. This array is $(ndims(data))-dimensional."))

# Add new fields to component Vector
function ComponentArray(x::ComponentVector; kwargs...)
    return foldl((x1, kwarg) -> _maybe_add_field(x1, kwarg), (kwargs...,); init=x)
end
ComponentVector(x::ComponentVector; kwargs...) = ComponentArray(x; kwargs...)

ComponentVector{T}(x::ComponentVector) where {T} = T.(x)


"""
    x = ComponentMatrix(data::AbstractMatrix, ax...)
    x = ComponentMatrix{T}(data::AbstractMatrix, ax...) where T

A `ComponentMatrix` is an alias for a two-dimensional `ComponentArray`.
"""
const ComponentMatrix{T,A,Axes} = ComponentArray{T,2,A,Axes}
ComponentMatrix{T}(::UndefInitializer, ax...) where {T} = ComponentArray{T}(undef, ax...)
ComponentMatrix(data::AbstractMatrix, ax...) = ComponentArray(data, ax...)
ComponentMatrix(data::AbstractArray, ax...) = throw(DimensionMismatch("A `ComponentMatrix` must be initialized with a 2-dimensional array. This array is $(ndims(data))-dimensional."))

ComponentMatrix(x::ComponentMatrix) = x
ComponentMatrix{T}(x::ComponentMatrix) where {T} = T.(x)

const CArray = ComponentArray
const CVector = ComponentVector
const CMatrix = ComponentMatrix

const AdjOrTrans{T, A} = Union{Adjoint{T, A}, Transpose{T, A}}
const AdjOrTransComponentArray{T, A} = Union{Adjoint{T, A}, Transpose{T, A}} where A<:ComponentArray


## Constructor helpers
# For making ComponentArrays from named tuples
function make_carray_args(nt)
    data, ax = make_carray_args(Vector, nt)
    data = length(data)==1 ? [data[1]] : reduce(vcat, data)
    return (data, ax)
end
make_carray_args(T::Type, nt) = make_carray_args(Vector{T}, nt)
function make_carray_args(A::Type{<:AbstractArray}, nt)
    data, idx = make_idx([], nt, 0)
    return (A(data), Axis(idx))
end

# Builds up data vector and returns appropriate AbstractAxis type for each input type
function make_idx(data, nt::NamedTuple, last_val)
    len = recursive_length(nt)
    kvs = []
    lv = 0
    for (k,v) in zip(keys(nt), nt)
        (_,val) = make_idx(data, v, lv)
        push!(kvs, k => val)
        lv = val
    end
    return (data, ViewAxis(last_index(last_val) .+ (1:len), (;kvs...)))
end
function make_idx(data, pair::Pair, last_val)
    data, ax = make_idx(data, pair.second, last_val)
    return (data, ViewAxis(last_val:(last_val+len-1), Axis(pair.second)))
end
make_idx(data, x, last_val) = (
    push!(data, x),
    ViewAxis(last_index(last_val) + 1)
)
make_idx(data, x::ComponentVector, last_val) = (
    pushcat!(data, x),
    ViewAxis(
        last_index(last_val) .+ (1:length(x)),
        getaxes(x)[1]
    )
)
function make_idx(data, x::AbstractArray, last_val)
    pushcat!(data, x)
    out = last_index(last_val) .+ (1:length(x))
    return (data, ViewAxis(out, ShapedAxis(size(x))))
end
function make_idx(data, x::A, last_val) where A<:AbstractArray{<:Union{NamedTuple, ComponentArray}}
    len = recursive_length(x)
    if eltype(x) |> isconcretetype
        out = ()
        for elem in x
            (_,out) = make_idx(data, elem, last_val)
        end
        return (
            data,
            ViewAxis(
                last_index(last_val) .+ (1:len),
                PartitionedAxis(
                    len ÷ length(x),
                    indexmap(out)
                )
            )
        )
    else
        error("Only homogeneous arrays of inner ComponentArrays are allowed.")
    end
end


#TODO: Make all internal function names start with underscores
_maybe_add_field(x, pair) = haskey(x, pair.first) ? _update_field(x, pair) : _add_field(x, pair)
function _add_field(x, pair)
    data = copy(getdata(x))
    new_data, new_ax = make_idx(data, pair.second, length(data))
    new_ax = Axis(NamedTuple{tuple(pair.first)}(tuple(new_ax)))
    new_ax = merge(getaxes(x)[1], new_ax)
    return ComponentArray(new_data, new_ax)
end
function _update_field(x, pair)
    x_copy = copy(x)
    x_copy[pair.first] = pair.second
    return x_copy
end

pushcat!(a, b) = reduce((x1,x2) -> push!(x1,x2), b; init=a)

# Reshape ComponentArrays with ShapedAxis axes
maybe_reshape(data, ::NotShapedOrPartitionedAxis...) = data
function maybe_reshape(data, axs::AbstractAxis...)
    shapes = filter_by_type(ShapedAxis, axs...) .|> size
    shapes = reduce((tup, s) -> (tup..., s...), shapes)
    return reshape(data, shapes)
end

# Recurse through nested ViewAxis types to find the last index
last_index(x) = last(x)
last_index(x::ViewAxis) = last_index(viewindex(x))
last_index(x::AbstractAxis) = last_index(last(indexmap(x)))

# Reduce singleton dimensions
remove_nulls() = ()
remove_nulls(x1, args...) = (x1, remove_nulls(args...)...)
remove_nulls(::NullAxis, args...) = (remove_nulls(args...)...,)


## Attributes
"""
    getdata(x::ComponentArray)

Access ```.data``` field of a ```ComponentArray```, which contains the array that ```ComponentArray``` wraps.
"""
@inline getdata(x::ComponentArray) = getfield(x, :data)
@inline getdata(x) = x
@inline getdata(x::Adjoint) = getdata(x.parent)'
@inline getdata(x::Transpose) = transpose(getdata(x.parent))

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
6×6 ComponentMatrix{Float64} with axes Axis(a = 1:3, b = (4:6, (a = 1, b = 2:3))) × Axis(a = 1:3, b = (4:6, (a = 1, b = 2:3)))
 0.0  0.0  0.0  0.0  0.0  0.0
 0.0  0.0  0.0  0.0  0.0  0.0
 0.0  0.0  0.0  0.0  0.0  0.0
 0.0  0.0  0.0  0.0  0.0  0.0
 0.0  0.0  0.0  0.0  0.0  0.0
 0.0  0.0  0.0  0.0  0.0  0.0

julia> getaxes(ca)
(Axis(a = 1:3, b = (4:6, (a = 1, b = 2:3))), Axis(a = 1:3, b = (4:6, (a = 1, b = 2:3))))
```
"""
@inline getaxes(x::ComponentArray) = getfield(x, :axes)
@inline getaxes(x::AdjOrTrans{T, <:ComponentVector}) where T = (FlatAxis(), getaxes(x.parent)[1])
@inline getaxes(x::AdjOrTrans{T, <:ComponentMatrix}) where T = reverse(getaxes(x.parent))

@inline getaxes(::Type{<:ComponentArray{T,N,A,<:Axes}}) where {T,N,A,Axes} = map(x->x(), (Axes.types...,))
@inline getaxes(::Type{<:AdjOrTrans{T,<:CA}}) where {T,CA<:ComponentVector} = (FlatAxis(), getaxes(CA)[1]) |> typeof
@inline getaxes(::Type{<:AdjOrTrans{T,<:CA}}) where {T,CA<:ComponentMatrix} = reverse(getaxes(CA)) |> typeof


Base.parent(x::ComponentArray) = getfield(x, :data)

Base.size(x::ComponentArray) = size(getdata(x))

Base.elsize(x::Type{<:ComponentArray{T,N,A,Axes}}) where {T,N,A,Axes} = Base.elsize(A)

Base.axes(x::ComponentArray) = axes(getdata(x))

Base.reinterpret(::Type{T}, x::ComponentArray, args...) where T = ComponentArray(reinterpret(T, getdata(x), args...), getaxes(x))

Base.propertynames(x::ComponentVector) = propertynames(indexmap(getaxes(x)[1]))

Base.keys(x::ComponentVector) = keys(indexmap(getaxes(x)[1]))

Base.hash(x::ComponentArray, h::UInt) = hash(getdata(x), h)

"""
    valkeys(x::ComponentVector)

Returns `Val`-wrapped keys of `ComponentVector` for fast iteration over component keys.

# Examples

```julia-repl
julia> using ComponentArrays

julia> ca = ComponentArray(a=1, b=[1,2,3], c=(a=4,))
ComponentVector{Int64}(a = 1, b = [1, 2, 3], c = (a = 4))

julia> [ca[k] for k in valkeys(ca)]
3-element Array{Any,1}:
 1
  [1, 2, 3]
  ComponentVector{Int64,SubArray...}(a = 4)

julia> sum(prod(ca[k]) for k in valkeys(ca))
11
```
"""
@generated function valkeys(ca::ComponentVector)
    idxmap = ComponentArrays.indexmap(getaxes(ca)[1])
    k = Val.(keys(idxmap))
    return :($k)
end

Base.haskey(x::ComponentVector, s::Symbol) = haskey(indexmap(getaxes(x)[1]), s)

function Base.permutedims(x::ComponentArray, dims)
    axs = getaxes(x)
    return ComponentArray(permutedims(getdata(x), dims), map(i->axs[i], dims)...)
end

Base.IndexStyle(::Type{<:ComponentArray{T,N,<:A,<:Axes}}) where {T,N,A,Axes} = IndexStyle(A)


ArrayInterface.parent_type(::Type{ComponentArray{T,N,A,Axes}}) where {T,N,A,Axes} = A
ArrayInterface.size(A::ComponentArray) = ArrayInterface.size(parent(A))
ArrayInterface.strides(A::ComponentArray) = ArrayInterface.strides(parent(A))
for f in [:device, :stride_rank, :contiguous_axis, :contiguous_batch_size, :dense_dims] 
    @eval ArrayInterface.$f(::Type{ComponentArray{T,N,A,Axes}}) where {T,N,A,Axes} = ArrayInterface.$f(A)
end


