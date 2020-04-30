const BC = Base.Broadcast

# Broadcasting
struct CAStyle{Axes,T,N} <: BC.AbstractArrayStyle{N} end

const CVecStyle{Axes,T} = CAStyle{Axes,T,1}
const CMatStyle{Axes,T} = CAStyle{Axes,T,2}

const BroadCAStyle{Axes,T,N} = BC.Broadcasted{CAStyle{Axes,T,N}}
const BroadCVecStyle{Axes,T} = BC.Broadcasted{CVecStyle{Axes,T}}
const BroadCMatStyle{Axes,T} = BC.Broadcasted{CMatStyle{Axes,T}}
const BroadDefArrStyle{N} = BC.DefaultArrayStyle{N}

CAStyle{Axes,T,N}(x::Val{i}) where {Axes,T,N,i} = CAStyle{Axes,T,N}()

Base.BroadcastStyle(::Type{<:ComponentArray{Axes,T,N,A}}) where A<:AbstractArray{T,N} where {Axes,T,N} = CAStyle{Axes,T,N}()
Base.BroadcastStyle(::Type{<:CVector{Axes,T,A}}) where A<:AbstractVector{T} where {Axes,T} = CVecStyle{Axes,T}()
Base.BroadcastStyle(::Type{<:CMatrix{Axes,T,A}}) where A<:AbstractMatrix{T} where {Axes,T} = CMatStyle{Axes,T}()

# TODO change fill_flat to take in N1 and N2 to avoid repeating code
# @generated function Base.BroadcastStyle(::CAStyle{<:Ax1,<:T1,<:N1}, ::CAStyle{<:Ax2,<:T2,<:N2}) where {Ax1,T1,N1,Ax2,T2,N2}
#     if N1>=N2
#         N = N1
#         Ax1 = fill_flat(Ax1,N)
#     else
#         N = N2
#         Ax2 = fill_flat(Ax2,N)
#     end
#     Ax = promote_type(Ax1, Ax2)
#     T = promote_type(T1, T2)
#     return :(CAStyle{$Ax, $T, $N}())
# end
# @generated function Base.BroadcastStyle(::CAStyle{<:Ax1,<:T1,<:N1}, ::BC.DefaultArrayStyle{<:N2}) where {Ax1,T1,N1,N2}
#     N = max(N1,N2)
#     ax = fill_flat(Ax1,N)
#     return :(CAStyle{$ax, T1, $N}())
# end
function Base.BroadcastStyle(::CAStyle{Ax1,T1,N1}, ::CAStyle{Ax2,T2,N2}) where {Ax1,T1,N1,Ax2,T2,N2}
    if N1>=N2
        N = N1
        ax1 = fill_flat(Ax1,N)
        ax2 = Ax2
    else
        N = N2
        ax1 = Ax1
        ax2 = fill_flat(Ax2,N)
    end
    Ax = promote_type(ax1, ax2)
    T = promote_type(T1, T2)
    return CAStyle{Ax, T, N}()
end
function Base.BroadcastStyle(::CAStyle{Ax1,T1,N1}, ::BC.DefaultArrayStyle{N2}) where {Ax1,T1,N1,N2}
    N = max(N1,N2)
    ax = fill_flat(Ax1,N)
    return CAStyle{ax, T1, N}()
end


function Base.similar(bc::BroadCAStyle{Axes,T,N}, ::Type{<:TT}) where {Axes,T,N,TT}
    return ComponentArray{Axes}(similar(Array{TT}, axes(bc)))
end
function Base.similar(bc::BroadCAStyle{Axes,T,N}) where {Axes,T,N}
    return ComponentArray{Axes}(similar(Array{T}, axes(bc)))
end

# Not sure why this saves so much time. The only thing it skips is unaliasing and extruding
function Base.copyto!(dest::ComponentArray, bc::BC.Broadcasted{Nothing})
    axes(dest) == axes(bc) || BC.throwdm(axes(dest), axes(bc))
    # Performance optimization: broadcast!(identity, dest, A) is equivalent to copyto!(dest, A) if indices match
    if bc.f === identity && bc.args isa Tuple{AbstractArray} # only a single input argument to broadcast!
        A = bc.args[1]
        if axes(dest) == axes(A)
            copyto!(dest, A)
            return dest
        end
    end
    @simd for i in eachindex(dest)
        @inbounds dest[i] = bc[i]
    end
    return dest
end
function Base.convert(::Type{<:BC.Broadcasted{Nothing}}, bc::BC.Broadcasted{Style,Axes,F,Args}) where {Style<:CAStyle,Axes,F,Args}
    args = map(getdata, bc.args)
    return BC.Broadcasted{Nothing,Axes,F,typeof(args)}(bc.f, args, bc.axes)
end
