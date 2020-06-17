const BC = Base.Broadcast

# Broadcasting
struct CAStyle{T,N,A,Axes} <: BC.AbstractArrayStyle{N} end

const CVecStyle{T,A,Axes} = CAStyle{T,1,A,Axes}
const CMatStyle{T,A,Axes} = CAStyle{T,2,A,Axes}

const BroadCAStyle{T,N,A,Axes} = BC.Broadcasted{<:CAStyle{T,N,A,Axes}}
const BroadCVecStyle{T,A,Axes} = BC.Broadcasted{<:CVecStyle{T,A,Axes}}
const BroadCMatStyle{T,A,Axes} = BC.Broadcasted{<:CMatStyle{T,A,Axes}}
const BroadDefArrStyle{N} = BC.DefaultArrayStyle{N}

CAStyle{T,N,A,Axes}(::Val{i}) where {T,N,A,Axes,i} = CAStyle{T,N,A,Axes}()

Base.BroadcastStyle(::Type{<:ComponentArray{T,N,A,Axes}}) where A<:AbstractArray{T,N} where {T,N,Axes} = CAStyle{T,N,A,Axes}()
Base.BroadcastStyle(::Type{<:CVector{T,A,Axes}}) where A<:AbstractVector{T} where {Axes,T} = CVecStyle{T,A,Axes}()
Base.BroadcastStyle(::Type{<:CMatrix{T,A,Axes}}) where A<:AbstractMatrix{T} where {Axes,T} = CMatStyle{T,A,Axes}()



function maybe_promote_type(A1::Type{<:AbstractArray{T1,N1}}, A2::Type{<:AbstractArray{T2,N2}}) where {T1,N1,T2,N2}
    A = promote_type(A1, A2)
    return isconcretetype(A) ? A : Array{promote_type(T1, T2), max(N1, N2)}
end

# TODO change fill_flat to take in N1 and N2 to avoid repeating code
function Base.BroadcastStyle(::CAStyle{<:T1,<:N1,<:A1,<:Ax1}, ::CAStyle{<:T2,<:N2,<:A2,<:Ax2}) where {Ax1,T1,N1,A1,Ax2,T2,N2,A2}
    if N1<N2
        N = N2
        ax1 = fill_flat(Ax1,N)
        ax2 = Ax2
        A = A2
    elseif N1>N2
        N = N1
        ax1 = Ax1
        ax2 = fill_flat(Ax2,N)
        A = A1
    else
        N = N1
        ax1, ax2 = Ax1, Ax2
        # A = maybe_promote_type(A1, A2)
    end
    Ax = promote_type.(typeof.(getaxes(ax1)), typeof.(getaxes(ax2))) .|> (x->x()) |> typeof
    # T = promote_type(T1, T2)
    A = maybe_promote_type(A1, A2)
    T = eltype(A)
    return CAStyle{T, N, A, Ax}() #:(CAStyle{$T, $N, $A, $Ax}())
end
function Base.BroadcastStyle(::CAStyle{T1,N1,A1,<:Ax1}, ::BC.DefaultArrayStyle{N2}) where {T1,N1,A1,Ax1,N2}
    N = max(N1,N2)
    Ax = fill_flat(Ax1,N)
    A = maybe_promote_type(A1, Array{T1,N2})
    return CAStyle{T1, N, A, Ax}() #:(CAStyle{T1, $N, A1, $Ax}())
end

# TODO: Need to find a better way than two similars
function Base.similar(bc::BC.Broadcasted{<:CAStyle{T,N,A,Axes}}, ::Type{<:TT}) where {T,N,A,Axes,TT}
    return ComponentArray{Axes}(similar(similar(A, axes(bc)), TT))
end
function Base.similar(bc::BC.Broadcasted{<:CAStyle{T,N,A,Axes}}, ::Type{<:T}) where {T,N,A,Axes}
    return ComponentArray{Axes}(similar(A, axes(bc)))
end
# function Base.similar(bc::BC.Broadcasted{<:CAStyle{T,N,A,Axes}}, ::Type{<:TT}) where {T,N,A<:AdjointVector,Axes,TT}
#     return ComponentArray{Axes}(similar(Array{TT}, axes(bc)))
# end

# # The preprocessing step in the Base copyto! implementation is slow for ComponentArrays so
# # we are bypassing it and doing the conversion ourselves. 
# function Base.copyto!(dest::ComponentArray, bc::BC.Broadcasted{Nothing})
#     axes(dest) == axes(bc) || BC.throwdm(axes(dest), axes(bc))
#     # Performance optimization: broadcast!(identity, dest, A) is equivalent to copyto!(dest, A) if indices match
#     if bc.f === identity && bc.args isa Tuple{AbstractArray} # only a single input argument to broadcast!
#         A = bc.args[1]
#         if axes(dest) == axes(A)
#             copyto!(dest, A)
#             return dest
#         end
#     end
#     @simd for i in eachindex(bc)
#         @inbounds dest[i] = bc[i]
#     end
#     return dest
# end

# Need this to get around the goofy 0-dimensional array wrapping in the default copyto! I'd
# love to not have this, but I don't really want to track down why everything is being wrapped
Base.convert(::Type{BC.Broadcasted{Nothing}}, bc::BroadCAStyle) = getdata(bc)

getdata(bc::BroadCAStyle) = BC.Broadcasted{Nothing}(bc.f, map(getdata, bc.args), bc.axes)


# Helper for extruding axes
fill_flat(Ax::Type{<:VarAxes}, N) = fill_flat(getaxes(Ax), N) |> typeof
function fill_flat(Ax::VarAxes, N)
    axs = getaxes(Ax)
    n = length(axs)
    if N>n
        axs = (axs..., ntuple(x -> FlatAxis(), N-n)...)
    end
    return axs
end

# From https://github.com/JuliaArrays/OffsetArrays.jl/blob/master/src/OffsetArrays.jl
Base.dataids(A::ComponentArray) = Base.dataids(parent(A))
Broadcast.broadcast_unalias(dest::ComponentArray, src::ComponentArray) = parent(dest) === parent(src) ? src : Broadcast.unalias(dest, src)

