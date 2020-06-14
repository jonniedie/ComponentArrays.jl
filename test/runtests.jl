using ComponentArrays
using ForwardDiff
using StaticArrays
using Test


## Test setup
c = (a=(a=1, b=[1.0, 4.4]), b=[0.4, 2, 1, 45])
nt = (a=100, b=[4, 1.3], c=c)
nt2 = (a=5, b=[(a=(a=20,b=1), b=0), (a=(a=33,b=1), b=0)], c=(a=(a=2, b=[1,2]), b=[1., 2.]))

ax = Axis(a=1, b=2:3, c=ViewAxis(4:10, (a=ViewAxis(1:3, (a=1, b=2:3)), b=4:7)))
ax_c = (a=ViewAxis(1:3, (a=1, b=2:3)), b=4:7)

a = Float64[100, 4, 1.3, 1, 1, 4.4, 0.4, 2, 1, 45]
sq_mat = collect(reshape(1:9,3,3))

ca = ComponentArray(nt)
ca_Float32 = ComponentArray{Float32}(nt)
ca_MVector = ComponentArray{MVector{10}}(nt)
ca_composed = ComponentArray(a=1, b=ca)

ca2 = ComponentArray(nt2)

cmat = ComponentArray(a .* a', ax, ax)
cmat2 = ca2 .* ca2'

caa = ComponentArray(a=ca, b=sq_mat)

_a, _b, _c = fastindices(:a, :b, :c)


## Tests
@testset "Utilities" begin
    @test ComponentArrays.getval.(fastindices(:a, :b, :c)) == (:a, :b, :c)
    @test fastindices(:a, Val(:b)) == (Val(:a), Val(:b))
    @test ComponentArrays.partition(1:12, 3) == [[1,2,3], [4,5,6], [7,8,9], [10,11,12]]
end

@testset "Construction" begin
    @test ca == ComponentArray(a=100, b=[4, 1.3], c=(a=(a=1, b=[1.0, 4.4]), b=[0.4, 2, 1, 45]))
    @test ca_Float32 == ComponentArray(Float32.(a), ax)
    @test eltype(ComponentArray{ForwardDiff.Dual}(nt)) == ForwardDiff.Dual
    @test ca_composed.b isa ComponentArray
    @test ca_composed.b == ca
    @test getdata(ca_MVector) isa MArray
    @test typeof(ComponentArray(undef, (ax,))) == typeof(ca)
    @test typeof(ComponentArray(undef, (ax, ax))) == typeof(cmat)
    @test typeof(ComponentArray{Float32}(undef, (ax,))) == typeof(ca_Float32)
    @test typeof(ComponentArray{MVector{10,Float64}}(undef, (ax,))) == typeof(ca_MVector)

    @test ca == ComponentVector(a=100, b=[4, 1.3], c=(a=(a=1, b=[1.0, 4.4]), b=[0.4, 2, 1, 45]))
    @test cmat == ComponentMatrix(a .* a', ax, ax)
    @test_throws DimensionMismatch ComponentVector(sq_mat, ax)
    @test_throws DimensionMismatch ComponentMatrix(rand(11,11,11), ax, ax)

    # Issue #24
    @test ComponentVector(a=1, b=2f0) == ComponentVector{Float32}(a = 1.0, b = 2.0)
    @test ComponentVector(a=1, b=2+im) == ComponentVector{Complex{Int64}}(a = 1 + 0im, b = 2 + 1im)
end

@testset "Attributes" begin
    @test length(ca) == length(a)
    @test size(ca) == size(a)
    @test size(cmat) == (length(a), length(a))

    @test propertynames(ca) == (:a, :b, :c)
    @test propertynames(ca.c) == (:a, :b)

    @test parent(ca) == a
end

@testset "Get" begin
    @test getdata(ca) == a
    @test getdata(cmat) == a .* a'

    @test getaxes(ca) == (ax,)
    @test getaxes(cmat) == (ax, ax)

    @test ca[1] == a[1]
    @test ca[1:5] == a[1:5]
    @test cmat[:,:] == cmat
    # @test getaxes(cmat[:a,:]) == getaxes(ca)

    @test ca.a == 100.0
    @test ca.b == Float64[4, 1.3]
    @test ca.c.a.a == 1.0
    @test ca.c.a.b[1] == 1.0
    @test ca.c == ComponentArray(c)
    @test ca2.b[1].a.a == 20.0

    @test ca[:a] == ca.a
    @test ca[:b] == ca.b
    @test ca[:c] == ca.c

    @test cmat[:a, :a] == 10000.0
    @test cmat[:a, :b] == [400, 130]
    @test all(cmat[:c, :c] .== ComponentArray(a[4:10] .* a[4:10]', Axis(ax_c), Axis(ax_c)))
    @test cmat[:c,:][:a,:][:a,:] == ca
    @test cmat[:a, :c] == cmat[:c, :a]
    @test all(cmat2[:b, :b][1,1] .== ca2.b[1] .* ca2.b[1]')

    @test ca[_a] == ca[:a]
    @test cmat[_c,_b] == cmat[:c,:b]
    @test cmat[_c, :a] == cmat[:c, :a]

    @test ca2.b[2].a.a == 33

    @test collect(caa.b) == sq_mat
    @test size(caa.b) == size(sq_mat)
    @test caa.b[1:2, 3] == sq_mat[1:2, 3]
end

@testset "Set" begin
    temp = deepcopy(ca2)
    tempmat = deepcopy(cmat2)

    temp.c.a .= 1000

    tempmat[:b,:b][1,1][:a,:a][:a,:a] = 100000
    tempmat[:b,:a][2].b = 1000

    @test temp.c.a.a == 1000

    @test tempmat[:b,:b][1,1][:a,:a][:a,:a] == 100000
    @test tempmat[:b,:a][2].b == 1000

    tempmat .= 0
    @test tempmat[:b,:a][2].b == 0
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
    @test convert(typeof(ca), a) == ca
    @test convert(typeof(ca), ca) == ca
    @test convert(typeof(cmat), cmat) == cmat
end

@testset "Broadcasting" begin
    temp = deepcopy(ca)
    @test Float32.(ca) == ComponentArray{Float32}(nt)
    @test ca .* ca' == cmat
    @test 1 .* (ca .+ ca) == ComponentArray(a .+ a)
    @test typeof(ca .+ cmat) == typeof(cmat)
    @test getaxes(false .* ca .* ca') == (ax, ax)
    @test getaxes(false .* ca' .* ca) == (ax, ax)
    @test (vec(temp) .= vec(ca_Float32)) isa ComponentArray
    @test_skip getdata(ca_MVector .* ca_MVector) isa MArray
end

@testset "Math" begin
    @test zeros(cmat) * ca == zeros(ca)
    @test ca * ca' == collect(cmat)
    @test ca * ca' == a * a'
    @test ca' * ca == a' * a
    @test cmat * ca == cmat * a
    @test cmat'' == cmat
    @test ca'' == ca
    @test ca.c' * cmat[:c,:c] * ca.c isa Number
    @test ca * 1 isa CVector
    @test_skip ca' * 1 isa AdjointCVector

    vca2 = vcat(ca2', ca2')
    hca2 = hcat(ca2, ca2)
    @test all(vca2[1,:] .== ca2)
    @test all(hca2[:,1] .== ca2)
    @test all(vca2' .== hca2)
    @test hca2[:a,:] == vca2[:,:a]
end

@testset "Issues" begin
    # Issue #25
    @test sum(abs2, cmat) == sum(abs2, getdata(cmat))
end