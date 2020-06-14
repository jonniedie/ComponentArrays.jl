function Base.similar(::BC.Broadcasted{<:CAStyle{T,N,<:A,<:Axes}}) where {T,N,A<:StaticArrays.StaticArray,Axes}
    ComponentArray{Axes}(similar(A))
end

ComponentArray{A}(::UndefInitializer, ax::Axes) where {A<:StaticArrays.StaticArray,Axes<:Tuple} =
    ComponentArray(similar(A), ax...)

function Base.similar(bc::BC.Broadcasted{<:CAStyle{T,N,<:A,<:Axes}}, ::Type{<:TT}) where {T,N,A<:StaticArrays.StaticArray,Axes,TT}
    return ComponentArray{Axes}(similar(A, TT))
end