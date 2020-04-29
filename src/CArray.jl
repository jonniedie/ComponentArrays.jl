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
struct ComponentArray{Axes,T,N,A<:AbstractArray{T,N}} <: AbstractArray{T,N}
    data::A
    axes::Axes
    ComponentArray(data::A, ax::Axes) where {A<:AbstractArray{T,N},Axes<:Tuple} where {T,N} = new{Axes,T,N,A}(data, ax)
end
ComponentArray(data::AbstractArray, ::Tuple{}) = data
ComponentArray(data::AbstractArray, ax::Axis...) = ComponentArray(data, remove_nulls(ax...))
ComponentArray(data::AbstractArray, ax::NullorFlatAxis...) = data
ComponentArray(data::AbstractArray, ax::NAxis{N,IdxMap}) where {N,IdxMap} = ComponentArray.(partition(data, N), [Axis{IdxMap}()])
function ComponentArray(data::AbstractArray, ax::AxisorNAxis...)
    naxs = Iterators.filter(x -> x isa NAxis, ax)
    part_data = partition(data, numaxes.(naxs)...)
    return [ComponentArray(x, Axis.(ax)...) for x in part_data]
end
ComponentArray{Axes}(data) where Axes = ComponentArray(data, map(Axis, (Axes.types...,))...)
ComponentArray(data::Number, ax::Axis...) = data
ComponentArray{T}(nt::NamedTuple) where T = ComponentArray(make_carray_args(nt, T)...)
ComponentArray(nt::NamedTuple) = ComponentArray(make_carray_args(nt)...)
ComponentArray{T}(;kwargs...) where T = ComponentArray{T}((;kwargs...))
ComponentArray(;kwargs...) = ComponentArray((;kwargs...))

const CArray = ComponentArray
const CVector{Axes,T,A} = ComponentArray{Axes,T,1,A}
const CMatrix{Axes,T,A} = ComponentArray{Axes,T,2,A}


## Constructor helpers
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
    return (data, (last_index(last_val) .+ (1:len), (;kvs...)))
end
make_idx(data, x, last_val) = (push!(data, x), last_index(last_val) + 1)
function make_idx(data, x::AbstractArray{N}, last_val) where N<:Number
    push!(data, x...)
    out = last_index(last_val) .+ (1:length(x))
    return (data, out)
end
function make_idx(data, x::A, last_val) where A<:AbstractArray
    len = recursive_length(x)
    if eltype(x) |> isconcretetype
        out = ()
        for elem in x
            (_,out) = make_idx(data, elem, last_val)
        end
        return (data, (last_index(last_val) .+ (1:len), len ÷ length(x), out[2]))
    else
        error("Only homogeneous arrays are allowed. This one has eltype $(eltype(x)).")
    end
end
make_idx(data, x::CVector, last_val) =
    (push!(data, x...), (last_index(last_val) .+ (1:length(x)), idxmap(getaxes(x)[1])))


recursive_length(x) = length(x)
recursive_length(a::AbstractVector{N}) where N<:Number = length(a)
recursive_length(a::AbstractVector) = recursive_length.(a) |> sum
recursive_length(nt::NamedTuple) = values(nt) .|> recursive_length |> sum

last_index(x) = last(x)
last_index(x::Tuple) = last_index(x[1])


## Base attributes
Base.propertynames(x::CVector{Axes,T,A}) where {Axes,T,A} = propertynames(getaxes(x)[1])

Base.parent(x::ComponentArray) = getfield(x, :data)

Base.size(x::ComponentArray) = size(getdata(x))