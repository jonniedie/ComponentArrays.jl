using BenchmarkTools
using ComponentArrays
using Test

ax = Axis{(a=1, b=2:3, c=(4:10, (a=1, b=2:7)))}()
a = collect(1:10.0)

ca = CArray(a, ax)
ca2 = CArray(a .* a', ax, ax);

# function f()
#     ax = Axis{10,(a=1, b=2:3, c=(4:10, (a=1, b=2:7)))}()
#     a = collect(1:10.0)
#
#     ca = CArray(a, ax)
#     ca2 = CArray(a .* a', ax, ax);
#
#     (ca .* ca' for i in 1:1000)
#     return nothing
# end
