## Linear Algebra
Base.pointer(x::ComponentArray) = pointer(getdata(x))

Base.unsafe_convert(::Type{Ptr{T}}, x::ComponentArray) where T = Base.unsafe_convert(Ptr{T}, getdata(x))

Base.adjoint(x::CVector) = ComponentArray(adjoint(getdata(x)), FlatAxis(), getaxes(x)[1])
Base.adjoint(x::CMatrix) = ComponentArray(adjoint(getdata(x)), reverse(getaxes(x))...)
Base.adjoint(x::AdjointCVector) = ComponentArray(adjoint(getdata(x)), (getaxes(x)[2],))

Base.transpose(x::CVector) = ComponentArray(transpose(getdata(x)), FlatAxis(), getaxes(x)[1])
Base.transpose(x::CMatrix) = ComponentArray(transpose(getdata(x)), reverse(getaxes(x))...)
Base.transpose(x::AdjointCVector) = ComponentArray(transpose(getdata(x)), (getaxes(x)[2],))

Base.:(*)(x::AdjointCVector, y::AbstractArray{<:T,<:N}) where {T,N} = ComponentArray(getdata(x)*y, getaxes(x)...)

Base.:(\)(x::CMatrix, y::AbstractVecOrMat) = getdata(x) \ y
Base.:(/)(x::AbstractVecOrMat, y::CMatrix) = x / getdata(y)

Base.inv(x::CMatrix) = inv(getdata(x))


## Vector to matrix concatenation
Base.hcat(x::CVector...) = ComponentArray(hcat(getdata.(x)...), getaxes(x[1])[1], FlatAxis())
Base.vcat(x::AdjointCVector...) = ComponentArray(vcat(getdata.(x)...), FlatAxis(), getaxes(x[1])[2])