const BC = Base.Broadcast


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
    Ax = map(ax-> ax[1], promote.(getaxes(ax1), getaxes(ax2))) |> typeof
    return Ax, N
end
fill_flat(Ax::Type{<:VarAxes}, N) = fill_flat(getaxes(Ax), N) |> typeof
function fill_flat(Ax::VarAxes, N)
    axs = getaxes(Ax)
    n = length(axs)
    if N>n
        axs = (axs..., ntuple(x -> FlatAxis(), N-n)...)
    end
    return axs
end


struct CAStyle{InnerStyle<:BC.BroadcastStyle, Axes, N} <: BC.AbstractArrayStyle{N} end
CAStyle(::InnerStyle, ::Axes, N) where {InnerStyle, Axes} = CAStyle{InnerStyle, Axes, N}()
CAStyle(::InnerStyle, ::Type{<:Axes}, N) where {InnerStyle, Axes} = CAStyle{InnerStyle, Axes, N}()

function CAStyle(::InnerStyle, ax::Axes, ::Val{N}) where {InnerStyle, Axes, N}
    return CAStyle(InnerStyle(N), ax, N)
end


function BC.BroadcastStyle(::CAStyle{<:In1, <:Ax1, <:N1}, ::CAStyle{<:In2, <:Ax2, <:N2}) where {In1, Ax1, N1, In2, Ax2, N2}
    ax, N = fill_flat(Ax1, Ax2, N1, N2)
    inner_style = BC.BroadcastStyle(In1(), In2())
    if inner_style isa BC.Unknown
        inner_style = BC.DefaultArrayStyle{N}()
    end
    return CAStyle(inner_style, ax, N)
end
function BC.BroadcastStyle(::CAStyle{In, Ax, N1}, ::Style) where Style<:BC.DefaultArrayStyle{N2} where {In, Ax, N1, N2}
    N = max(N1, N2)
    ax = fill_flat(Ax, max(N1, N2))
    inner_style = BC.BroadcastStyle(In(), Style())
    return CAStyle(inner_style, ax, N)
end
function BC.BroadcastStyle(CAS::CAStyle{In, Ax, N1}, ::BC.DefaultArrayStyle{0}) where {In, Ax, N1}
    return CAS
end
function BC.BroadcastStyle(CAS::CAStyle{In, Ax, N}, ::BC.DefaultArrayStyle{N}) where {In, Ax, N}
    return CAS
end
function BC.BroadcastStyle(::CAStyle{In, Ax, N1}, ::Style) where Style<:BC.AbstractArrayStyle{N2} where {In, Ax, N1, N2}
    N = max(N1, N2)
    ax = fill_flat(Ax, max(N1, N2))
    inner_style = BC.BroadcastStyle(In(), Style())
    return CAStyle(inner_style, ax, N)
end


function Base.BroadcastStyle(::Type{<:ComponentArray{T, N, A, Axes}}) where {T, A, N, Axes}
    return CAStyle(Base.BroadcastStyle(A), Axes, ndims(A))
end
function Base.BroadcastStyle(A::Type{<:Adjoint{T, <:ComponentArray}}) where {T}
    return CAStyle(Base.BroadcastStyle(Adjoint{T,A}), getaxes(A), ndims(A))
end
function Base.BroadcastStyle(A::Type{<:Transpose{T, <:ComponentArray}}) where {T}
    return CAStyle(Base.BroadcastStyle(Transpose{T,A}), getaxes(A), ndims(A))
end

function Base.BroadcastStyle(::CAStyle{InnerStyle, Axes, N}, bc::BC.Broadcasted) where {InnerStyle, Axes, N}
    return CAStyle(Base.BroadcastStyle(InnerStyle(), bc), Axes, N)
end


Base.convert(::Type{<:BC.Broadcasted{Nothing}}, bc::BC.Broadcasted{<:CAStyle,<:Axes,<:F,<:Args}) where {Axes,F,Args} = getdata(bc)

getdata(bc::BC.Broadcasted{<:CAStyle}) = BC.broadcasted(bc.f, map(getdata, bc.args)...)
getdata(x::Adjoint) = getdata(x.parent)'
getdata(x::Transpose) = transpose(getdata(x.parent))


function Base.similar(bc::BC.Broadcasted{<:CAStyle{InnerStyle, Axes, N}}, args...) where {InnerStyle, Axes, N}
    return ComponentArray{Axes}(similar(BC.Broadcasted{InnerStyle}(bc.f, bc.args, bc.axes), args...))
end
function Base.similar(bc::BC.Broadcasted{<:CAStyle{InnerStyle, Axes, N}}, T::Type) where {InnerStyle, Axes, N}
    return ComponentArray{Axes}(similar(BC.Broadcasted{InnerStyle}(bc.f, bc.args, bc.axes), T))
end

# function Base.copy(bc::BC.Broadcasted{<:CAStyle{InnerStyle, Axes, N}}) where {InnerStyle, Axes,  N}
#     return ComponentArray{Axes}(Base.copy(BC.broadcasted(bc.f, map(getdata, bc.args)...)))
# end
# function Base.copy(bc::BC.Broadcasted{<:CAStyle{InnerStyle, Axes, N}}) where {InnerStyle, Axes,  N}
#     return ComponentArray{Axes}(Base.copy(BC.Broadcasted(InnerStyle())))
# end

# From https://github.com/JuliaArrays/OffsetArrays.jl/blob/master/src/OffsetArrays.jl
Base.dataids(A::ComponentArray) = Base.dataids(parent(A))
Broadcast.broadcast_unalias(dest::ComponentArray, src::ComponentArray) = parent(dest) === parent(src) ? src : Broadcast.unalias(dest, src)
