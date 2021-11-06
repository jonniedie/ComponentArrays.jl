# ComponentSol{T,N,C} = SciMLBase.AbstractODESolution{T,N,C} where C<:AbstractVector{<:ComponentArray}

# Plotting stuff
function SciMLBase.getsyms(sol::SciMLBase.AbstractODESolution{T,N,C}) where {T,N,C<:AbstractVector{<:ComponentArray}}
    if SciMLBase.has_syms(sol.prob.f)
        return sol.prob.f.syms
    else
        return Symbol.(labels(sol.u[1]))
    end
end
