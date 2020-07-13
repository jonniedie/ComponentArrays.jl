## Linear Algebra
Base.pointer(x::ComponentArray{T,N,A,Axes}) where {T,N,A<:DenseArray,Axes} = pointer(getdata(x))

Base.unsafe_convert(::Type{Ptr{T}}, x::ComponentArray{T,N,A,Axes}) where {T,N,A,Axes} = Base.unsafe_convert(Ptr{T}, getdata(x))

Base.strides(x::ComponentArray) = strides(getdata(x))

Base.stride(x::ComponentArray, k) = stride(getdata(x), k)
Base.stride(x::ComponentArray, k::Int64) = stride(getdata(x), k)


ArrayInterface.lu_instance(jac_prototype::ComponentArray) = ArrayInterface.lu_instance(getdata(jac_prototype))


## Vector to matrix concatenation
Base.hcat(x::CV...) where {CV<:ComponentVector} = ComponentArray(hcat(getdata.(x)...), getaxes(x[1])[1], FlatAxis())

Base.vcat(x::ComponentVector, y::AbstractVector) = vcat(getdata(x), y)
Base.vcat(x::AbstractVector, y::ComponentVector) = vcat(x, getdata(y))
function Base.vcat(x::ComponentVector, y::ComponentVector)
    if reduce((accum, key) -> accum || (key in keys(x)), keys(y); init=false)
        return vcat(getdata(x), getdata(y))
    else
        return ComponentArray(x; NamedTuple(y)...)
    end
end
Base.vcat(x::CV...) where {CV<:AdjOrTransComponentArray} =ComponentArray(vcat(map(y->getdata(y.parent)', x)...), getaxes(x[1]))
Base.vcat(x::ComponentVector...) = reduce((x1, x2) -> vcat(x1, x2), x)
Base.vcat(x::ComponentVector, args...) = vcat(getdata(x), getdata.(args)...)

# While there are some cases where these were faster, it is going to be almost impossible to
# to keep up with method ambiguity errors due to other array types overloading *, /, and \.
# Leaving these here and commented out for now, but will delete them later.

# # Avoid slower fallback
# for f in [:(*), :(/), :(\)]
#     @eval begin
#         # The normal stuff
#         Base.$f(x::ComponentArray, y::AbstractArray) = $f(getdata(x), y)
#         Base.$f(x::AbstractArray, y::ComponentArray) = $f(x, getdata(y))
#         Base.$f(x::ComponentArray, y::ComponentArray) = $f(getdata(x), getdata(y))

#         # A bunch of special cases to avoid ambiguous method errors
#         Base.$f(x::ComponentArray, y::AbstractMatrix) = $f(getdata(x), y)
#         Base.$f(x::AbstractMatrix, y::ComponentArray) = $f(x, getdata(y))

#         Base.$f(x::ComponentArray, y::AbstractVector) = $f(getdata(x), y)
#         Base.$f(x::AbstractVector, y::ComponentArray) = $f(x, getdata(y))
#     end
# end

# # Adjoint/transpose special cases
# for f in [:(*), :(/)]
#     @eval begin
#         Base.$f(x::Adjoint, y::ComponentArray) = $f(getdata(x), getdata(y))
#         Base.$f(x::Transpose, y::ComponentArray) = $f(getdata(x), getdata(y))

#         Base.$f(x::Adjoint{T,<:AbstractVector{T}}, y::ComponentVector) where T = $f(x, getdata(y))
#         Base.$f(x::Transpose{T,<:AbstractVector{T}}, y::ComponentVector) where T = $f(x, getdata(y))

#         Base.$f(x::Adjoint{T,<:AbstractVector{T}}, y::ComponentMatrix{T,A,Axes}) where {T,A,Axes} = $f(x, getdata(y))
#         Base.$f(x::Transpose{T,<:AbstractVector{T}}, y::ComponentMatrix{T,A,Axes}) where {T,A,Axes} = $f(x, getdata(y))

#         Base.$f(x::Adjoint{T,<:AbstractMatrix{T}}, y::ComponentVector) where {T} = $f(x, getdata(y))
#         Base.$f(x::Transpose{T,<:AbstractMatrix{T}}, y::ComponentVector) where {T} = $f(x, getdata(y))

#         Base.$f(x::ComponentArray, y::Adjoint{T,<:AbstractVector{T}}) where T = $f(getdata(x), y)
#         Base.$f(x::ComponentArray, y::Transpose{T,<:AbstractVector{T}}) where T = $f(getdata(x), y)

#         Base.$f(x::ComponentArray, y::Adjoint{T,<:ComponentVector}) where T = $f(getdata(x), getdata(y))
#         Base.$f(x::ComponentArray, y::Transpose{T,<:ComponentVector}) where T = $f(getdata(x), getdata(y))

#         # There seems to be a new method in Julia > v.1.4 that specializes on this
#         Base.$f(x::Adjoint{T,<:AbstractVector{T}}, y::ComponentVector{T,A,Axes}) where {T<:Number,A,Axes} = $f(x, getdata(y))
#         Base.$f(x::Transpose{T,<:AbstractVector{T}}, y::ComponentVector{T,A,Axes}) where {T<:Number,A,Axes} = $f(x, getdata(y))

#         Base.$f(x::Adjoint{T,<:AbstractVector{T}}, y::ComponentVector{T,A,Axes}) where {T<:Real,A,Axes} = $f(getdata(x), getdata(y))
#         Base.$f(x::Transpose{T,<:AbstractVector{T}}, y::ComponentVector{T,A,Axes}) where {T<:Real,A,Axes} = $f(getdata(x), getdata(y))
#     end
# end