const TrackedComponentArray{V, D, N, DA, N, A, Ax} = ReverseDiff.TrackedArray{V,D,N,ComponentArray{V,N,A,Ax},DA}

maybe_tracked_array(val::AbstractArray, der, tape, index, origin) = ReverseDiff.TrackedArray(val, der, tape)
function maybe_tracked_array(val, der, tape, index, origin)
    ax = getaxes(ReverseDiff.value(origin))[1]
    i = ax[index].idx
    return ReverseDiff.TrackedReal(val, der, tape, i, origin)
end

for f in [:getindex, :view]
    # TODO: make this work for multidimensional ComponentArrays
    @eval function Base.$f(tca::TrackedComponentArray, index::Union{Symbol, Val})
            val = $f(ReverseDiff.value(tca), index)
            der = Base.maybeview(ReverseDiff.deriv(tca), index)
            t = ReverseDiff.tape(tca)
        return maybe_tracked_array(val, der, t, index, tca)
    end
end

function Base.getproperty(tca::TrackedComponentArray, s::Symbol)
    if s in (:value, :deriv, :tape)
        return getfield(tca, s)
    else
        val = getproperty(ReverseDiff.value(tca), s)
        der = getproperty(ReverseDiff.deriv(tca), s)
        t = ReverseDiff.tape(tca)
        return maybe_tracked_array(val, der, t, s, tca)
    end
end