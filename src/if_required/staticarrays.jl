function Base.similar(::BC.Broadcasted{<:CAStyle{T,N,A,Axes}}) where {T,N,A<:StaticArrays.StaticArray,Axes}
    ComponentArray{Axes}(similar(A))
end

ComponentArray{A}(::UndefInitializer, ax::Axes) where {A<:StaticArrays.StaticArray,Axes<:Tuple} =
    ComponentArray(similar(A), ax...)