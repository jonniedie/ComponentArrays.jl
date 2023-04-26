module ComponentArraysReverseDiffExt

using ComponentArrays
isdefined(Base, :get_extension) ? (using ReverseDiff) : (using ..ReverseDiff)

const TrackedComponentArray{V, D, N, DA, A, Ax} = ReverseDiff.TrackedArray{V,D,N,ComponentArray{V,N,A,Ax},DA}

maybe_tracked_array(val::AbstractArray, der, tape, inds, origin) = ReverseDiff.TrackedArray(val, der, tape)
function maybe_tracked_array(val::Real, der, tape, inds, origin::AbstractVector)
    ax = getaxes(ReverseDiff.value(origin))[1]
    i = ax[inds[1]].idx
    return ReverseDiff.TrackedReal(val, der, tape, i, origin)
end

for f in [:getindex, :view]
    @eval function Base.$f(tca::TrackedComponentArray, inds::Union{Symbol, Val}...)
            val = $f(ReverseDiff.value(tca), inds...)
            der = Base.maybeview(ReverseDiff.deriv(tca), inds...)
            t = ReverseDiff.tape(tca)
        return maybe_tracked_array(val, der, t, inds, tca)
    end
end

function Base.getproperty(tca::TrackedComponentArray, s::Symbol)
    if s in (:value, :deriv, :tape)
        return getfield(tca, s)
    else
        val = getproperty(ReverseDiff.value(tca), s)
        der = getproperty(ReverseDiff.deriv(tca), s)
        t = ReverseDiff.tape(tca)
        return maybe_tracked_array(val, der, t, (s,), tca)
    end
end

end
