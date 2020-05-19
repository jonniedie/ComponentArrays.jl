const BC = Base.Broadcast

# Broadcasting
struct CAStyle{T,N,Axes} <: BC.AbstractArrayStyle{N} end

const CVecStyle{T,Axes} = CAStyle{T,1,Axes}
const CMatStyle{T,Axes} = CAStyle{T,2,Axes}

const BroadCAStyle{T,N,Axes} = BC.Broadcasted{CAStyle{T,N,Axes}}
const BroadCVecStyle{T,Axes} = BC.Broadcasted{CVecStyle{T,Axes}}
const BroadCMatStyle{T,Axes} = BC.Broadcasted{CMatStyle{T,Axes}}
const BroadDefArrStyle{N} = BC.DefaultArrayStyle{N}

CAStyle{T,N,Axes}(::Val{i}) where {T,N,Axes,i} = CAStyle{T,N,Axes}()

Base.BroadcastStyle(CA::Type{<:ComponentArray{T,N,A,Axes}}) where A<:AbstractArray{T,N} where {T,N,Axes} = CAStyle{T,N,Axes}()
Base.BroadcastStyle(CA::Type{<:CVector{T,A,Axes}}) where A<:AbstractVector{T} where {Axes,T} = CVecStyle{T,Axes}()
Base.BroadcastStyle(CA::Type{<:CMatrix{T,A,Axes}}) where A<:AbstractMatrix{T} where {Axes,T} = CMatStyle{T,Axes}()

# TODO change fill_flat to take in N1 and N2 to avoid repeating code
@generated function Base.BroadcastStyle(::CAStyle{<:T1,<:N1,<:Ax1}, ::CAStyle{<:T2,<:N2,<:Ax2}) where {Ax1,T1,N1,Ax2,T2,N2}
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
    return :(CAStyle{$T, $N, $Ax}())
end
@generated function Base.BroadcastStyle(::CAStyle{<:T1,<:N1,<:Ax1}, ::BC.DefaultArrayStyle{N2}) where {T1,N1,Ax1,N2}
    N = max(N1,N2)
    Ax = fill_flat(Ax1,N)
    return :(CAStyle{T1, $N, $Ax}())
end


function Base.similar(bc::BroadCAStyle{T,N,Axes}, ::Type{<:TT}) where {T,N,Axes,TT}
    return ComponentArray{Axes}(similar(Array{TT}, axes(bc)))
end
function Base.similar(bc::BroadCAStyle{T,N,Axes}) where {T,N,Axes}
    return ComponentArray{Axes}(similar(Array{T}, axes(bc)))
end

# The preprocessing step in the Base copyto! implementation is slow for ComponentArrays so
# we are bypassing it and doing the conversion ourselves. 
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

# Need this to get around the goofy 0-dimensional array wrapping in the default copyto! I'd
# love to not have this, but I don't really want to track down why everything is being wrapped
Base.convert(::Type{BC.Broadcasted{Nothing}}, bc::BroadCAStyle) = getdata(bc)

getdata(bc::BroadCAStyle) = BC.Broadcasted{Nothing}(bc.f, map(getdata, bc.args), bc.axes)