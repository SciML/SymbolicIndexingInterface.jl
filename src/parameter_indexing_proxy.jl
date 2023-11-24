"""
    parameter_values(p)

Return an indexable collection containing the value of each parameter in `p`.
"""
function parameter_values end

"""
    struct ParameterIndexingProxy end
    ParameterIndexingProxy(p)

A wrapper struct that allows symbolic indexing of parameters. The wrapped object `p`
must implement [`symbolic_container`](@ref) and [`parameter_values`](@ref). Indexing
of parameters using numeric indices is also permitted.
"""
struct ParameterIndexingProxy{T}
    wrapped::T
end

function Base.getindex(p::ParameterIndexingProxy, args...)
    symtype = symbolic_type(first(args))
    elsymtype = symbolic_type(eltype(first(args)))

    if symtype != NotSymbolic()
        getindex(p, symtype, args...)
    else
        getindex(p, elsymtype, args...)
    end
end

function Base.getindex(p::ParameterIndexingProxy, ::NotSymbolic, args)
    parameter_values(p.wrapped)[args...]
end

function Base.getindex(p::ParameterIndexingProxy, ::ScalarSymbolic, sym)
    sc = symbolic_container(p.wrapped)
    if is_parameter(sc, sym)
        return parameter_values(p.wrapped)[parameter_index(sc, sym)]
    end
    error("Parameter indexing error: $sym is not a parameter")
end

function Base.getindex(p::ParameterIndexingProxy, ::ScalarSymbolic, sym::Union{AbstractArray,Tuple})
    return getindex.((p,), sym)
end

function Base.getindex(p::ParameterIndexingProxy, ::ArraySymbolic, sym)
    return getindex(p, collect(sym))
end