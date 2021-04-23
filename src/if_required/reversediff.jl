const TrackedComponentArray{V, D, N, DA, N, A, Ax} = ReverseDiff.TrackedArray{V,D,N,ComponentArray{V,N,A,Ax},DA}

maybe_tracked_array(val::AbstractArray, der, t) = ReverseDiff.TrackedArray(val, der, t)
maybe_tracked_array(val, der, t) = ReverseDiff.TrackedReal(val, der, t)

function Base.getindex(tca::TrackedComponentArray, inds::Union{Symbol, Val}...)
        val = ReverseDiff.value(tca)[inds...]
        der = ReverseDiff.deriv(tca)[inds...]
        t = ReverseDiff.tape(tca)
    return maybe_tracked_array(val, der, t)
end

function Base.getproperty(tca::TrackedComponentArray, s::Symbol)
    if s in (:value, :deriv, :tape)
        return getfield(tca, s)
    else
        val = getproperty(ReverseDiff.value(tca), s)
        der = getproperty(ReverseDiff.deriv(tca), s)
        t = ReverseDiff.tape(tca)
        return maybe_tracked_array(val, der, t)
    end
end