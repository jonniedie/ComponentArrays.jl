AVOA = RecursiveArrayTools.AbstractVectorOfArray

Base.Array(VA::AVOA{T,N,A}) where {T,N,A<:AbstractVector{<:ComponentVector}} = hcat(VA.u...)