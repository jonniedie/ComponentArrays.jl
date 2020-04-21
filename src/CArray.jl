"""
    x = CArray(nt::NamedTuple)
    x = CArray{T}(nt::NamedTuple) where {T}

Array type that can be accessed like an arbitrary nested mutable struct.

# Examples

```julia-repl
julia> c = (a=2, b=[1, 2]);

julia> x = CArray(a=1, b=[2, 1, 4], c=c)
CArray(a = 1.0, b = [2.0, 1.0, 4.0], c = (a = 2.0, b = [1.0, 2.0]))

julia> x.c.a = 400; x
CArray(a = 1.0, b = [2.0, 1.0, 4.0], c = (a = 400.0, b = [1.0, 2.0]))

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
struct CArray{Axes,T,N,A<:AbstractArray{T,N}} <: AbstractArray{T,N}
    data::A
    axes::Axes
    CArray(data::A, ax::Axes) where {A<:AbstractArray{T,N},Axes<:Tuple} where {T,N} = new{Axes,T,N,A}(data, ax)
end
CArray(data::AbstractArray, ::Tuple{}) = data
CArray(data::AbstractArray, ax::Axis...) = CArray(data, remove_nulls(ax...))
CArray(data::AbstractArray, ax::NullorFlatAxis...) = data
CArray{Axes}(data) where Axes = CArray(data, map(Axis, (Axes.types...,))...)
CArray(data::Number, ax::Axis...) = data
# CArray(data::AbstractArray, ax::Tuple{Vararg{Axis{L,NamedTuple()}}}) where L = data
# CArray(tup::Tuple) = CArray(tup...)
CArray{T}(nt::NamedTuple) where T = CArray(make_CArray_args(nt, T)...)
CArray(nt::NamedTuple) = CArray(make_CArray_args(nt)...)
CArray{T}(;kwargs...) where T = CArray{T}((;kwargs...))
CArray(;kwargs...) = CArray((;kwargs...))

const CVector{Axes,T,A} = CArray{Axes,T,1,A}
const CMatrix{Axes,T,A} = CArray{Axes,T,2,A}


## Constructor helpers
function make_CArray_args(nt, T=Float64)
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
        return (data, (last_index(last_val) .+ (1:len), length(x), out[2]))
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

Base.parent(x::CArray) = getfield(x, :data)

Base.size(x::CArray) = size(getdata(x))