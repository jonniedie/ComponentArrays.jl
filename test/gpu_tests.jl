using JLArrays

JLArrays.allowscalar(false)

jla = jl(collect(1:4))
jlca = ComponentArray(jla, Axis(a=1:2, b=3:4))

@testset "Broadcasting" begin
    @test identity.(jlca + jla) ./ 2 == jlca

    @test getdata(map(identity, jlca)) isa JLArray
    @test all(==(0), map(-, jlca, jla))
    @test all(map(-, jlca, jlca) .== 0)
    @test all(==(0), map(-, jla, jlca))

    @test any(==(1), jlca)
    @test count(>(2), jlca) == 2

    # Make sure mapreducing multiple arrays works
    @test mapreduce(==, +, jlca, jla) == 4
    @test mapreduce(abs2, +, jlca) == 30

    @test all(map(sin, jlca) .== sin.(jlca) .== sin.(jla) .≈ sin.(1:4))
end

@testset "adapt" begin
    x = [1 2; 3 4]
    jlx = JLArrays.Adapt.adapt(typeof(jlca), x)
    @test jlx isa JLArray
end
