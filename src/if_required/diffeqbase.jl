ComponentSol{T,N,C} = DiffEqBase.AbstractODESolution{T,N,C} where C<:AbstractVector{<:ComponentArray}


# Plotting stuff
function DiffEqBase.getsyms(sol::ComponentSol)
    if DiffEqBase.has_syms(sol.prob.f)
        return sol.prob.f.syms
    else
        return labels(sol.u[1])
    end
end


# A little bit of type piracy. Should probably make this a PR to DiffEqBase
DiffEqBase.cleansyms(syms::AbstractArray{<:String}) = DiffEqBase.cleansyms.(syms)
DiffEqBase.cleansyms(syms::String) = syms

# DiffEqBase.interpret_vars(var::AbstractString, sol::ComponentSol, syms) =
#     DiffEqBase.interpret_vars(_to_sol_index(var, syms), sol, syms)
DiffEqBase.interpret_vars(var::Union{AbstractString, Symbol}, sol::ComponentSol, syms) =
    DiffEqBase.interpret_vars(_to_sol_index(var, syms), sol, syms)
# This doesn't work with mixed strings and integers
DiffEqBase.interpret_vars(vars::Tuple{Vararg{<:Union{<:AbstractString, Symbol}}}, sol::ComponentSol, syms) =
    DiffEqBase.interpret_vars(map(var->_to_sol_index(var, syms), vars), sol, syms)
DiffEqBase.interpret_vars(vars::AbstractArray{<:Union{<:AbstractString, Symbol}}, sol::ComponentSol, syms) =
    DiffEqBase.interpret_vars(collect(Iterators.flatten(map(var->_to_sol_index(var, syms), vars))), sol, syms)


_to_sol_index(var::Symbol, syms) = _to_sol_index(string(var), syms)
_to_sol_index(var::AbstractString, syms) = findall(startswith.(syms, var))
_to_sol_index(var, syms) = var


function (p::DiffEqBase.DefaultLinSolve)(x,A,b,update_matrix=false;tol=nothing, kwargs...)
  if p.iterable isa Vector && eltype(p.iterable) <: LinearAlgebra.BlasInt # `iterable` here is the pivoting vector
    F = LU{eltype(A)}(A, p.iterable, zero(LinearAlgebra.BlasInt))
    ldiv!(x, F, b)
    return nothing
  end
  if update_matrix
    if typeof(A) <: Union{Matrix, ComponentMatrix}
      blasvendor = BLAS.vendor()
      # if the user doesn't use OpenBLAS, we assume that is a better BLAS
      # implementation like MKL
      #
      # RecursiveFactorization seems to be consistantly winning below 100
      # https://discourse.julialang.org/t/ann-recursivefactorization-jl/39213
      if ArrayInterface.can_setindex(x) && (size(A,1) <= 100 || ((blasvendor === :openblas || blasvendor === :openblas64) && size(A,1) <= 500))
        p.A = RecursiveFactorization.lu!(A)
      else
        p.A = lu!(A)
      end
    elseif typeof(A) <: Tridiagonal
      p.A = lu!(A)
    elseif typeof(A) <: Union{SymTridiagonal}
      p.A = ldlt!(A)
    elseif typeof(A) <: Union{Symmetric,Hermitian}
      p.A = bunchkaufman!(A)
    elseif typeof(A) <: DiffEqBase.SparseMatrixCSC
      p.A = lu(A)
    elseif ArrayInterface.isstructured(A)
      p.A = factorize(A)
    elseif !(typeof(A) <: DiffEqBase.AbstractDiffEqOperator)
      # Most likely QR is the one that is overloaded
      # Works on things like CuArrays
      p.A = qr(A)
    end
  end

  if typeof(A) <: Union{Matrix,SymTridiagonal,Tridiagonal,Symmetric,Hermitian} # No 2-arg form for SparseArrays!
    x .= b
    ldiv!(p.A,x)
  # Missing a little bit of efficiency in a rare case
  #elseif typeof(A) <: DiffEqArrayOperator
  #  ldiv!(x,p.A,b)
  elseif ArrayInterface.isstructured(A) || A isa DiffEqBase.SparseMatrixCSC
    ldiv!(x,p.A,b)
  elseif typeof(A) <: DiffEqBase.AbstractDiffEqOperator
    # No good starting guess, so guess zero
    if p.iterable === nothing
      p.iterable = IterativeSolvers.gmres_iterable!(x,A,b;initially_zero=true,restart=5,maxiter=5,tol=1e-16,kwargs...)
      p.iterable.reltol = tol
    end
    x .= false
    iter = p.iterable
    DiffEqBase.purge_history!(iter, x, b)

    for residual in iter
    end
  else
    ldiv!(x,p.A,b)
  end
  return nothing
end