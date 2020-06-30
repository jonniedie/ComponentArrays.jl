ComponentArray{A}(::UndefInitializer, ax::Axes) where {A<:StaticArrays.StaticArray,Axes<:Tuple} =
    ComponentArray(similar(A), ax...)

# Sometimes you just need to get things done.
function Base.Broadcast.BroadcastStyle(::Type{s66}) where s66<:Transpose{T,s19} where s19<:ComponentArray{s62,s63,s64,s65} where s65<:Tuple{Vararg{AbstractAxis,N}} where s64<:StaticArrays.StaticArray{S,s62,N} where S<:Tuple where s63<:N where s62<:T where {T, N}
    return CAStyle(StaticArrays.StaticArrayStyle{2}(), getaxes(s19), 2)
end
function Base.Broadcast.BroadcastStyle(::Type{s66}) where s66<:Adjoint{T,s19} where s19<:ComponentArray{s62,s63,s64,s65} where s65<:Tuple{Vararg{AbstractAxis,N}} where s64<:StaticArrays.StaticArray{S,s62,N} where S<:Tuple where s63<:N where s62<:T where {T, N}
    return CAStyle(StaticArrays.StaticArrayStyle{2}(), getaxes(s19), 2)
end

# This is pretty unideal. It gets the answer right, but it allocates in the process. Need to
# figure this out because what's the point of StaticArrays if they are going to allocate?
function Base.copy(bc::Base.Broadcast.Broadcasted{Style,<:Ax,<:F,s19}) where {s19<:Tuple, Axes, Ax, F, Style<:CAStyle{s18,<:s17,<:s12}} where {s12, s17, s18<:StaticArrays.StaticArrayStyle}
    args = map(getdata, bc.args)
    # # style = BC.combine_styles(BC.BroadcastStyle.(typeof.(args))...)
    return ComponentArray{s17}(Base.copy(BC.broadcasted(bc.f, args...)))
end


