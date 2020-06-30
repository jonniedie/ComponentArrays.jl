# # function Base.similar(::BC.Broadcasted{<:CAStyle{T,N,<:A,<:Axes}}) where {T,N,A<:StaticArrays.StaticArray,Axes}
# #     ComponentArray{Axes}(similar(A))
# # end

ComponentArray{A}(::UndefInitializer, ax::Axes) where {A<:StaticArrays.StaticArray,Axes<:Tuple} =
    ComponentArray(similar(A), ax...)

# # function Base.similar(bc::BC.Broadcasted{<:CAStyle{T,N,<:A,<:Axes}}, ::Type{<:TT}) where {T,N,A<:StaticArrays.StaticArray,Axes,TT}
# #     return ComponentArray{Axes}(similar(A, TT))
# # end

# # StaticComponentArray{T,N,A,Axes} = ComponentArray{T,N,<:A,Axes} where {A<:StaticArrays.StaticArray}

# # function Base.BroadcastStyle(A::Type{<:Adjoint{T, <:ComponentArray{<:T,<:N,<:StaticArrays.StaticArray,<:Axes}}}) where {T,N,Axes}
# #     return CAStyle(Base.BroadcastStyle(Adjoint{T,A}), getaxes(A), 2)
# # end
# # function Base.BroadcastStyle(A::Type{<:Transpose{T, <:ComponentArray{<:T,<:N,<:StaticArrays.StaticArray,<:Axes}}}) where {T,N,Axes}
# #     return CAStyle(Base.BroadcastStyle(Transpose{T,A}), getaxes(A), 2)
# # end


# # Sometimes you just need to get things done.
# function Base.Broadcast.BroadcastStyle(::Type{s19}) where s19<:Adjoint{T,s18} where s18<:ComponentArray{s12,s20,s21,s22} where s22<:Tuple{Vararg{AbstractAxis,N} where N} where s21<:StaticArray{S,s12,N} where S<:Tuple where N where s20<:N where s12<:T where {T, N}
#     return CAStyle(Base.BroadcastStyle(Adjoint{T,A}), getaxes(A), 2)
# end

# function Base.Broadcast.BroadcastStyle(::Type{s19}) where s19<:Transpose{T,s18} where s18<:ComponentArray{s12,s20,s21,s22} where s22<:Tuple{Vararg{AbstractAxis,N} where N} where s21<:StaticArray{S,s12,N} where S<:Tuple where N where s20<:N where s12<:T where {T, N}
#     return CAStyle(Base.BroadcastStyle(Transpose{T,A}), getaxes(A), 2)
# end