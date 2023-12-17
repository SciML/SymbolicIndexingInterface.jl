"""
    symbolic_container(p)

Using `p`, return an object that implements the symbolic indexing interface. In case `p`
itself implements the interface, `p` can be returned as-is. All symbolic indexing interface
methods fall back to calling the same method on `symbolic_container(p)`, so this may be
used for trivial implementations of the interface that forward all calls to another object.

This is also used by [`ParameterIndexingProxy`](@ref)
"""
function symbolic_container end

"""
    is_variable(sys, sym)

Check whether the given `sym` is a variable in `sys`.
"""
is_variable(sys, sym) = is_variable(symbolic_container(sys), sym)

"""
    variable_index(sys, sym, [i])

Return the index of the given variable `sym` in `sys`, or `nothing` otherwise. If
[`constant_structure`](@ref) is `false`, this accepts the current time index as an
additional parameter `i`.
"""
variable_index(sys, sym) = variable_index(symbolic_container(sys), sym)
variable_index(sys, sym, i) = variable_index(symbolic_container(sys), sym, i)

"""
    variable_symbols(sys, [i])

Return a vector of the symbolic variables being solved for in the system `sys`. If
`constant_structure(sys) == false` this accepts an additional parameter indicating
the current time index. The returned vector should not be mutated.
"""
variable_symbols(sys) = variable_symbols(symbolic_container(sys))
variable_symbols(sys, i) = variable_symbols(symbolic_container(sys), i)

"""
    is_parameter(sys, sym)

Check whether the given `sym` is a parameter in `sys`.
"""
is_parameter(sys, sym) = is_parameter(symbolic_container(sys), sym)

"""
    parameter_index(sys, sym)

Return the index of the given parameter `sym` in `sys`, or `nothing` otherwise.
"""
parameter_index(sys, sym) = parameter_index(symbolic_container(sys), sym)

"""
    parameter_symbols(sys)

Return a vector of the symbolic parameters of the given system `sys`. The returned
vector should not be mutated.
"""
parameter_symbols(sys) = parameter_symbols(symbolic_container(sys))

"""
    is_independent_variable(sys, sym)

Check whether the given `sym` is an independent variable in `sys`. The returned vector
should not be mutated.
"""
is_independent_variable(sys, sym) = is_independent_variable(symbolic_container(sys), sym)

"""
    independent_variable_symbols(sys)

Return a vector of the symbolic independent variables of the given system `sys`.
"""
independent_variable_symbols(sys) = independent_variable_symbols(symbolic_container(sys))

"""
    is_observed(sys, sym)

Check whether the given `sym` is an observed value in `sys`.
"""
is_observed(sys, sym) = is_observed(symbolic_container(sys), sym)

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
observed(sys, sym) = observed(symbolic_container(sys), sym)
observed(sys, sym, states) = observed(symbolic_container(sys), sym, states)

"""
    is_time_dependent(sys)

Check if `sys` has time as (one of) its independent variables.
"""
is_time_dependent(sys) = is_time_dependent(symbolic_container(sys))

"""
    constant_structure(sys)

Check if `sys` has a constant structure. Constant structure systems do not change the
number of variables or parameters over time.
"""
constant_structure(sys) = constant_structure(symbolic_container(sys))

"""
    all_solvable_symbols(sys)

Return an array of all symbols in the system that can be solved for. This includes
observed variables, but not parameters or independent variables.
"""
all_solvable_symbols(sys) = all_solvable_symbols(symbolic_container(sys))

"""
    all_symbols(sys)

Return an array of all symbols in the system. This includes parameters and independent
variables.
"""
all_symbols(sys) = all_symbols(symbolic_container(sys))
