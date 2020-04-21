using BenchmarkTools
using ComponentArrays
using ForwardDiff
using Test

c = (a=(a=1, b=[1.0, 4.4]), b=[0.4, 2, 1, 45])
nt = (a=100, b=[4, 1.3], c=c)
ax = Axis(a=1, b=2:3, c=(4:10, (a=(1:3, (a=1, b=2:3)), b=4:7)))
ax_c = (a=(1:3, (a=1, b=2:3)), b=4:7)
a = Float64[100, 4, 1.3, 1, 1, 4.4, 0.4, 2, 1, 45]
ca = CArray(nt)
ca_Float32 = CArray{Float32}(nt)
ca_composed = CArray(a=1, b=ca)

nt2 = (a=5, b=[(a=(a=20,b=1), b=0), (a=(a=33,b=1), b=0), (a=(a=44, b=4), b=3)], c=(a=(a=2, b=[1,2]), b=[1., 2.]))
ca2 = CArray(nt)

cmat = CArray(a .* a', ax, ax)

@testset "Construction" begin
    @test ca == CArray(a=100, b=[4, 1.3], c=(a=(a=1, b=[1.0, 4.4]), b=[0.4, 2, 1, 45]))
    @test ca_Float32 == CArray(Float32.(a), ax)
    @test eltype(CArray{ForwardDiff.Dual}(nt)) == ForwardDiff.Dual
    @test_skip ca_composed.b isa CArray
end

@testset "Set/get" begin
    @test ca.a == 100.0
    @test ca.b == Float64[4, 1.3]
    @test ca.c.a.a == 1.0
    @test ca.c.a.b[1] == 1.0
    @test ca.c == CArray(c)
    @test_skip ca2.b[1].a.a == 20.0

    @test ca[:a] == ca.a
    @test ca[:b] == ca.b
    @test ca[:c] == ca.c

    @test cmat[:a, :a] == 10000.0
    @test cmat[:a, :b] == [400, 130]
    @test cmat[:c, :c] == CArray(a[4:10] .* a[4:10]', Axis(ax_c), Axis(ax_c))
    @test cmat[:c,:][:a,:][:a,:] == ca
    @test cmat[:a, :c] == cmat[:c, :a]
end

@testset "Similar/copy" begin
    @test typeof(similar(ca)) == typeof(ca)
    @test typeof(similar(ca, Float32)) == typeof(ca_Float32)
    @test eltype(similar(ca, ForwardDiff.Dual)) == ForwardDiff.Dual
    @test copy(ca) == ca
    @test deepcopy(ca) == ca
end

@testset "Broadcasting" begin
    @test Float32.(ca) == CArray{Float32}(nt)
    @test ca .* ca' == cmat
    @test 1 .* (ca .+ ca) == CArray(a .+ a)
    @test typeof(ca .+ cmat) == typeof(cmat)
end

@testset "Math" begin
    @test zeros(cmat) * ca == zeros(ca)
    @test ca * ca' == cmat
    @test ca * ca' == a * a'
    @test ca' * ca == a' * a
    @test cmat * ca == cmat * a
    @test cmat'' == cmat
    @test ca'' == ca
    @test ca.c' * cmat[:c,:c] * ca.c isa Number
    @test_skip ca' * 1 isa CVector
end


