struct ComponentIndex{Idx, Ax<:AbstractAxis}
    idx::Idx
    ax::Ax
end
ComponentIndex(idx::Int) = ComponentIndex(idx, NullAxis())
ComponentIndex(idx::Union{FlatIdx, Colon}) = ComponentIndex(idx, FlatAxis())
ComponentIndex(vax::ViewAxis{Inds,IdxMap,Ax}) where {Inds,IdxMap,Ax} = ComponentIndex(Inds, vax.ax)

const FlatComponentIndex{Idx} = ComponentIndex{Idx, FlatAxis}
const NullComponentIndex{Idx} = ComponentIndex{Idx, NullAxis}
