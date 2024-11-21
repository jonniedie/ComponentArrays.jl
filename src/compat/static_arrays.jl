function ComponentArray{A}(::UndefInitializer, ax::Axes) where {A<:StaticArray, Axes<:Tuple}
    return ComponentArray(similar(A), ax...)
end

_maybe_SArray(x::SubArray, ::Val{N}, ::FlatAxis) where {N} = SVector{N}(x)
_maybe_SArray(x::Base.ReshapedArray, ::Val, ::ShapedAxis{Sz}) where {Sz} = SArray{Tuple{Sz...}}(x)
_maybe_SArray(x, ::Val, ::Shaped1DAxis{Sz}) where {Sz} = SArray{Tuple{Sz...}}(x)
_maybe_SArray(x, vals...) = x

@generated function static_getproperty(ca::ComponentVector, ::Val{s}) where {s}
    comp_ind = getaxes(ca)[1][s]
    return :(_maybe_SArray(ca.$s, $(Val(length(comp_ind.idx))), $(comp_ind.ax)))
end

macro static_unpack(expr)
    @assert expr.head == :(=) "Unpack expression must have an equals sign for assignment"
    lhs, rhs = expr.args
    unpacked_var_names = if lhs isa Symbol
        [lhs]
    elseif lhs.head == :tuple
        if lhs.args[1] isa Expr
            lhs.args[1].args
        else
            lhs.args
        end
    else
        error("Malformed left side of assignment expression: $(lhs)")
    end
    parent_var_name = esc(rhs)
    out = Expr(:block)
    for name in unpacked_var_names
        esc_name = esc(name)
        push!(out.args, :($esc_name = static_getproperty($parent_var_name, $(Val(name)))))
    end
    return out
end
