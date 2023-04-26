module ComponentArraysConstructionBaseExt

using ComponentArrays
isdefined(Base, :get_extension) ? (using ConstructionBase) : (using ..ConstructionBase)

ConstructionBase.setproperties(x::ComponentVector, patch::NamedTuple) = ComponentVector(x; patch...)

end
