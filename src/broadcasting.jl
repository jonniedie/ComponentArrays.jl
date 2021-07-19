const BC = Base.Broadcast


struct CAStyle{InnerStyle<:BC.BroadcastStyle, Axes, N} <: BC.AbstractArrayStyle{N} end
CAStyle(::InnerStyle, ::Axes, N) where {InnerStyle, Axes} = CAStyle{InnerStyle, Axes, N}()
CAStyle(::InnerStyle, ::Type{<:Axes}, N) where {InnerStyle, Axes} = CAStyle{InnerStyle, Axes, N}()

function CAStyle(::InnerStyle, ax::Axes, ::Val{N}) where {InnerStyle, Axes, N}
    return CAStyle(InnerStyle(), ax, N)
end


# function Base.BroadcastStyle(::Type{<:ComponentArray{T, N, A, Axes}}) where {T, A, N, Axes}
#     return CAStyle(Base.BroadcastStyle(A), getaxes(Axes), ndims(A))
# end
# function Base.BroadcastStyle(AA::Type{<:Adjoint{T, <:ComponentArray{T, N, A, Axes}}}) where {T, N, A, Axes}
#     return CAStyle(Base.BroadcastStyle(Adjoint{T,A}), getaxes(AA), ndims(AA))
# end
# function Base.BroadcastStyle(AA::Type{<:Transpose{T, <:ComponentArray{T, N, A, Axes}}}) where {T, N, A, Axes}
#     return CAStyle(Base.BroadcastStyle(Transpose{T,A}), getaxes(AA), ndims(AA))
# end

# function Base.BroadcastStyle(::CAStyle{InnerStyle, Axes, N}, bc::BC.Broadcasted) where {InnerStyle, Axes, N}
#     return CAStyle(Base.BroadcastStyle(InnerStyle(), bc), Axes, N)
# end

Base.BroadcastStyle(::Type{<:ComponentArray{T, N, A, Axes}}) where {T, N, A, Axes} = BC.DefaultArrayStyle{N}()
# Base.BroadcastStyle(::Type{<:ComponentArray{T, N, A, Axes}}) where {T, N, A, Axes} = BC.BroadcastStyle(A)

Base.getindex(bc::BC.Broadcasted, inds::ComponentIndex...) = bc[value.(inds)...]

# Need special case here for adjoint vectors in order to avoid type instability in axistype
BC.combine_axes(a::ComponentArray, b::AdjOrTransComponentVector) = (axes(a)[1], axes(b)[2])
BC.combine_axes(a::AdjOrTransComponentVector, b::ComponentArray) = (axes(b)[2], axes(a)[1])

# BC.axistype(a::CombinedAxis, b::AbstractUnitRange) = Base.Broadcast.axistype(_array_axis(a), b)
# BC.axistype(a::AbstractUnitRange, b::CombinedAxis) = Base.Broadcast.axistype(a, _array_axis(b))
# BC.axistype(a::CombinedAxis, b::CombinedAxis) = Base.Broadcast.axistype(_array_axis(a), _array_axis(b))
BC.axistype(a::CombinedAxis, b::AbstractUnitRange) = a
BC.axistype(a::AbstractUnitRange, b::CombinedAxis) = b
BC.axistype(a::CombinedAxis, b::CombinedAxis) = CombinedAxis(FlatAxis(), Base.Broadcast.axistype(_array_axis(a), _array_axis(b)))
BC.axistype(a::T, b::T) where {T<:CombinedAxis} = a

Base.promote_shape(a::Tuple{Vararg{CombinedAxis}}, b::NTuple{N,AbstractUnitRange}) where N = Base.promote_shape(_array_axis.(a), b)
Base.promote_shape(a::NTuple{N,AbstractUnitRange}, b::Tuple{Vararg{CombinedAxis}}) where N = Base.promote_shape(a, _array_axis.(b))
Base.promote_shape(a::Tuple{Vararg{CombinedAxis}}, b::Tuple{Vararg{CombinedAxis}}) = Base.promote_shape(_array_axis.(a), _array_axis.(b))
# Base.promote_shape(a::Tuple{Vararg{Union{AbstractUnitRange, CombinedAxis}}}, b::Tuple{Vararg{Union{AbstractUnitRange, CombinedAxis}}}) = promote_shape(_array_axis.(a), _array_axis.(b))
Base.promote_shape(a::T, b::T) where {T<:Tuple{Vararg{CombinedAxis}}} = a

# # Hack to make things like Dual.(ComponentArray(a=1,b=1), [1,1]) work
# BC.broadcasted(f::Type, arg1::ComponentArray, args...) = ComponentArray(f.(getdata(arg1), getdata.(args)...), getaxes(arg1))
# BC.broadcasted(f::Type, arg1, arg2::ComponentArray, args...) = ComponentArray(f.(arg1, getdata(arg2), getdata.(args)...), getaxes(arg2))

# function BC.BroadcastStyle(::CAStyle{<:In1, <:Ax1, <:N1}, ::CAStyle{<:In2, <:Ax2, <:N2}) where {In1, Ax1, N1, In2, Ax2, N2}
#     ax, N = fill_flat(Ax1, Ax2, N1, N2)
#     inner_style = BC.BroadcastStyle(In1(), In2())
#     if inner_style isa BC.Unknown
#         inner_style = BC.DefaultArrayStyle{N}()
#     end
#     return CAStyle(inner_style, ax, N)
# end
# function BC.BroadcastStyle(::CAStyle{In, Ax, N1}, ::Style) where Style<:BC.DefaultArrayStyle{N2} where {In, Ax, N1, N2}
#     N = max(N1, N2)
#     ax = fill_flat(Ax, max(N1, N2))
#     inner_style = BC.BroadcastStyle(In(), Style())
#     return CAStyle(inner_style, ax, N)
# end
# function BC.BroadcastStyle(CAS::CAStyle{In, Ax, N1}, ::BC.DefaultArrayStyle{0}) where {In, Ax, N1}
#     return CAS
# end
# function BC.BroadcastStyle(CAS::CAStyle{In, Ax, N}, ::BC.DefaultArrayStyle{N}) where {In, Ax, N}
#     return CAS
# end
# function BC.BroadcastStyle(::CAStyle{In, Ax, N1}, ::Style) where Style<:BC.AbstractArrayStyle{N2} where {In, Ax, N1, N2}
#     N = max(N1, N2)
#     ax = fill_flat(Ax, max(N1, N2))
#     inner_style = BC.BroadcastStyle(In(), Style())
#     return CAStyle(inner_style, ax, N)
# end


# Base.convert(::Type{<:BC.Broadcasted{Nothing}}, bc::BC.Broadcasted{<:CAStyle,Axes,F,Args}) where {Axes,F,Args} = getdata(bc)

# getdata(bc::BC.Broadcasted{<:CAStyle}) = BC.broadcasted(bc.f, map(getdata, bc.args)...)


# function Base.similar(bc::BC.Broadcasted{<:CAStyle{InnerStyle, Axes, N}}, args...) where {InnerStyle, Axes, N}
#     return similar(BC.Broadcasted{InnerStyle}(bc.f, bc.args, bc.axes), args...)
# end
# function Base.similar(bc::BC.Broadcasted{<:CAStyle{InnerStyle, Axes, N}}, T::Type) where {InnerStyle, Axes, N}
#     return similar(BC.Broadcasted{InnerStyle}(bc.f, bc.args, bc.axes), T)
# end
# function Base.similar(bc::BC.Broadcasted{<:CAStyle{<:BC.Unknown, Axes, N}}, T::Type) where {InnerStyle, Axes, N}
#     return similar(BC.Broadcasted{BC.DefaultArrayStyle{N}}(bc.f, bc.args, bc.axes), T)
# end


# BC.broadcasted(f, x::ComponentArray) = ComponentArray(map(f, getdata(x)), getaxes(x))

# Need a special case here because `map` doesn't follow same rules as normal broadcasting. To be safe and avoid ambiguities,
# we'll just handle the case where everything is a ComponentArray. Else it falls back to a plain Array output.
function Base.map(f, xs::ComponentArray{<:Any, <:Any, <:Any, Axes}...) where Axes
    return ComponentArray(map(f, getdata.(xs)...), getaxes(Axes))
end


# function Base.copy(bc::BC.Broadcasted{<:CAStyle{InnerStyle, Axes, N}}) where {InnerStyle, Axes,  N}
#     return ComponentArray{Axes}(Base.copy(BC.broadcasted(bc.f, map(getdata, bc.args)...)))
# end
# function Base.copy(bc::BC.Broadcasted{<:CAStyle{InnerStyle, Axes, N}}) where {InnerStyle, Axes,  N}
#     return ComponentArray{Axes}(Base.copy(BC.Broadcasted(InnerStyle())))
# end

# From https://github.com/JuliaArrays/OffsetArrays.jl/blob/master/src/OffsetArrays.jl
Base.dataids(A::ComponentArray) = Base.dataids(parent(A))
Broadcast.broadcast_unalias(dest::ComponentArray, src) = getdata(dest) === getdata(src) ? src : Broadcast.unalias(dest, src)



# Helper for extruding axes
function fill_flat(Ax1, Ax2, N1, N2)
    if N1<N2
        N = N2
        ax1 = fill_flat(Ax1,N)
        ax2 = Ax2
    elseif N1>N2
        N = N1
        ax1 = Ax1
        ax2 = fill_flat(Ax2,N)
    else
        N = N1
        ax1, ax2 = Ax1, Ax2
    end
    # Ax = Base.promote_typeof(getaxes(ax1), getaxes(ax2))
    Ax = broadcast_promote_typeof(getaxes(ax1), getaxes(ax2))
    return Ax, N
end
fill_flat(Ax::Type{<:VarAxes}, N) = fill_flat(getaxes(Ax), N) |> typeof
function fill_flat(Ax::VarAxes, N)
    axs = Ax
    n = length(axs)
    if N>n
        axs = (axs..., ntuple(x -> FlatAxis(), N-n)...)
    end
    return axs
end
