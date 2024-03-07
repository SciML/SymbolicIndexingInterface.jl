"""
    struct ParameterIndexingProxy

This struct wraps any struct implementing the symbolic indexing interface. It allows
`getindex` and `setindex!` operations to get/set parameter values. Requires that the
wrapped type support [`getp`](@ref) and [`setp`](@ref) for getting and setting
parameter values respectively.
"""
struct ParameterIndexingProxy{T}
    wrapped::T
end

function Base.getindex(p::ParameterIndexingProxy, idx, args...)
    getp(p.wrapped, idx)(p.wrapped, args...)
end

function Base.setindex!(p::ParameterIndexingProxy, val, idx)
    return setp(p.wrapped, idx)(p.wrapped, val)
end
