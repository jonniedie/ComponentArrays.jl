Base.BroadcastStyle(::Type{<:ComponentArray{T, N, A, Axes}}) where {T, N, A, Axes} = Broadcast.BroadcastStyle(A)

Broadcast.axistype(a::CombinedAxis, b::AbstractUnitRange) = a
Broadcast.axistype(a::AbstractUnitRange, b::CombinedAxis) = b
Broadcast.axistype(a::CombinedAxis, b::CombinedAxis) = CombinedAxis(FlatAxis(), Base.Broadcast.axistype(_array_axis(a), _array_axis(b)))
Broadcast.axistype(a::T, b::T) where {T<:CombinedAxis} = a

Base.promote_shape(a::NTuple{M,CombinedAxis}, b::NTuple{N,AbstractUnitRange}) where {M,N} = Base.promote_shape(_array_axis.(a), b)
Base.promote_shape(a::NTuple{N,AbstractUnitRange}, b::NTuple{M,CombinedAxis}) where {M,N} = Base.promote_shape(a, _array_axis.(b))
Base.promote_shape(a::NTuple{M,CombinedAxis}, b::NTuple{N,CombinedAxis}) where {M,N} = Base.promote_shape(_array_axis.(a), _array_axis.(b))
Base.promote_shape(a::T, b::T) where {T<:NTuple{N,CombinedAxis} where N} = a

# From https://github.com/JuliaArrays/OffsetArrays.jl/blob/master/src/OffsetArrays.jl
Base.dataids(A::ComponentArray) = Base.dataids(parent(A))
Broadcast.broadcast_unalias(dest::ComponentArray, src) = getdata(dest) === getdata(src) ? src : Broadcast.unalias(dest, src)
