"""
    is_variable(sys, sym)

Check whether the given `sym` is a variable in `sys`.
"""
function is_variable end

"""
    variable_index(sys, sym, [i])

Return the index of the given variable `sym` in `sys`, or `nothing` otherwise. If
[`constant_structure`](@ref) is `false`, this accepts the current time index as an
additional parameter `i`.
"""
function variable_index end

"""
    variable_symbols(sys, [i])

Return a vector of the symbolic variables being solved for in the system `sys`. If
`constant_structure(sys) == false` this accepts an additional parameter indicating
the current time index. The returned vector should not be mutated.
"""
function variable_symbols end

"""
    is_parameter(sys, sym)

Check whether the given `sym` is a parameter in `sys`.
"""
function is_parameter end

"""
    parameter_index(sys, sym)

Return the index of the given parameter `sym` in `sys`, or `nothing` otherwise.
"""
function parameter_index end

"""
    parameter_symbols(sys)

Return a vector of the symbolic parameters of the given system `sys`. The returned
vector should not be mutated.
"""
function parameter_symbols end

"""
    is_independent_variable(sys, sym)

Check whether the given `sym` is an independent variable in `sys`. The returned vector
should not be mutated.
"""
function is_independent_variable end

"""
    independent_variable_symbols(sys)

Return a vector of the symbolic independent variables of the given system `sys`.
"""
function independent_variable_symbols end

"""
    is_observed(sys, sym)

Check whether the given `sym` is an observed value in `sys`.
"""
function is_observed end

"""
    observed(sys, sym, [states])

Return the observed function of the given `sym` in `sys`. The returned function should
have the signature `(u, p) -> [values...]` where `u` and `p` is the current state and
parameter vector. If `istimedependent(sys) == true`, the function should accept
the current time `t` as its third parameter. If `constant_structure(sys) == false`,
accept a third parameter which can either be a vector of symbols indicating the order
of states or a time index which identifies the order of states.

See also: [`is_time_dependent`](@ref), [`constant_structure`](@ref)
"""
function observed end

"""
    is_time_dependent(sys)

Check if `sys` has time as (one of) its independent variables.
"""
function is_time_dependent end

"""
    constant_structure(sys)

Check if `sys` has a constant structure. Constant structure systems do not change the
number of variables or parameters over time.
"""
function constant_structure end
