# ComponentArrays.jl NEWS
Notes on new features (minor releases). For more details on bugfixes and non-feature-adding changes (patch releases), check out the [releases page](https://github.com/jonniedie/ComponentArrays.jl/releases).

### v0.7.0
- Much faster (and lazier) arrays of subcomponents!
```julia
julia> ca = ComponentArray(a=5, b=(a=zeros(4,4), b=0), c=(a=[(a=1, b=2), (a=3, b=1), (a=1, b=2), (a=3, b=1)], b=[1., 2., 4]));

julia> @btime sum(x.a + x.b for x in $ca.c.a);
  127.160 ns (2 allocations: 480 bytes)

julia> @btime sum(x.a + x.b for x in $ca.c.a);
  36.895 ns (0 allocations: 0 bytes)
```

### v0.6.0
- Easier DifferentialEquations plotting!
    - Automatic legend labeling!
    - `Symbol` and `String` support for the `vars` plot keyword!
    - See it in an action [here](https://github.com/jonniedie/ComponentArrays.jl/blob/master/docs/src/examples/adaptive_control.md)!

### v0.5.0
- Constructor for making new `ComponentVector`s with additional fields! Watch out, it's slow!
```julia
julia> x = ComponentArray(a=5, b=[1, 2])
ComponentVector{Int64}(a = 5, b = [1, 2])

julia> moar_x = ComponentArray(x; c=zeros(2,2), d=(a=2, b=10))
ComponentVector{Int64}(a = 5, b = [1, 2], c = [0 0; 0 0], d = (a = 2, b = 10))
```

### v0.4.0
- Zygote rules for DiffEqFlux support! Check out [the docs](https://jonniedie.github.io/ComponentArrays.jl/dev/examples/DiffEqFlux/) for an example!

### v0.3.0
- Matrix and higher-dimensional array components!

...and plenty more!
