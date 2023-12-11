"""
    parameter_values(p)

Return an indexable collection containing the value of each parameter in `p`.
"""
function parameter_values end

"""
    getp(sys, p)

Return a function that takes an integrator or solution of `sys`, and returns the value of
the parameter `p`. Requires that the integrator or solution implement
[`parameter_values`](@ref).
"""
function getp(sys, p)
    symtype = symbolic_type(p)
    elsymtype = symbolic_type(eltype(p))
    if symtype != NotSymbolic()
        return _getp(sys, symtype, p)
    else
        return _getp(sys, elsymtype, p)
    end
end

function _getp(sys, ::NotSymbolic, p)
    return function getter(sol)
        return parameter_values(sol)[p]
    end
end

function _getp(sys, ::ScalarSymbolic, p)
    idx = parameter_index(sys, p)
    return function getter(sol)
        return parameter_values(sol)[idx]
    end
end

function _getp(sys, ::ScalarSymbolic, p::Union{Tuple, AbstractArray})
    idxs = parameter_index.((sys,), p)
    return function getter(sol)
        return getindex.((parameter_values(sol),), idxs)
    end
end

function _getp(sys, ::ArraySymbolic, p)
    return getp(sys, collect(p))
end

"""
    setp(sys, p)

Return a function that takes an integrator of `sys` and a value, and sets the
the parameter `p` to that value. Requires that the integrator implement
[`parameter_values`](@ref) and the returned collection be a mutable reference
to the parameter vector in the integrator.
"""
function setp(sys, p)
    symtype = symbolic_type(p)
    elsymtype = symbolic_type(eltype(p))
    if symtype != NotSymbolic()
        return _setp(sys, symtype, p)
    else
        return _setp(sys, elsymtype, p)
    end
end

function _setp(sys, ::NotSymbolic, p)
    return function setter!(sol, val)
        parameter_values(sol)[p] = val
    end
end

function _setp(sys, ::ScalarSymbolic, p)
    idx = parameter_index(sys, p)
    return function setter!(sol, val)
        parameter_values(sol)[idx] = val
    end
end

function _setp(sys, ::ScalarSymbolic, p::Union{Tuple, AbstractArray})
    idxs = parameter_index.((sys,), p)
    return function setter!(sol, val)
        setindex!.((parameter_values(sol),), val, idxs)
    end
end

function _setp(sys, ::ArraySymbolic, p)
    return setp(sys, collect(p))
end
