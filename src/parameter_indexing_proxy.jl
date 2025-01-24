"""
    struct ParameterIndexingProxy

This struct wraps any struct implementing the value provider and index provider interfaces.
It allows `getindex` and `setindex!` operations to get/set parameter values. Requires that
the wrapped type support [`getp`](@ref) and [`setp`](@ref) for getting and setting
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

function Base.show(io::IO, pip::ParameterIndexingProxy; kwargs...)
    params = Any[]
    vals = Any[]
    for p in parameter_symbols(pip.wrapped)
        push!(params, p)
        val = getp(pip.wrapped, p)(pip.wrapped)
        push!(vals, val)
    end

    print(
          Table([params vals]; 
                box=:SIMPLE, 
                header=["Parameter", "Value"], 
                kwargs...)
         )
end
