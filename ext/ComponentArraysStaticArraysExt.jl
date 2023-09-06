module ComponentArraysStaticArraysExt

using ComponentArrays, StaticArrays

ComponentArray{A}(::UndefInitializer, ax::Axes) where {A<:StaticArrays.StaticArray,Axes<:Tuple} =
    ComponentArray(similar(A), ax...)

end
