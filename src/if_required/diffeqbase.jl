# Can we figure out how to get rid of this?
(p::DiffEqBase.DefaultLinSolve)(x, A::ComponentMatrix, b, update_matrix=false; tol=nothing, kwargs...) = p(x, getdata(A), b, update_matrix; tol, kwargs...)

# function (p::DiffEqBase.DefaultLinSolve)(x,A::ComponentMatrix,b,update_matrix=false;tol=nothing, kwargs...)
#     if p.iterable isa Vector && eltype(p.iterable) <: LinearAlgebra.BlasInt # `iterable` here is the pivoting vector
#         F = LU{eltype(A)}(A, p.iterable, zero(LinearAlgebra.BlasInt))
#         ldiv!(x, F, b)
#         return nothing
#     end
    
#     if update_matrix
#         blasvendor = BLAS.vendor()
#         if ArrayInterface.can_setindex(x) && (size(A,1) <= 100 || ((blasvendor === :openblas || blasvendor === :openblas64) && size(A,1) <= 500))
#             p.A = RecursiveFactorization.lu!(A)
#         else
#             p.A = lu!(A)
#         end
#     end

#     x .= b
#     ldiv!(p.A,x)
#     return nothing
# end