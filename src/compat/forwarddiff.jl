function Base.copyto!(dest::GPUComponentArray, src::ForwardDiff.Partials{N,V}) where {N,V}
    copyto!(getdata(dest), collect(src))
    return dest
end
