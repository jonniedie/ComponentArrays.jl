## https://github.com/SciML/DifferentialEquations.jl/issues/849
function ArrayInterface.lu_instance(x::ComponentMatrix)
    T = eltype(x)
    noUnitT = typeof(zero(T))
    luT = LinearAlgebra.lutype(noUnitT)
    ipiv = Vector{LinearAlgebra.BlasInt}(undef, 0)
    info = zero(LinearAlgebra.BlasInt)
    return LU{luT}(similar(x), ipiv, info)
end

# Helpers for dealing with adjoints and such
_first_axis(x::AbstractComponentVecOrMat) = getaxes(x)[1]

_second_axis(x::AbstractMatrix) = FlatAxis()
_second_axis(x::ComponentMatrix) = getaxes(x)[2]

_out_axes(::typeof(*), a, b::AbstractVector) = (_first_axis(a), )
_out_axes(::typeof(*), a, b::AbstractMatrix) = (_first_axis(a), _second_axis(b))
_out_axes(::typeof(\), a, b::AbstractVector) = (_second_axis(a), )
_out_axes(::typeof(\), a, b::AbstractMatrix) = (_second_axis(a), _second_axis(b))
_out_axes(::typeof(/), a::AbstractMatrix, b) = (_first_axis(a), _first_axis(b))

# Arithmetic
for op in [:*, :\, :/]
    @eval begin
        function Base.$op(A::AbstractComponentVecOrMat, B::AbstractComponentVecOrMat)
            C = $op(getdata(A), getdata(B))
            ax = _out_axes($op, A, B)
            return ComponentArray(C, ax...)
        end
    end
end


for op in [:adjoint, :transpose]
    @eval begin
        function LinearAlgebra.$op(M::ComponentMatrix{T,A,Tuple{Ax1,Ax2}}) where {T,A,Ax1,Ax2}
            data = $op(getdata(M))
            return ComponentArray(data, (Ax2(), Ax1())[1:ndims(data)]...)
        end

        function LinearAlgebra.$op(M::ComponentVector{T,A,Tuple{Ax1}}) where {T,A,Ax1}
            return ComponentMatrix($op(getdata(M)), FlatAxis(), Ax1())
        end
    end
end