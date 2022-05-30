Base.getindex(cv::ComponentVector, ax::AbstractAxis) = _get_index_axis(cv,ax)
Base.getindex(cv::ComponentVector, cv_template::ComponentVector) = _get_index_axis(
    cv,first(getaxes(cv_template)))

# since ComponentVector is a DenseArray, need to copy values 
function _get_index_axis(cv::ComponentVector, ax::AbstractAxis)
    first(getaxes(cv)) == ax && return(copy(cv)) # no need to reassamble
    # extract subvectors and reassamble
    keys_ax = keys(ax)
    tmp = map(keys_ax) do k
        cvs = getproperty(cv, k)
        axs = ax[k].ax
        #@show cvs, axs
        _get_index_axis(cvs, axs)
    end
    ComponentVector(NamedTuple{keys_ax}(tmp)) # creating from named tuple copies data
end
_get_index_axis(x, ax::NullAxis) = x
# in order to extract entire component, do not specify subaxes
# e.g. (a=1) to match entire (a=(a1=1, a2=2))
_get_index_axis(cv::ComponentVector, ax::NullAxis) = cv # else method ambiguous

