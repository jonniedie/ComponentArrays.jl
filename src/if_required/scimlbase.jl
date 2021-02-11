# ComponentSol{T,N,C} = SciMLBase.AbstractODESolution{T,N,C} where C<:AbstractVector{<:ComponentArray}

# Plotting stuff
function SciMLBase.getsyms(sol::SciMLBase.AbstractODESolution{T,N,C}) where {T,N,C<:AbstractVector{<:ComponentArray}}
    if SciMLBase.has_syms(sol.prob.f)
        return sol.prob.f.syms
    else
        return labels(sol.u[1])
    end
end

# A little bit of type piracy. Should probably make this a PR to DiffEqBase
SciMLBase.cleansyms(syms::AbstractArray{<:String}) = SciMLBase.cleansyms.(syms)
SciMLBase.cleansyms(syms::String) = syms
