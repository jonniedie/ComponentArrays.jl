module ComponentArraysStaticArraysExt

using ComponentArrays
isdefined(Base, :get_extension) ? (using StaticArrays) : (using ..StaticArrays)

ComponentArray{A}(::UndefInitializer, ax::Axes) where {A<:StaticArrays.StaticArray,Axes<:Tuple} =
    ComponentArray(similar(A), ax...)

end
