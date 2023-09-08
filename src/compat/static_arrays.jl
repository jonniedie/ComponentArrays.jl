function ComponentArray{A}(::UndefInitializer, ax::Axes) where {A<:StaticArray, Axes<:Tuple}
    return ComponentArray(similar(A), ax...)
end

maybe_SArray(x::SubArray, ::Val{N}, ::FlatAxis) where {N} = SVector{N}(x)
maybe_SArray(x::Base.ReshapedArray, ::Val, ::ShapedAxis{Sz}) where {Sz} = SArray{Tuple{Sz...}}(x)
maybe_SArray(x, vals...) = x

@generated function static_getproperty(ca::ComponentVector, ::Val{s}) where {s}
    (; idx, ax) = getaxes(ca)[1][s]
    return :(maybe_SArray(ca.$s, $(Val(length(idx))), $ax))
end

macro static_unpack(expr)
    unpacked_var_names = if expr.args[1].head == :tuple
        expr.args[1].args
    end
    parent_var_name = esc(expr.args[end])
    out = Expr(:block)
    for name in unpacked_var_names
        esc_name = esc(name)
        push!(out.args, :($esc_name = static_getproperty($parent_var_name, $(Val(name)))))
    end
    return out
end