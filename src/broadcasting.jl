const BC = Base.Broadcast

# Broadcasting
struct CAStyle{Axes,T,N} <: BC.AbstractArrayStyle{N} end
# struct CVecStyle{Axes,T} <: BC.AbstractArrayStyle{1} end
# struct CMatStyle{Axes,T} <: BC.AbstractArrayStyle{2} end

const CVecStyle{Axes,T} = CAStyle{Axes,T,1}
const CMatStyle{Axes,T} = CAStyle{Axes,T,2}

const BroadCAStyle{Axes,T,N} = BC.Broadcasted{CAStyle{Axes,T,N}}
const BroadCVecStyle{Axes,T} = BC.Broadcasted{CVecStyle{Axes,T}}
const BroadCMatStyle{Axes,T} = BC.Broadcasted{CMatStyle{Axes,T}}
const BroadDefArrStyle{N} = BC.DefaultArrayStyle{N}

CAStyle{Axes,T,N}(x::Val{i}) where {Axes,T,N,i} = CAStyle{Axes,T,N}()

Base.BroadcastStyle(::Type{<:CArray{Axes,T,N,A}}) where A<:AbstractArray{T,N} where {Axes,T,N} = CAStyle{Axes,T,N}()
Base.BroadcastStyle(::Type{<:CVector{Axes,T,A}}) where A<:AbstractVector{T} where {Axes,T} = CVecStyle{Axes,T}()
Base.BroadcastStyle(::Type{<:CMatrix{Axes,T,A}}) where A<:AbstractMatrix{T} where {Axes,T} = CMatStyle{Axes,T}()

# Base.BroadcastStyle(::CVecStyle{Ax1,T1}, ::CVecStyle{Ax2,T2}) where {Ax1,T1,Ax2,T2} =
#     CVecStyle{promote_type(Ax1,Ax2), promote_type(T1,T2)}()
# Base.BroadcastStyle(::CVecStyle{Ax1,T1}, ::CAStyle{Ax2,T2,N}) where {Ax1,T1,Ax2,T2,N} =
#     CAStyle{promote_type(Ax1,Ax2), promote_type(T1,T2), N}()
Base.BroadcastStyle(::CAStyle{Ax1,T1,N1}, ::CAStyle{Ax2,T2,N2}) where {Ax1,T1,N1,Ax2,T2,N2} =
    CAStyle{promote_type(Ax1,Ax2), promote_type(T1,T2), max(N1,N2)}()
# Base.BroadcastStyle(cvs::CVS, cms::CMS) where {CVS<:CVecStyle, CMS<:CMatStyle} = cms
# Base.BroadcastStyle(::CAS, ::TT) where {CAS<:CAStyle,TT<:DefArrStyle} = CAS()
# @generated function Base.BroadcastStyle(::CAStyle{Ax1,T1,N1}, ::BC.DefaultArrayStyle{N2}) where {Ax1,T1,N1,N2}
#     ax = fill_flat(Ax1,N2)
#     N = max(N1,N2)
#     return :(CAStyle{$ax, T1, $N}())
# end
function Base.BroadcastStyle(::CAStyle{Ax1,T1,N1}, ::BC.DefaultArrayStyle{N2}) where {Ax1,T1,N1,N2}
    ax = fill_flat(Ax1,N2)
    N = max(N1,N2)
    return CAStyle{ax, T1, N}()
end


function Base.similar(bc::BroadCAStyle{Axes,T,N}, ::Type{<:TT}) where {Axes,T,N,TT}
    # return :(Base.@_pure_meta; CArray{Axes}(similar(Array{TT,N}, axes(bc))))
    # x = bc.args[1]
    # return similar(x, TT)
    # ax = _axes(Axes)
    # # try
    # #     return CArray(similar(A(), TT, length.(ax)...), ax...)
    # # catch
    #     return CArray(Array{TT,N}(undef, length.(ax)...), ax...)
    # # end
    return CArray{Axes}(similar(Array{TT}, axes(bc)))
end
function Base.similar(bc::BroadCAStyle{Axes,T,N}) where {Axes,T,N}
    return CArray{Axes}(similar(Array{T}, axes(bc)))
end
# function Base.similar(bc::BroadCAStyle{Axes,T,N}, ::Type{<:TT}) where {Axes,T,N,TT}
#     ax = _axes(Axes)
#     return CArray(Array{TT,N}(undef, length.(ax)...), ax...)
# end

# function BC.combine_axes(x1::Axis, x2::Axis, args...)
#
# end
# function BC.combine_axes(x::Axis...)
#
# end

# Not sure why this saves so much time. The only thing it skips is unaliasing and extruding
@inline function Base.copyto!(dest::CArray, bc::BC.Broadcasted{Nothing})
    axes(dest) == axes(bc) || throwdm(axes(dest), axes(bc))
    # Performance optimization: broadcast!(identity, dest, A) is equivalent to copyto!(dest, A) if indices match
    if bc.f === identity && bc.args isa Tuple{AbstractArray} # only a single input argument to broadcast!
        A = bc.args[1]
        if axes(dest) == axes(A)
            return copyto!(dest, A)
        end
    end
    @simd for i in eachindex(dest)
        @inbounds dest[i] = bc[i]
    end
    return dest
end
function Base.convert(::Type{<:BC.Broadcasted{Nothing}}, bc::BC.Broadcasted{Style,Axes,F,Args}) where {Style<:CAStyle,Axes,F,Args}
    args = map(_data, bc.args)
    return BC.Broadcasted{Nothing,Axes,F,typeof(args)}(bc.f, args, bc.axes)
end
