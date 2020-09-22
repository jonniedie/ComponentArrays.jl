AVOA = RecursiveArrayTools.AbstractVectorOfArray

function Base.Array(VA::AVOA{T,N,A}) where {T,N,A<:AbstractVector{<:ComponentVector}}
    return ComponentArray(reduce(hcat, VA.u), FlatAxis(), getaxes(VA.u[1])[1])
end