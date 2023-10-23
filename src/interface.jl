"""
    is_variable(sys, sym)

Check whether the given `sym` is a variable in `sys`.
"""
function is_variable end

"""
    has_static_variable(sys)

Check whether the variables in `sys` are stable across time.
"""
function has_static_variable end

"""
    variable_index(sys, sym, [i])

Return the index of the given variable `sym` in `sys`, or `nothing` otherwise. If
[`has_static_variable`](@ref) is `false`, this accepts the current timestep as an
additional parameter `i`.
"""
function variable_index end

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
    is_independent_variable(sys, sym)

Check whether the given `sym` is an independent variable in `sys`.
"""
function is_independent_variable end

"""
    is_observed(sys, sym)

Check whether the given `sym` is an observed value in `sys`.
"""
function is_observed end

"""
    observed(sys, sym, [symbolic_states])

Return the observed function of the given `sym` in `sys`. The returned function should
have the signature `(u, p) -> [values...]` where `u` and `p` is the current state and
parameter vector. If `istimedependent(sys) == true`, the function should accept
the current time `t` as its third parameter. If `has_static_variable(sys) == false` then
`observed` must accept a third parameter `symbolic_states` indicating the order of symbolic
variables in `u`.

See also: [`is_time_dependent`](@ref), [`has_static_variable`](@ref)
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
