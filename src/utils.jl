"""
    fastindices(i...)

Wrap ```ComponentArray``` symbolic indices in ```Val```s for type-stable indexing.

# Examples
```julia-repl
julia> using ComponentArrays, BenchmarkTools

julia> ca = ComponentArray(a=1, b=[2, 1, 4], c=(a=2, b=[1, 2]))
ComponentArray{Float64}(a = 1.0, b = [2.0, 1.0, 4.0], c = (a = 2.0, b = [1.0, 2.0]))

julia> ca2 = ca .* ca'
7×7 ComponentArray{Tuple{Axis{(a = 1, b = 2:4, c = (5:7, (a = 1, b = 2:3)))},Axis{(a = 1, b = 2:4, c = (5:7, (a = 1, b = 
2:3)))}},Float64,2,Array{Float64,2}}:
 1.0  2.0  1.0   4.0  2.0  1.0  2.0
 2.0  4.0  2.0   8.0  4.0  2.0  4.0
 1.0  2.0  1.0   4.0  2.0  1.0  2.0
 4.0  8.0  4.0  16.0  8.0  4.0  8.0
 2.0  4.0  2.0   8.0  4.0  2.0  4.0
 1.0  2.0  1.0   4.0  2.0  1.0  2.0
 2.0  4.0  2.0   8.0  4.0  2.0  4.0

julia> _a, _b, _c = fastindices(:a, :b, :c)
(Val{:a}(), Val{:b}(), Val{:c}())

julia> @btime \$ca2[:c,:c];
  12.199 μs (2 allocations: 80 bytes)

julia> @btime \$ca2[\$_c, \$_c];
  14.728 ns (2 allocations: 80 bytes)
```
"""
fastindices(i...) = toval.(i)
fastindices(i::Tuple) = toval.(i)

toval(x::Val) = x
toval(x) = Val(x)

# Get value from Val type
getval(::Val{x}) where x = x
getval(::Type{Val{x}}) where x = x

partition(A, N) = collect(Iterators.partition(A, N))
function partition(A, N...)
    part_size = prod(N)
    n_parts = size(A) .÷ N
    Ap = partition(A, part_size)
    return reshape(reshape.(Ap, N...), n_parts...)
end