module ComponentArraysAdaptExt

using ComponentArrays, Adapt

function Adapt.adapt_structure(to, x::ComponentArray)
    data = adapt(to, getdata(x))
    return ComponentArray(data, getaxes(x))
end

Adapt.adapt_storage(::Type{ComponentArray{T,N,A,Ax}}, xs::AT) where {T,N,A,Ax,AT<:AbstractArray} =
    Adapt.adapt_storage(A, xs)

end
