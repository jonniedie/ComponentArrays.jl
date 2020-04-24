using ComponentArrays
using ForwardDiff
using Test


## Test setup
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

_a, _b, _c = fastindices(:a, :b, :c)


## Tests
@testset "Construction" begin
    @test ca == CArray(a=100, b=[4, 1.3], c=(a=(a=1, b=[1.0, 4.4]), b=[0.4, 2, 1, 45]))
    @test ca_Float32 == CArray(Float32.(a), ax)
    @test eltype(CArray{ForwardDiff.Dual}(nt)) == ForwardDiff.Dual
    @test ca_composed.b isa CArray
    @test ca_composed.b == ca
end

@testset "Attributes" begin
    @test length(ca) == length(a)
    @test size(ca) == size(a)
    @test size(cmat) == (length(a), length(a))

    @test propertynames(ca) == (:a, :b, :c)
    @test propertynames(ca.c) == (:a, :b)

    @test parent(ca) == a
end

@testset "Set/get" begin
    @test getdata(ca) == a
    @test getdata(cmat) == a .* a'

    @test getaxes(ca) == (ax,)
    @test getaxes(cmat) == (ax, ax)

    @test ca[1] == a[1]
    @test ca[1:5] == a[1:5]
    @test cmat[:,:] == cmat
    @test getaxes(cmat[:a,:]) == getaxes(ca)

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

    @test ca[_a] == ca[:a]
    @test cmat[_c,_b] == cmat[:c,:b]
    @test cmat[_c, :a] == cmat[:c, :a]
end

@testset "Similar" begin
    @test typeof(similar(ca)) == typeof(ca)
    @test typeof(similar(ca2)) == typeof(ca2)
    @test typeof(similar(ca, Float32)) == typeof(ca_Float32)
    @test eltype(similar(ca, ForwardDiff.Dual)) == ForwardDiff.Dual
end

@testset "Copy" begin
    @test copy(ca) == ca
    @test deepcopy(ca) == ca
end

@testset "Convert" begin
    @test NamedTuple(ca) == nt
    @test NamedTuple(ca.c) == c
end

@testset "Broadcasting" begin
    @test Float32.(ca) == CArray{Float32}(nt)
    @test ca .* ca' == cmat
    @test 1 .* (ca .+ ca) == CArray(a .+ a)
    @test typeof(ca .+ cmat) == typeof(cmat)
    @test getaxes(false .* ca .* ca') == (ax, ax)
    @test getaxes(false .* ca' .* ca) == (ax, ax)
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
    @test ca * 1 isa CVector
    @test_skip ca' * 1 isa AdjointCVector
end

@testset "Utilities" begin
    @test ComponentArrays.getval.(fastindices(:a, :b, :c)) == (:a, :b, :c)
    @test fastindices(:a, Val(:b)) == (Val(:a), Val(:b))
end