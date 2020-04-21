## Linear Algebra
# Base.pointer(x::CArray) = pointer(_data(x))

# Base.unsafe_convert(::Type{Ptr{T}}, x::CArray) where T = Base.unsafe_convert(Ptr{T}, _data(x))

Base.adjoint(x::CVector) = CArray(adjoint(_data(x)), FlatAxis(), _axes(x)[1])
Base.adjoint(x::CMatrix) = CArray(adjoint(_data(x)), reverse(_axes(x))...)

Base.transpose(x::CVector) = CArray(transpose(_data(x)), FlatAxis(), _axes(x)[1])
Base.transpose(x::CMatrix) = CArray(transpose(_data(x)), reverse(_axes(x))...)

const AdjointVector{T,A} = Adjoint{T,A} where A<:AbstractVector{T}
const AdjointCVector{Axes,T,A} = CMatrix{Axes,T,A} where A<:AdjointVector

Base.:(*)(x::AdjointCVector, y::AbstractArray{<:T,<:N}) where {T,N} = CArray(_data(x)*y, _axes(x)...)

Base.:(\)(x::CMatrix, y::AbstractVecOrMat) = _data(x) \ y
Base.:(/)(x::AbstractVecOrMat, y::CMatrix) = x / _data(y)

Base.inv(x::CMatrix) = inv(_data(x))
