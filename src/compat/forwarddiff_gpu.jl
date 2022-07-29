function Base.copyto!(dest::GPUComponentArray, src::ForwardDiff.Partials)
    copyto!(getdata(dest), collect(src))
    return dest
end
