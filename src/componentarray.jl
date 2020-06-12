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
ComponentArray{Float64}(a = 1.0, b = [2.0, 1.0, 4.0], c = (a = 2.0, b = [1.0, 2.0]))

julia> x.c.a = 400; x
ComponentArray{Float64}(a = 1.0, b = [2.0, 1.0, 4.0], c = (a = 400.0, b = [1.0, 2.0]))

julia> x[5]
400.0

julia> collect(x)
7-element Array{Float64,1}:
   1.0
   2.0
   1.0
   4.0
 400.0
   1.0
   2.0
```
"""
struct ComponentArray{T,N,A<:AbstractArray{T,N},Axes} <: AbstractArray{T,N}
    data::A
    axes::Axes
    ComponentArray(data, ::Axes) where Axes<:Tuple = data
    ComponentArray(data::A, ax::Axes) where {A<:AbstractArray{T,N},Axes<:Tuple} where {T,N} =
        new{T,N,A,Axes}(data, ax)
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
    return [ComponentArray(x, Axis.(ax)) for x in part_data]
end

# Entry from NamedTuple or kwargs
ComponentArray{T}(nt::NamedTuple) where T = ComponentArray(make_carray_args(T, nt)...)
ComponentArray(nt::NamedTuple) = ComponentArray(make_carray_args(nt)...)
ComponentArray{T}(;kwargs...) where T = ComponentArray{T}((;kwargs...))
ComponentArray(;kwargs...) = ComponentArray((;kwargs...))


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

"""
    x = ComponentMatrix(data::AbstractMatrix, ax...)
    x = ComponentMatrix{T}(data::AbstractMatrix, ax...) where T

A `ComponentMatrix` is an alias for a two-dimensional `ComponentArray`.
"""
const ComponentMatrix{T,A,Axes} = ComponentArray{T,2,A,Axes}
ComponentMatrix{T}(::UndefInitializer, ax...) where {T} = ComponentArray{T}(undef, ax...)
ComponentMatrix(data::AbstractMatrix, ax...) = ComponentArray(data, ax...)
ComponentMatrix(data::AbstractArray, ax...) = throw(DimensionMismatch("A `ComponentMatrix` must be initialized with a 2-dimensional array. This array is $(ndims(data))-dimensional."))

const CArray = ComponentArray
const CVector = ComponentVector
const CMatrix = ComponentMatrix

const AdjointVector{T,A} = Union{Adjoint{T,A}, Transpose{T,A}} where A<:AbstractVector{T}
const AdjointCVector{T,A,Axes} = ComponentMatrix{T,A,Axes} where A<:AdjointVector


## Constructor helpers
# For making ComponentArrays from named tuples
make_carray_args(nt) = make_carray_args(Float64, nt)
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
make_idx(data, x, last_val) = (
    push!(data, x),
    ViewAxis(last_index(last_val) + 1)
)
make_idx(data, x::ComponentVector, last_val) = (
    push!(data, x...),
    ViewAxis(
        last_index(last_val) .+ (1:length(x)),
        getaxes(x)[1]
    )
)
function make_idx(data, x::AbstractArray{N}, last_val) where N<:Number
    push!(data, x...)
    out = last_index(last_val) .+ (1:length(x))
    return (data, ViewAxis(out, ShapedAxis(size(x))))
end
function make_idx(data, x::A, last_val) where A<:AbstractArray
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
        error("Only homogeneous arrays are allowed. This one has eltype $(eltype(x)).")
    end
end

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


## Base attributes
Base.parent(x::ComponentArray) = getfield(x, :data)

Base.size(x::ComponentArray) = size(getdata(x))

Base.reinterpret(::Type{T}, x::ComponentArray, args...) where T = ComponentArray(reinterpret(T, getdata(x), args...), getaxes(x))

Base.propertynames(x::ComponentVector{Axes,T,A}) where {Axes,T,A} = propertynames(getaxes(x)[1])

Base.keys(x::ComponentVector) = keys(indexmap(getaxes(x)[1]))

Base.IndexStyle(::ComponentVector) = IndexLinear()