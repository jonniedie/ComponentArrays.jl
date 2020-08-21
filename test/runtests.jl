using ComponentArrays
using ForwardDiff
using LinearAlgebra
using StaticArrays
using OffsetArrays
using Test
using Unitful


## Test setup
c = (a=(a=1, b=[1.0, 4.4]), b=[0.4, 2, 1, 45])
nt = (a=100, b=[4, 1.3], c=c)
nt2 = (a=5, b=[(a=(a=20,b=1), b=0), (a=(a=33,b=1), b=0)], c=(a=(a=2, b=[1,2]), b=[1. 2.; 5 6]))

ax = Axis(a=1, b=2:3, c=ViewAxis(4:10, (a=ViewAxis(1:3, (a=1, b=2:3)), b=4:7)))
ax_c = (a=ViewAxis(1:3, (a=1, b=2:3)), b=4:7)

a = Float64[100, 4, 1.3, 1, 1, 4.4, 0.4, 2, 1, 45]
sq_mat = collect(reshape(1:9,3,3))

ca = ComponentArray(nt)
ca_Float32 = ComponentArray{Float32}(nt)
ca_MVector = ComponentArray{MVector{10}}(nt)
ca_SVector = ComponentArray{SVector{10}}(nt)
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
    @test fastindices(("a", Val(:b))) == (Val(:a), Val(:b))

    @test collect(ComponentArrays.partition(collect(1:12), 3)) == [[1,2,3], [4,5,6], [7,8,9], [10,11,12]]
    @test size(collect(ComponentArrays.partition(zeros(2,2,2), 1, 2, 2))[2,1,1]) == (1, 2, 2)
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

    # Issue #23
    sz = size(ca)
    temp = ComponentArray(ca; d=100)
    temp2 = ComponentVector(temp; d=4)
    temp3 = ComponentArray(temp2; e=(a=20, b=[2 4; 1 4]))
    @test sz == size(ca)
    @test temp.d == 100
    @test temp2.d == 4
    @test !haskey(ca, :d)
    @test all(temp3.e.b .== [2 4; 1 4])

    # Issue #18
    temp_miss = ComponentArray(a=missing, b=[2, 1, 4, 5], c=[1, 2, 3])
    @test eltype(temp_miss) == Union{Int64, Missing}
    @test temp_miss.a === missing
    temp_noth = ComponentArray(a=nothing, b=[2, 1, 4, 5], c=[1, 2, 3])
    @test eltype(temp_noth) == Union{Int64, Nothing}
    @test temp_noth.a === nothing
end

@testset "Attributes" begin
    @test length(ca) == length(a)
    @test size(ca) == size(a)
    @test size(cmat) == (length(a), length(a))

    @test propertynames(ca) == (:a, :b, :c)
    @test propertynames(ca.c) == (:a, :b)

    @test parent(ca) == a

    @test keys(ca) == (:a, :b, :c)
    @test valkeys(ca) == Val.((:a, :b, :c))
end

@testset "Get" begin
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
    @test ca.c == ComponentArray(c)
    @test ca2.b[1].a.a == 20.0

    @test ca[:a] == ca["a"] == ca.a
    @test ca[:b] == ca["b"] == ca.b
    @test ca[:c] == ca["c"] == ca.c

    @test cmat[:a, :a] == cmat["a", "a"] == 10000.0
    @test cmat[:a, :b] == cmat["a", "b"] == [400, 130]
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

    @test view(ca, :a) == ca.a
    @test cmat[:c, :a] == view(cmat, :c, :a)

    @test ca[CartesianIndex(1)] == ca[1]
    @test cmat[CartesianIndex(1, 2)] == cmat[1, 2]

    @test getproperty(ca, Val(:a)) == ca.a

    #OffsetArray stuff
    part_ax = PartitionedAxis(2, Axis(a=1, b=2))
    oaca = ComponentArray(OffsetArray(collect(1:5), -1), Axis(a=0, b=ViewAxis(1:4, part_ax)))
    temp_ca = ComponentArray(collect(1:5), Axis(a=1, b=ViewAxis(2:5, part_ax)))
    @test oaca.a == temp_ca.a
    @test oaca.b[1].a == temp_ca.b[1].a
    @test oaca[0] == temp_ca[1]
    @test oaca[4] == temp_ca[5]
    @test axes(oaca) == axes(getdata(oaca))
end

@testset "Set" begin
    temp = deepcopy(ca2)
    tempmat = deepcopy(cmat2)

    temp.c.a .= 1000

    tempmat[:b,:b][1,1][:a,:a][:a,:a] = 100000
    tempmat[:b,:a][2].b = 1000

    @test temp.c.a.a == 1000

    @test tempmat["b","b"][1,1]["a",:a][:a,:a] == 100000
    @test tempmat[:b,:a][2].b == 1000
    
    temp2 = deepcopy(ca)
    temp3 = deepcopy(ca_MVector)
    @test (temp2 .= ca .* 1) isa ComponentArray
    @test (temp2 .= temp2 .* a .+ 1) isa typeof(temp2)
    @test (temp2 .= ca .* ca_SVector) isa typeof(temp2)
    @test (temp3 .= ca .* ca_SVector) isa typeof(temp3)

    temp2.b = ca.b .+ 1
    @test temp2.b == ca.b .+ 1

    setproperty!(temp2, :a, 20)
    @test temp2.a == 20

    setproperty!(temp2, Val(:b), zeros(2))
    @test temp2.b == zeros(2)

    tempmat .= 0
    @test tempmat[:b,:a][2].b == 0

    temp = deepcopy(cmat)
    @test all((temp[:c,:c][:a,:a] .= 0) .== 0)
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
    @test getdata(ca_MVector .* ca_MVector) isa MArray
    
    @test typeof(ca .* ca_MVector) == typeof(ca)
    @test typeof(ca_SVector .* ca) == typeof(ca)
    @test typeof(ca_SVector .* ca_SVector) == typeof(ca_SVector)
    @test typeof(ca_SVector .* ca_MVector) == typeof(ca_SVector)
    @test typeof(ca_SVector' .+ ca) == typeof(cmat)
    @test getdata(ca_SVector' .+ ca_SVector') isa StaticArrays.StaticArray
    @test getdata(ca_SVector .* ca_SVector') isa StaticArrays.StaticArray
    @test ca_SVector .* ca .+ a .- 1 isa ComponentArray

    # Issue #31 (with Complex as a stand-in for Dual)
    @test reshape(Complex.(ca, Float32.(a)), size(ca)) isa ComponentArray{Complex{Float64}}

    # Issue #34 : Different Axis types
    x1 = ComponentArray(a=[1.1,2.1], b=[0.1])
    x2 = ComponentArray(a=[1.1,2.1], b=0.1)
    x3 = ComponentArray(a=[1.1,2.1], c=[0.1])
    xmat = x1 .* x2'
    x1mat = x1 .* x1'
    @test x1 + x2 isa Vector
    @test x1 + x3 isa Vector
    @test x2 + x3 isa Vector
    @test x1 .* x2 isa Vector
    @test xmat + x1mat isa ComponentArray
    @test xmat isa ComponentArray
    @test getaxes(xmat) == (getaxes(x1)[1], getaxes(x2)[1])
    @test getaxes(x1mat + xmat) == (getaxes(x1)[1], FlatAxis())
    @test getaxes(x1mat + xmat') == (FlatAxis(), getaxes(x1)[1])

    x1 .+= x2
    @test getdata(x1) == 2getdata(x2)
end

@testset "Math" begin
    a_t = collect(a')

    @test ca * ca' == collect(cmat)
    @test ca * ca' == a * a'
    @test ca' * ca == a' * a
    @test cmat * ca == cmat * a
    @test cmat' * ca isa AbstractArray
    @test a' * ca isa Number
    @test cmat'' == cmat
    @test ca'' == ca
    @test ca.c' * cmat[:c,:c] * ca.c isa Number
    @test ca * 1 isa ComponentVector
    @test size(ca' * 1) == size(ca')
    @test a' * ca isa Number
    @test a_t * ca isa AbstractArray
    @test a' * cmat isa Adjoint
    @test a_t * cmat isa AbstractArray
    @test cmat * ca isa AbstractVector
    @test ca + ca + ca isa typeof(ca)
    @test a + ca + ca isa typeof(ca)
    @test a*ca' isa AbstractMatrix
    
    @test ca * transpose(ca) == collect(cmat)
    @test ca * transpose(ca) == a * transpose(a)
    @test transpose(ca) * ca == transpose(a) * a
    @test cmat * ca == cmat * a
    @test transpose(transpose(cmat)) == cmat
    @test transpose(transpose(ca)) == ca
    @test transpose(ca.c) * cmat[:c,:c] * ca.c isa Number
    @test size(transpose(ca) * 1) == size(transpose(ca))
    @test transpose(a)*ca isa Number
    @test transpose(a)*cmat isa Transpose
    @test a*transpose(ca) isa AbstractMatrix

    temp = deepcopy(ca)
    temp .= (cmat+I) \ ca
    @test temp isa ComponentArray
    @test (ca' / (cmat'+I))' == (cmat+I) \ ca
    @test cmat * ((cmat+I) \ ca) isa AbstractArray
    @test inv(cmat+I) isa AbstractArray

    tempmat = deepcopy(cmat)
    
    @test ldiv!(temp, lu(cmat+I), ca) isa ComponentVector
    @test ldiv!(getdata(temp), lu(cmat+I), ca) isa AbstractVector
    @test ldiv!(tempmat, lu(cmat+I), cmat) isa ComponentMatrix
    @test ldiv!(getdata(tempmat), lu(cmat+I), cmat) isa AbstractMatrix

    vca2 = vcat(ca2', ca2')
    hca2 = hcat(ca2, ca2)
    temp = ComponentVector(q=100, r=rand(3,3,3))
    vtempca = [temp; ca]
    @test all(vca2[1,:] .== ca2)
    @test all(hca2[:,1] .== ca2)
    @test all(vca2' .== hca2)
    @test hca2[:a,:] == vca2[:,:a]
    @test vtempca isa ComponentVector
    @test vtempca.r == temp.r
    @test vtempca.c == ca.c
    @test length(vtempca) == length(temp) + length(ca)
    @test [ca; ca; ca] isa Vector
    @test vcat(ca, 100) isa Vector

    # Issue #33
    smat = @SMatrix [1 2; 3 4]
    b = ComponentArray(a = 1, b = 2)
    @test smat*b isa StaticArray
end

@testset "Plot Utilities" begin
    lab = labels(ca2)
    @test lab == [
        "a",
        "b[1].a.a",
        "b[1].a.b",
        "b[1].b",
        "b[2].a.a",
        "b[2].a.b",
        "b[2].b",
        "c.a.a",
        "c.a.b[1]",
        "c.a.b[2]",
        "c.b[1,1]",
        "c.b[2,1]",
        "c.b[1,2]",
        "c.b[2,2]",
    ]
    @test label2index(ca2, "c.b") == collect(11:14)
end

@testset "Uncategorized Issues" begin
    # Issue #25
    @test sum(abs2, cmat) == sum(abs2, getdata(cmat))

    # Issue #40
    r0 = [1131.340, -2282.343, 6672.423]u"km"
    v0 = [-5.64305, 4.30333, 2.42879]u"km/s"
    rv0 = ComponentArray(r=r0, v=v0)
    zrv0 = zero(rv0)
    @test all(zero(cmat) * ca .== zero(ca))
    @test typeof(zrv0) === typeof(rv0)
    @test typeof(zrv0.r[1]) == typeof(rv0[1])
end
