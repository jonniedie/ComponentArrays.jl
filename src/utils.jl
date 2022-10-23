@deprecate fastindices(i::Tuple) Val.(i)
@deprecate fastindices(i...) Val.((i...,))

# Make a Val if input isn't already one
toval(x::Val) = x
toval(x) = Val(x)
toval(x::String) = Val(Symbol(x))
toval(x::AbstractArray{Symbol}) = Val((x...,))

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
recursive_length(nt::NamedTuple{(), Tuple{}}) = 0

# Find the highest element type
recursive_eltype(nt::NamedTuple) = isempty(nt) ? Base.Bottom : mapreduce(recursive_eltype, promote_type, nt)
recursive_eltype(x::Vector{Any}) = isempty(x) ? Base.Bottom : mapreduce(recursive_eltype, promote_type, x)
recursive_eltype(x::Dict) = isempty(x) ? Base.Bottom : mapreduce(recursive_eltype, promote_type, values(x))
recursive_eltype(::AbstractArray{T,N}) where {T<:Number, N} = T
recursive_eltype(x) = typeof(x)


function reorder_as(prototype::ComponentArray, input::ComponentArray)
    @assert size(prototype) == size(input) "Incompatible sizes: $(size(prototype)) and $(size(input))"
    @inline getslice(::AbstractAxis{nothing}) = (:,)
    @inline getslice(::AbstractAxis{:}) = (:,)
    @inline getslice(::AbstractAxis{IdxMap}) where {IdxMap} = IdxMap
    result = ComponentArray(getdata(input), getaxes(prototype)...)
    for slices in Base.product(getslice.(getaxes(prototype))...)
        result[slices...] = input[slices...]
    end
    return result
end

function reorder_as(prototype::ComponentArray{Any,Any,Ax}, input::ComponentArray{Any,Any,Ax}) where {Ax}
    # Fast method for ComponentArrays that have identical axes
    return input
end
