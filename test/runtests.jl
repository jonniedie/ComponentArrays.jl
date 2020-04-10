using BenchmarkTools
using Test

include("CArray.jl")

ax = Axis{10,(a=1:2, b=3, c=(4:10, (a=1, b=2:7)))}()
a = collect(1:10.0)

ca = CArray(a, (ax,))
ca2 = CArray(a .* a', (ax,ax));
