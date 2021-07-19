const BC = Base.Broadcast

Base.BroadcastStyle(::Type{<:ComponentArray{T, N, A, Axes}}) where {T, N, A, Axes} = BC.BroadcastStyle(A)

Base.getindex(bc::BC.Broadcasted, inds::ComponentIndex...) = bc[value.(inds)...]

# Need special case here for adjoint vectors in order to avoid type instability in axistype
BC.combine_axes(a::ComponentArray, b::AdjOrTransComponentVector) = (axes(a)[1], axes(b)[2])
BC.combine_axes(a::AdjOrTransComponentVector, b::ComponentArray) = (axes(b)[2], axes(a)[1])

BC.axistype(a::CombinedAxis, b::AbstractUnitRange) = a
BC.axistype(a::AbstractUnitRange, b::CombinedAxis) = b
BC.axistype(a::CombinedAxis, b::CombinedAxis) = CombinedAxis(FlatAxis(), Base.Broadcast.axistype(_array_axis(a), _array_axis(b)))
BC.axistype(a::T, b::T) where {T<:CombinedAxis} = a

Base.promote_shape(a::Tuple{Vararg{CombinedAxis}}, b::NTuple{N,AbstractUnitRange}) where N = Base.promote_shape(_array_axis.(a), b)
Base.promote_shape(a::NTuple{N,AbstractUnitRange}, b::Tuple{Vararg{CombinedAxis}}) where N = Base.promote_shape(a, _array_axis.(b))
Base.promote_shape(a::Tuple{Vararg{CombinedAxis}}, b::Tuple{Vararg{CombinedAxis}}) = Base.promote_shape(_array_axis.(a), _array_axis.(b))
Base.promote_shape(a::T, b::T) where {T<:Tuple{Vararg{CombinedAxis}}} = a

# From https://github.com/JuliaArrays/OffsetArrays.jl/blob/master/src/OffsetArrays.jl
Base.dataids(A::ComponentArray) = Base.dataids(parent(A))
Broadcast.broadcast_unalias(dest::ComponentArray, src) = getdata(dest) === getdata(src) ? src : Broadcast.unalias(dest, src)
