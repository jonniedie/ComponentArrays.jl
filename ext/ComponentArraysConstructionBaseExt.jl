module ComponentArraysConstructionBaseExt

using ComponentArrays, ConstructionBase

ConstructionBase.setproperties(x::ComponentVector, patch::NamedTuple) = ComponentVector(x; patch...)

end
