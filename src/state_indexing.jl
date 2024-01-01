"""
    state_values(p)

Return an indexable collection containing the values of all states in the integrator or
problem `p`.
"""
function state_values end

"""
    current_time(p)

Return the current time in the integrator or problem `p`.
"""
function current_time end

"""
    getu(sys, sym)

Return a function that takes an integrator or problem of `sys`, and returns the value of
the symbolic `sym`. `sym` can be a direct index into the state vector, a symbolic state,
a symbolic expression involving symbolic quantities in the system `sys`, or an
array/tuple of the aforementioned.

At minimum, this requires that the integrator or problem implement [`state_values`](@ref).
To support symbolic expressions, the integrator or problem must implement
[`observed`](@ref), [`parameter_values`](@ref) and [`current_time`](@ref).

This function typically does not need to be implemented, and has a default implementation
relying on the above functions.
"""
function getu(sys, sym)
    symtype = symbolic_type(sym)
    elsymtype = symbolic_type(eltype(sym))

    if symtype != NotSymbolic()
        _getu(sys, symtype, sym)
    else
        _getu(sys, elsymtype, sym)
    end
end

function _getu(sys, ::NotSymbolic, sym)
    return function getter(prob)
        return state_values(prob)[sym] 
    end
end

function _getu(sys, ::ScalarSymbolic, sym)
    if is_variable(sys, sym)
        idx = variable_index(sys, sym)
        return function getter1(prob)
            return state_values(prob)[idx]
        end
    elseif is_observed(sys, sym)
        fn = observed(sys, sym)
        if is_time_dependent(sys)
            function getter2(prob)
                return fn(state_values(prob), parameter_values(prob), current_time(prob))
            end
        else
            function getter3(prob)
                return fn(state_values(prob), parameter_values(prob))
            end
        end
    end
    error("Invalid symbol $sym for `getu`")
end

function _getu(sys, ::ScalarSymbolic, sym::Union{<:Tuple,<:AbstractArray})
    getters = getu.((sys,), sym)
    _call(getter, prob) = getter(prob)
    return function getter(prob)
        return _call.(getters, (prob,))
    end
end

function _getu(sys, ::ArraySymbolic, sym)
    return getu(sys, collect(sym))
end

"""
    setu(sys, sym)

Return a function that takes an integrator or problem of `sys` and a value, and sets the
the state `sym` to that value. Note that `sym` can be a direct numerical index, a symbolic state, or an array/tuple of the aforementioned.

Requires that the integrator implement [`state_values`](@ref) and the
returned collection be a mutable reference to the state vector in the integrator/problem.
In case `state_values` cannot return such a mutable reference, `setu` needs to be
implemented manually.
"""
function setu(sys, sym)
    symtype = symbolic_type(sym)
    elsymtype = symbolic_type(eltype(sym))

    if symtype != NotSymbolic()
        _setu(sys, symtype, sym)
    else
        _setu(sys, elsymtype, sym)
    end
end

function _setu(sys, ::NotSymbolic, sym)
    return function setter!(prob, val)
        state_values(prob)[sym] = val
    end
end

function _setu(sys, ::ScalarSymbolic, sym)
    is_variable(sys, sym) || error("Invalid symbol $sym for `setu`")
    idx = variable_index(sys, sym)
    return function setter!(prob, val)
        state_values(prob)[idx] = val
    end
end

function _setu(sys, ::ScalarSymbolic, sym::Union{<:Tuple,<:AbstractArray})
    setters = setu.((sys,), sym)
    _call!(setter!, prob, val) = setter!(prob, val)
    return function setter!(prob, val)
        _call!.(setters, (prob,), val)
    end
end

function _setu(sys, ::ArraySymbolic, sym)
    return setu(sys, collect(sym))
end
