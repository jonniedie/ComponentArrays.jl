## Linear Algebra
Base.pointer(x::CArray) = pointer(getdata(x))

Base.unsafe_convert(::Type{Ptr{T}}, x::CArray) where T = Base.unsafe_convert(Ptr{T}, getdata(x))

Base.adjoint(x::CVector) = CArray(adjoint(getdata(x)), FlatAxis(), getaxes(x)[1])
Base.adjoint(x::CMatrix) = CArray(adjoint(getdata(x)), reverse(getaxes(x))...)

Base.transpose(x::CVector) = CArray(transpose(getdata(x)), FlatAxis(), getaxes(x)[1])
Base.transpose(x::CMatrix) = CArray(transpose(getdata(x)), reverse(getaxes(x))...)

const AdjointVector{T,A} = Union{Adjoint{T,A}, Transpose{T,A}} where A<:AbstractVector{T}
const AdjointCVector{Axes,T,A} = CMatrix{Axes,T,A} where A<:AdjointVector

Base.:(*)(x::AdjointCVector, y::AbstractArray{<:T,<:N}) where {T,N} = CArray(getdata(x)*y, getaxes(x)...)

Base.:(\)(x::CMatrix, y::AbstractVecOrMat) = getdata(x) \ y
Base.:(/)(x::AbstractVecOrMat, y::CMatrix) = x / getdata(y)

Base.inv(x::CMatrix) = inv(getdata(x))
