using ComponentArrays
using ForwardDiff
using LabelledArrays
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

_a, _b, _c = Val.((:a, :b, :c))


## Tests
@testset "Utilities" begin
    @test_deprecated ComponentArrays.getval.(fastindices(:a, :b, :c)) == (:a, :b, :c)
    @test_deprecated fastindices(:a, Val(:b)) == (Val(:a), Val(:b))

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

    # Entry from Dict
    dict1 = Dict(:a=>rand(5), :b=>rand(5,5))
    dict2 = Dict(:a=>3, :b=>dict1)
    @test ComponentArray(dict1) isa ComponentArray
    @test ComponentArray(dict2).b isa ComponentArray

    @test ca == ComponentVector(a=100, b=[4, 1.3], c=(a=(a=1, b=[1.0, 4.4]), b=[0.4, 2, 1, 45]))
    @test cmat == ComponentMatrix(a .* a', ax, ax)
    @test_throws DimensionMismatch ComponentVector(sq_mat, ax)
    @test_throws DimensionMismatch ComponentMatrix(rand(11,11,11), ax, ax)
    @test_throws ErrorException ComponentArray(v=[(a=1, b=2), (a=3, c=4)])

    # Axis construction from symbols
    @test Axis([:a, :b, :c]) == Axis(a=1, b=2, c=3)
    @test Axis((:a, :b, :c)) == Axis(a=1, b=2, c=3)
    @test Axis(:a, :b, :c) == Axis(a=1, b=2, c=3)

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

    # Issue #61
    @test ComponentArray(x=1) isa ComponentArray{Int}

    # Issue #81
    @test ComponentArray() isa ComponentArray
    @test ComponentVector() isa ComponentVector
    @test ComponentMatrix() isa ComponentMatrix
    @test ComponentArray{Float32}() isa ComponentArray{Float32}
    @test ComponentVector{Float32}() isa ComponentVector{Float32}
    @test ComponentMatrix{Float32}() isa ComponentMatrix{Float32}
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

    @test ca != getdata(ca)
    @test getdata(ca) != ca
    @test hash(ca) != hash(getdata(ca))
    @test hash(ca, zero(UInt)) != hash(getdata(ca), zero(UInt))

    ab = ComponentArray(a=1, b=2)
    xy = ComponentArray(x=1, y=2)
    @test ab != xy
    @test hash(ab) != hash(xy)
    @test hash(ab, zero(UInt)) != hash(xy, zero(UInt))

    @test ab == LVector(a=1, b=2)
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

    @test Base.to_indices(ca, (:a, :b)) == (:a, :b)
    @test Base.to_indices(ca, (1, 2)) == (1, 2)
    @test Base.to_index(ca, :a) == :a

    #OffsetArray stuff
    part_ax = PartitionedAxis(2, Axis(a=1, b=2))
    oaca = ComponentArray(OffsetArray(collect(1:5), -1), Axis(a=0, b=ViewAxis(1:4, part_ax)))
    temp_ca = ComponentArray(collect(1:5), Axis(a=1, b=ViewAxis(2:5, part_ax)))
    @test oaca.a == temp_ca.a
    @test oaca.b[1].a == temp_ca.b[1].a
    @test oaca[0] == temp_ca[1]
    @test oaca[4] == temp_ca[5]
    @test axes(oaca) == axes(getdata(oaca))

    # Issue #56
    A = ComponentArray(rand(4, 10), Axis(a=1:2, b=3:4), FlatAxis())
    A_vec = A[:,1]
    A_mat = A[:,1:2]
    @test A_vec isa ComponentVector
    @test A_mat isa ComponentMatrix
    @test getdata(A_vec) isa Vector
    @test getdata(A_mat) isa Matrix

    # Issue #70
    let 
        ca = ComponentVector(a=1, b=2, c=3)
        @test_throws BoundsError ca[:a, :b]
    end

    # Issue # 87: Conversion/promotion
    let
        ax1 = Axis((; x1=1))
        ax2 = Axis((; x2=1))
        A1 = ComponentMatrix(zeros(1, 1), ax1, ax1)
        A2 = ComponentMatrix(zeros(1, 1), ax2, ax2)
        A = [A for A in [A1, A2]]
        @test A[1] == A1
        @test A[2] == A2
    end
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

    A = ComponentArray(zeros(Int,4,4), Axis(x=1:4), Axis(x=1:4))
    A[1,:] .= 1
    @test A[1,:] == ComponentVector(x=ones(Int,4))
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

    @test convert(Array, ca) == getdata(ca)
end

@testset "Broadcasting" begin
    temp = deepcopy(ca)
    @test eltype(Float32.(ca)) == Float32
    @test ca .* ca' == cmat
    @test 1 .* (ca .+ ca) == ComponentArray(a .+ a, getaxes(ca))
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

    @test map(sqrt, ca) isa ComponentArray
    @test map(+, ca, sqrt.(ca)) isa ComponentArray
    @test map(+, sqrt.(ca), Float32.(ca), ca) isa ComponentArray
    @test map(+, ca, getdata(ca)) isa Array
    @test map(+, ca, ComponentArray(v=getdata(ca))) isa Array

    x1 .+= x2
    @test getdata(x1) == 2getdata(x2)

    # Issue #60
    x4 = ComponentArray(rand(3,3), Axis(x=1, y=2, z=3), Axis(x=1, y=2, z=3))
    @test x4 + I(3) isa ComponentMatrix
end

@testset "Math" begin
    a_t = collect(a')

    @test ca * ca' == collect(cmat)
    @test ca * ca' == a * a'
    @test ca' * ca == a' * a
    @test cmat * ca == ComponentArray(cmat * a, getaxes(ca))
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
    @test ca' * cmat == ComponentArray(a' * getdata(cmat), getaxes(ca))
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
    @test [ca' ca']' isa Vector
    @test keys(getaxes([ca' temp']')[1]) == (:a, :b, :c, :q, :r)

    # Getting serious about axes
    let
        ab = ComponentArray(a=1, b=5)
        cd = ComponentArray(c=3, d=7)
        ab_ab = ab * ab'
        ab_cd = ab * cd'
        cd_ab = cd * ab'
        cd_cd = cd * cd'
        AB = Axis(a=1, b=2)
        CD = Axis(c=1, d=2)
        _AB = Axis(a=2, b=3)
        _CD = Axis(c=2, d=3)
        ABCD = Axis(a=1, b=2, c=3, d=4)
        CDAB = Axis(c=1, d=2, a=3, b=4)

        # Cats
        @test [ab_ab; ab_ab] isa Matrix
        @test [ab_ab; ab_cd] isa Matrix
        @test getaxes([ab_ab; cd_ab]) == (ABCD, AB)
        @test getaxes([ab_ab ab_cd]) == (AB, ABCD)
        @test getaxes([ab_ab ab_cd; cd_ab cd_cd]) == (ABCD, ABCD)
        @test getaxes([ab_ab ab_cd; cd_ab cd_cd]) == (ABCD, ABCD)
        @test getaxes([ab ab_cd]) == (AB, _CD)
        @test getaxes([ab_cd ab]) == (AB, CD)
        @test getaxes([ab'; cd_ab]) == (_CD, AB)
        @test getaxes([cd'; cd_ab']) == (_AB, CD)
        @test getaxes([cd'; cd_ab']) == (_AB, CD)

        # Math
        @test getaxes(ab_cd * cd) == (AB,)
        @test getaxes(cd_ab' * cd) == (AB,)
        @test getaxes(cd' * cd_ab) == (FlatAxis(), AB)
        @test getaxes(cd' * cd_ab') == (FlatAxis(), CD)
        @test getaxes(cd_ab' * cd_ab) == (AB, AB)
        @test getaxes(cd_ab' * ab_cd') == (AB, AB)
        @test getaxes(ab_cd * ab_cd') == (AB, AB)
    end

    # Issue #33
    smat = @SMatrix [1 2; 3 4]
    b = ComponentArray(a = 1, b = 2)
    @test smat*b isa StaticArray

    # Issue #86: Matrix multiplication
    in1 = ComponentArray(u1=1)
    in2 = ComponentArray(u2=1)
    out1 = ComponentArray(y1=1)
    out2 = ComponentArray(y2=1)
    s1_D = out1 * in1'
    s2_D = out2 * in2'
    @test getaxes(s1_D * s2_D) == (Axis(y1=1), Axis(u2=1))
    @test getaxes(s2_D * s1_D) == (Axis(y2=1), Axis(u1=1))
    @test getaxes((s1_D * s2_D) * in2) == getaxes(s1_D * (s2_D * in2)) == (Axis(y1=1),)
    @test getaxes((s2_D * s1_D) * in1) == getaxes(s2_D * (s1_D * in1)) == (Axis(y2=1),)
    @test getaxes(out1' * (s1_D * s2_D)) == getaxes(transpose(out1) * (s1_D * s2_D)) == (FlatAxis(), Axis(u2=1))
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

    # Issue #74
    lab2 = labels(ComponentArray(a=1, aa=ones(2), ab=[(a=1, aa=ones(2)), (a=1, aa=ones(2))], ac=(a=1, ab=ones(2,2))))
    @test label2index(lab2, "a") == [1]
    @test label2index(lab2, "aa") == collect(2:3)
    @test label2index(lab2, "ab") == collect(4:9)
    @test label2index(lab2, "ab[1].aa") == collect(5:6)
    @test label2index(lab2, "ac") == collect(10:14)
    @test label2index(lab2, "ac.a") == [10]
    @test label2index(lab2, "ac.ab") == collect(11:14)
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

@testset "Autodiff" begin include("autodiff_tests.jl") end