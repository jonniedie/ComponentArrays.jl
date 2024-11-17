module ComponentArraysKernelAbstractionsExt

using ComponentArrays: ComponentArrays, ComponentArray
using KernelAbstractions: KernelAbstractions, @kernel, @index

KernelAbstractions.backend(x::ComponentArray) = KernelAbstractions.backend(getdata(x))

@kernel function ca_fill_kernel!(A, @Const(x))
    idx = @index(Global, Linear)
    @inbounds A[idx] = x
end

function ComponentArrays.fill_componentarray_ka!(A::ComponentArray{T}, x) where {T}
    kernel! = ca_fill_kernel!(KernelAbstractions.get_backend(A))
    kernel!(A, x; ndrange=length(A))
    return A
end

end
