"""
    fastindices(i...)

Helper function for wrapping CArray symbolic indices in ```Val```s for type-stable indexing.
    Hopefully this wont be necessary in the future once I figure out when constant
    propagation does and doesn't work.

# Examples
```juliajulia> ca = CArray(a=1, b=[2, 1, 4], c=(a=2, b=[1, 2]))
CArray(a = 1.0, b = [2.0, 1.0, 4.0], c = (a = 2.0, b = [1.0, 2.0]))

julia> ca2 = ca .* ca'
7×7 CArray{Tuple{Axis{(a = 1, b = 2:4, c = (5:7, (a = 1, b = 2:3)))},Axis{(a = 1, b = 2:4, c = (5:7, (a = 1, b = 
2:3)))}},Float64,2,Array{Float64,2}}:
 1.0  2.0  1.0   4.0  2.0  1.0  2.0
 2.0  4.0  2.0   8.0  4.0  2.0  4.0
 1.0  2.0  1.0   4.0  2.0  1.0  2.0
 4.0  8.0  4.0  16.0  8.0  4.0  8.0
 2.0  4.0  2.0   8.0  4.0  2.0  4.0
 1.0  2.0  1.0   4.0  2.0  1.0  2.0
 2.0  4.0  2.0   8.0  4.0  2.0  4.0

julia> using BenchmarkTools

julia> _a, _b, _c = fastindices(:a, :b, :c)
  (Val{:a}(), Val{:b}(), Val{:c}())

julia> @btime \$ca2[:c,:c];
  12.199 μs (2 allocations: 80 bytes)

julia> @btime \$ca2[\$_c, \$_c];
  14.728 ns (2 allocations: 80 bytes)
```
"""
fastindices(i...) = Val.(i)

# Get value from Val type
getval(::Val{x}) where x = x
getval(::Type{Val{x}}) where x = x