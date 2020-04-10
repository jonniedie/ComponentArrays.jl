
# Broadcasting
struct CAStyle{Axes,T,N,A} <: Broadcast.AbstractArrayStyle{N} end
const BroadCAStyle{Axes,T,N,A} = Broadcast.Broadcasted{CAStyle{Axes,T,N,A}}
const DefArrStyle{N} = Base.Broadcast.DefaultArrayStyle{N}

Base.BroadcastStyle(::Type{<:CArray{Axes,T,N,A}}) where {Axes,T,N,A} = CAStyle{Axes,T,N,A}()
CAStyle{Axes,T,N,A}(x::Val{i}) where {Axes,T,N,A,i} = CAStyle{Axes,T,N,A}()
Base.BroadcastStyle(::CAStyle{Axes,T,N,A}, ::CAStyle{Axes,TT,N,A}) where {Axes,T,N,A,TT} =
    CAStyle{Axes,promote_type(T,TT),N,A}()
Base.BroadcastStyle(::CAStyle{Axes,T,N,A}, ::TT) where {Axes,T,N,A,TT<:DefArrStyle} = TT()
# Base.BroadcastStyle(::CAStyle{Axes,T,N,A}, ::TT) where {Axes,T,N,A,TT<:DefArrStyle{0}} =
#     CAStyle{Axes,T,N,A}()
# Base.BroadcastStyle(::TT, ::CAStyle{Axes,T,N,A}) where {Axes,T,N,A,TT<:DefArrStyle{0}} =
#     CAStyle{Axes,T,N,A}()

function Base.similar(bc::BroadCAStyle{Axes,T,N,A}, ::Type{TT}) where {Axes,T,N,A,TT}
    # return :(Base.@_pure_meta; CArray{Axes}(similar(Array{TT,N}, axes(bc))))
    # x = bc.args[1]
    # return similar(x, TT)
    ax = _axes(Axes)
    # try
    #     return CArray(similar(A(), TT, length.(ax)...), ax...)
    # catch
        return CArray(Array{TT,N}(undef, length.(ax)...), ax...)
    # end
end

# function Base.Broadcast.combine_axes(x1::Axis, x2::Axis, args...)
#
# end
# function Base.Broadcast.combine_axes(x::Axis...)
#
# end
