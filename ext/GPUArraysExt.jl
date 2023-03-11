module GPUArraysExt

using ComponentArrays
isdefined(Base, :get_extension) ? (using GPUArrays) : (using ..GPUArrays)

const GPUComponentArray = ComponentArray{T,N,<:GPUArrays.AbstractGPUArray,Ax} where {T,N,Ax<:Tuple{Vararg{AbstractAxis}}}

GPUArrays.backend(x::ComponentArray) = GPUArrays.backend(getdata(x))

function GPUArrays.Adapt.adapt_structure(to, x::ComponentArray)
    data = GPUArrays.Adapt.adapt_structure(to, getdata(x))
    return ComponentArray(data, getaxes(x))
end

function Base.map(f, x::GPUComponentArray, args...)
    data = map(f, getdata(x), getdata.(args)...)
    return ComponentArray(data, getaxes(x))
end
function Base.map(f, x::GPUComponentArray, args::Vararg{Union{Base.AbstractBroadcasted, AbstractArray}})
    data = map(f, getdata(x), map(getdata, args)...)
    return ComponentArray(data, getaxes(x))
end

# We need all of these to avoid method ambiguities
function Base.mapreduce(f, op, x::GPUComponentArray; kwargs...)
    return mapreduce(f, op, getdata(x); kwargs...)
end
function Base.mapreduce(f, op, x::GPUComponentArray, args...; kwargs...)
    return mapreduce(f, op, getdata(x), map(getdata, args)...; kwargs...)
end
function Base.mapreduce(f, op, x::GPUComponentArray, args::Vararg{Union{Base.AbstractBroadcasted, AbstractArray}}; kwargs...)
    return mapreduce(f, op, getdata(x), map(getdata, args)...; kwargs...)
end

# These are all stolen from GPUArrays.j;
Base.any(A::GPUComponentArray{Bool}) = mapreduce(identity, |, getdata(A))
Base.all(A::GPUComponentArray{Bool}) = mapreduce(identity, &, getdata(A))

Base.any(f::Function, A::GPUComponentArray) = mapreduce(f, |, getdata(A))
Base.all(f::Function, A::GPUComponentArray) = mapreduce(f, &, getdata(A))

Base.count(pred::Function, A::GPUComponentArray; dims=:, init=0) =
    mapreduce(pred, Base.add_sum, getdata(A); init=init, dims=dims)

# avoid calling into `initarray!`
for (fname, op) in [(:sum, :(Base.add_sum)), (:prod, :(Base.mul_prod)),
                    (:maximum, :(Base.max)), (:minimum, :(Base.min)),
                    (:all, :&),              (:any, :|)]
    fname! = Symbol(fname, '!')
    @eval begin
        Base.$(fname!)(f::Function, r::GPUComponentArray, A::GPUComponentArray{T}) where T =
            GPUArrays.mapreducedim!(f, $(op), getdata(r), getdata(A); init=neutral_element($(op), T))
    end
end

end
