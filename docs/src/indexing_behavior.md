# Indexing Behavior

## Views and slices
`ComponentArray`s slice, rather than view, when indexing. This catches some people by surprise when they are trying to use indexing on `ComponentVector`s for dynamic field access. Let's look at an example. We'll make a `ComponentVector` with a nested structure.
```julia
julia> using ComponentArrays

julia> ca = ComponentArray(a=5, b=[4, 1])
ComponentVector{Int64}(a = 5, b = [4, 1])
```
Using dot notation, we can access and change properties as if `ca` was a regular `struct` or `NamedTuple`.
```julia
julia> ca.b[1] = 99;

julia> ca.a = 22;

julia> ca
ComponentVector{Int64}(a = 22, b = [99, 1])
```
Now let's try with indexing:
```julia
julia> ca[:b][1] = 0
0

julia> ca[:a] = 0

julia> ca
ComponentVector{Int64}(a = 0, b = [99, 1])
```
We see that the `a` field changed but the `b` field didn't. When we did `ca[:b]`, it sliced into `ca`, thus creating a copy that would not update the original when we went to set the first element to `0`. On the other hand, since the update of the `a` field calls `setindex!` which updates in-place.

If viewing, rather than slicing, is the desired behavior, use the `@view` macro or `view` function:
```julia
julia> @view(ca[:b])[1] = 0

julia> ca
ComponentVector{Int64}(a = 0, b = [0, 1])
```

## Retaining component labels through index operations
Sometimes you might want to index into a `ComponentArray` without dropping the component name. Let's look at a new example with a more deeply nested structure:
```julia
julia> ca = ComponentArray(a=5, b=[4, 1], c=(a=2, b=[6, 30]))
ComponentVector{Int64}(a = 5, b = [4, 1], c = (a = 2, b = [6, 30]))
```
If we wanted to get the `b` component while keeping the name, we can use the `KeepIndex` wrapper around our index:
```julia
julia> ca[KeepIndex(:b)]
ComponentVector{Int64}(b = [4, 1])
```
Now instead of just returning a plain `Vector`, this returns a `ComponentVector` that keeps the `b` name. Of course, this is still compatible with `view`s, so we could have done `@view ca[KeepIndex(:b)]` if we wanted to retain the view into the origianl.

Similarly, we can use plain indexes like ranges or integers and they will keep the names of any components they capture:
```julia
julia> ca[KeepIndex(1)]
ComponentVector{Int64}(a = 5)

julia> ca[KeepIndex(2:3)]
ComponentVector{Int64}(b = [4, 1])

julia> ca[KeepIndex(1:3)]
ComponentVector{Int64}(a = 5, b = [4, 1])

julia> ca[KeepIndex(2:end)]
ComponentVector{Int64}(b = [4, 1], c = (a = 2, b = [6, 30]))
```
But what if our range doesn't capture a full component? We can see below that using `KeepIndex` on the first five elements returns a `ComponentVector` with those elements but only the `a` and `b` names, since the `c` component wasn't fully captured. 
```julia
julia> ca[KeepIndex(1:5)]
5-element ComponentVector{Int64} with axis Axis(a = 1, b = 2:3):
 5
 4
 1
 2
 6
```