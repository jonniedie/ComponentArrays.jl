"""
    fastindices(i...)

Wrap ```ComponentArray``` symbolic indices in ```Val```s for type-stable indexing.

# Examples
```julia-repl
julia> using ComponentArrays

julia> ca = ComponentArray(a=1, b=[2, 1, 4], c=(a=2, b=[1, 2]))
ComponentVector{Int64}(a = 1, b = [2, 1, 4], c = (a = 2, b = [1, 2]))

julia> ca2 = ca .* ca'
7×7 ComponentMatrix{Int64} with axes Axis(a = 1, b = 2:4, c = ViewAxis(5:7, Axis(a = 1, b = 2:3))) × Axis(a = 1, b = 2:4, c = ViewAxis(5:7, Axis(a = 1, b = 2:3)))
 1  2  1   4  2  1  2
 2  4  2   8  4  2  4
 1  2  1   4  2  1  2
 4  8  4  16  8  4  8
 2  4  2   8  4  2  4
 1  2  1   4  2  1  2
 2  4  2   8  4  2  4

julia> _a, _b, _c = fastindices(:a, :b, :c)
(Val{:a}(), Val{:b}(), Val{:c}())

julia> ca2[_c, _c]
3×3 ComponentMatrix{Int64,SubArray...} with axes Axis(a = 1, b = 2:3) × Axis(a = 1, b = 2:3)
 4  2  4
 2  1  2
 4  2  4

julia> ca2[_c, _c] == ca2[:c, :c]
true
```
"""
fastindices(i...) = toval.(i)
fastindices(i::Tuple) = toval.(i)


# Make a Val if input isn't already one
toval(x::Val) = x
toval(x) = Val(x)
toval(x::String) = Val(Symbol(x))

# Get value from Val type
getval(::Val{x}) where x = x
getval(::Type{Val{x}}) where x = x

# Split an array up into partitions where the Ns are partition sizes on each dimension
partition(A) = A
partition(a, N...) = partition(a, N)
# Faster method for vectors and matrices
partition(v, N) = (view(v, i:i+N-1) for i in firstindex(v):N:lastindex(v))
function partition(m, N1, N2)
    ax = axes(m)
    firsts = firstindex.(ax)
    lasts = lastindex.(ax)
    return (view(m, i:i+N1-1, j:j+N2-1) for i in firsts[1]:N1:lasts[1], j in firsts[2]:N2:lasts[2])
end
# Slower fallback for higher dimensions
function partition(a::A, N::Tuple) where A<:AbstractArray
    ax = axes(a)
    offs = firstindex.(ax)
    return (view(a, (:).((I.I .- 1) .* N .+ offs, ((I.I .- 1) .* N .+ N .- 1 .+ offs))...) for I in CartesianIndices(div.(size(a), N)))
end
# partition(a::A, N::Tuple) where A<:AbstractVector = reshape(view(a, :), N)

# Faster filtering of tuples by type
filter_by_type(::Type{T}, args...) where T = filter_by_type(T, (), args...)
filter_by_type(::Type{T}, part::Tuple) where T = part
filter_by_type(::Type{T}, part::Tuple, ax, args...) where T = filter_by_type(T, part, args...)
filter_by_type(::Type{T}, part::Tuple, ax::T, args...) where T = filter_by_type(T, (part..., ax), args...)

# Flat length of an arbitrarily nested named tuple
recursive_length(x) = length(x)
recursive_length(a::AbstractArray{T,N}) where {T<:Number,N} = length(a)
recursive_length(a::AbstractArray) = recursive_length.(a) |> sum
recursive_length(nt::NamedTuple) = values(nt) .|> recursive_length |> sum
recursive_length(::Union{Nothing, Missing}) = 1
