
# Plot labels
plot_labels(x) = map(x->x[firstindex(x)+1:end], _plot_labels(x))
function _plot_labels(x::ComponentVector)
    vcat((".$(key)" .* _plot_labels(x[key]) for key in keys(x))...)
end
_plot_labels(x::AbstractArray{<:ComponentArray}) = vcat(("[$i]" .* _plot_labels(x[i]) for i in eachindex(x))...)
_plot_labels(x::AbstractArray) = vcat(("[" * join(i.I, ",") * "]" for i in CartesianIndices(x))...)
_plot_labels(x) = ""

# _label2index(x::ComponentVector, str::AbstractString) = reduce((x1, s) -> x1[Symbol(s)], split(str, "."), init=x)
_label2index(x::ComponentVector, str::AbstractString) = findall(startswith.(plot_labels(x), str))