"""
    x = ComponentArray(nt::NamedTuple)
    x = ComponentArray{T}(nt::NamedTuple) where {T}

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
ComponentArray(data, ::FlatAxis...) = data
ComponentArray(data, ax::NotShapedOrPartitionedAxis...) = ComponentArray(data, ax)
ComponentArray(data, ax::NotPartitionedAxis...) = ComponentArray(maybe_reshape(data, ax...), unshape.(ax)...)
function ComponentArray(data, ax::AbstractAxis...)
    part_axs = filter_by_type(PartitionedAxis, ax...)
    part_data = partition(data, numaxes.(part_axs)...)
    return [ComponentArray(x, Axis.(ax)) for x in part_data]
end

ComponentArray{Axes}(data) where Axes = ComponentArray(data, getaxes(Axes)...)

ComponentArray{T}(nt::NamedTuple) where T = ComponentArray(make_carray_args(nt, T)...)
ComponentArray(nt::NamedTuple) = ComponentArray(make_carray_args(nt)...)
ComponentArray{T}(;kwargs...) where T = ComponentArray{T}((;kwargs...))
ComponentArray(;kwargs...) = ComponentArray((;kwargs...))

const ComponentVector{T,A,Axes} = ComponentArray{T,1,A,Axes}
const ComponentMatrix{T,A,Axes} = ComponentArray{T,2,A,Axes}

const CArray = ComponentArray
const CVector = ComponentVector
const CMatrix = ComponentMatrix


## Constructor helpers
maybe_reshape(data, axs::NotShapedAxis...) = data
function maybe_reshape(data, axs::AbstractAxis...)
    shapes = filter_by_type(ShapedAxis, axs...) .|> size
    shapes = reduce((tup, s) -> (tup..., s...), shapes)
    return reshape(data, shapes)
end

function make_carray_args(nt, T=Float64)
    data, idx = make_idx(T[], nt, 0)
    return (data, Axis(idx))
end

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
make_idx(data, x::ComponentVector, last_val) = (
    push!(data, x...),
    ViewAxis(
        last_index(last_val) .+ (1:length(x)),
        getaxes(x)[1]
    )
)


last_index(x) = last(x)
last_index(x::ViewAxis) = last_index(viewindex(x))


## Base attributes
Base.parent(x::ComponentArray) = getfield(x, :data)

Base.size(x::ComponentArray) = size(getdata(x))

Base.reinterpret(::Type{T}, x::ComponentArray, args...) where T = ComponentArray(reinterpret(T, getdata(x), args...), getaxes(x))

Base.propertynames(x::CVector{Axes,T,A}) where {Axes,T,A} = propertynames(getaxes(x)[1])

Base.keys(x::CVector) = keys(indexmap(getaxes(x)[1]))