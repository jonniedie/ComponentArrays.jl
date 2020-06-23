## Linear Algebra
Base.pointer(x::ComponentArray{T,N,A,Axes}) where {T,N,A<:DenseArray,Axes} = pointer(getdata(x))

Base.unsafe_convert(::Type{Ptr{T}}, x::ComponentArray{T,N,A,Axes}) where {T,N,A<:DenseArray,Axes} = Base.unsafe_convert(Ptr{T}, getdata(x))

Base.adjoint(x::CVector) = ComponentArray(adjoint(getdata(x)), FlatAxis(), getaxes(x)[1])
Base.adjoint(x::CMatrix) = ComponentArray(adjoint(getdata(x)), reverse(getaxes(x))...)
Base.adjoint(x::AdjointCVector) = ComponentArray(adjoint(getdata(x)), (getaxes(x)[2],))

Base.transpose(x::CVector) = ComponentArray(transpose(getdata(x)), FlatAxis(), getaxes(x)[1])
Base.transpose(x::CMatrix) = ComponentArray(transpose(getdata(x)), reverse(getaxes(x))...)
Base.transpose(x::AdjointCVector) = ComponentArray(transpose(getdata(x)), (getaxes(x)[2],))

# Avoid slow linear indexing fallback
for f in [:(*), :(/), :(\)]
    @eval begin
        # The normal stuff
        Base.$f(x::ComponentArray, y::AbstractArray) = $f(getdata(x), y)
        Base.$f(x::AbstractArray, y::ComponentArray) = $f(x, getdata(y))
        Base.$f(x::ComponentArray, y::ComponentArray) = $f(getdata(x), getdata(y))

        # A bunch of special cases to avoid ambiguous method errors
        Base.$f(x::ComponentArray, y::AbstractMatrix) = $f(getdata(x), y)
        Base.$f(x::AbstractMatrix, y::ComponentArray) = $f(x, getdata(y))

        Base.$f(x::ComponentArray, y::AbstractVector) = $f(getdata(x), y)
        Base.$f(x::AbstractVector, y::ComponentArray) = $f(x, getdata(y))
    end
end

# Adjoint/transpose special cases
for f in [:(*), :(/)]
    @eval begin
        Base.$f(x::Adjoint, y::ComponentArray) = $f(x, getdata(y))
        Base.$f(x::Transpose, y::ComponentArray) = $f(x, getdata(y))

        Base.$f(x::Adjoint{T,<:AbstractVector{T}}, y::ComponentVector) where T = $f(x, getdata(y))
        Base.$f(x::Transpose{T,<:AbstractVector{T}}, y::ComponentVector) where T = $f(x, getdata(y))

        # There seems to be a new method in Julia > v.1.4 that specializes on this
        Base.$f(x::Adjoint{T,<:AbstractVector{T}}, y::ComponentVector{T,A,Axes}) where {T<:Number,A,Axes} = $f(x, getdata(y))
        Base.$f(x::Transpose{T,<:AbstractVector{T}}, y::ComponentVector{T,A,Axes}) where {T<:Number,A,Axes} = $f(x, getdata(y))

        Base.$f(x::Adjoint{T,<:AbstractVector{T}}, y::ComponentVector{T,A,Axes}) where {T<:Real,A,Axes} = $f(x, getdata(y))
        Base.$f(x::Transpose{T,<:AbstractVector{T}}, y::ComponentVector{T,A,Axes}) where {T<:Real,A,Axes} = $f(x, getdata(y))

        Base.$f(x::Adjoint{T,<:AbstractVector{T}}, y::ComponentMatrix{T,A,Axes}) where {T,A,Axes} = $f(x, getdata(y))
        Base.$f(x::Transpose{T,<:AbstractVector{T}}, y::ComponentMatrix{T,A,Axes}) where {T,A,Axes} = $f(x, getdata(y))
    end
end

#TODO: All this stuff
LinearAlgebra.ldiv!(x::ComponentArray, args...) = ldiv!(getdata(x), getdata.(args)...)
LinearAlgebra.ldiv!(Y::ComponentArray, A::Factorization, B::ComponentArray) = ldiv!(getdata(Y), A, getdata(B))
LinearAlgebra.ldiv!(x::ComponentArray, ::Nothing, A) = ldiv!(getdata(x), nothing, A)

Base.inv(x::ComponentMatrix) = inv(getdata(x))


## Vector to matrix concatenation
Base.hcat(x::ComponentVector...) = ComponentArray(hcat(getdata.(x)...), getaxes(x[1])[1], FlatAxis())
Base.vcat(x::AdjointCVector...) = ComponentArray(vcat(getdata.(x)...), FlatAxis(), getaxes(x[1])[2])