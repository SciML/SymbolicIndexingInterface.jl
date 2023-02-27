"""
$(TYPEDSIGNATURES)

Get an iterable over the independent variables for the given system. Default to an empty
vector.
"""
function independent_variables end
independent_variables(::Any) = []

"""
$(TYPEDSIGNATURES)

Check if the given sym is an independent variable in the given system. Default to checking
if the given `sym` exists in the iterable returned by `independent_variables`.
"""
function is_indep_sym end

function is_indep_sym(store, sym)
    any(isequal(Symbol(sym)), Symbol.(independent_variables(store)))
end

"""
$(TYPEDSIGNATURES)

Get an iterable over the states for the given system. Default to an empty vector.
"""
function states end

states(::Any) = []

"""
$(TYPEDSIGNATURES)

Get an iterable over the unknown states for the given system. Default to an empty vector.
"""
function unknown_states end

unknown_states(::Any) = []

"""
$(TYPEDSIGNATURES)

Find the index of the given sym in the given system. Default to the index of the first
symbol in the iterable returned by `states` which matches the given `sym`. Return
`nothing` if the given `sym` does not match.
"""
function state_sym_to_index end

function state_sym_to_index(store, sym)
    findfirst(isequal(Symbol(sym)), Symbol.(states(store)))
end

"""
$(TYPEDSIGNATURES)

Check if the given sym is a state variable in the given system. Default to checking if
the value returned by `state_sym_to_index` is not `nothing`.
"""
function is_state_sym end

is_state_sym(store, sym) = !isnothing(state_sym_to_index(store, sym))

"""
$(TYPEDSIGNATURES)

Get an iterable over the parameters variables for the given system. Default to an empty
vector.
"""
function parameters end

parameters(::Any) = []

"""
$(TYPEDSIGNATURES)

Find the index of the given sym in the given system. Default to the index of the first
symbol in the iterable retruned by `parameters` which matches the given `sym`. Return
`nothing` if the given `sym` does not match.
"""
function param_sym_to_index end

param_sym_to_index(store, sym) = findfirst(isequal(Symbol(sym)), Symbol.(parameters(store)))

"""
$(TYPEDSIGNATURES)

Check if the given sym is a parameter variable in the given system. Default
to checking if the value returned by `param_sym_to_index` is not `nothing`.
"""
function is_param_sym end

is_param_sym(store, sym) = !isnothing(param_sym_to_index(store, sym))

"""
$(TYPEDSIGNATURES)

Get an iterable over the observed variable expressions for the given system.
Default to an empty vector.
"""
function observed end

observed(::Any) = []

"""
$(TYPEDSIGNATURES)

Check if the given sym is an observed variable in the given system. Default
to checking if the value returned by `observed_sym_to_index` is not `nothing`.
"""
function is_observed_sym end

is_observed_sym(store, sym) = !isnothing(observed_sym_to_index(store, sym))

"""
$(TYPEDSIGNATURES)

Find the index of the given sym in the given system. Default to the index of the first
symbol in the iterable returned by `states` which matches the given `sym`. Return
`nothing` if the given `sym` does not match.
"""
function observed_sym_to_index end

function observed_sym_to_index(store, sym)
    findfirst(o -> isequal(sym, o.lhs), observed(store))
end

"""
$(TYPEDSIGNATURES)

Return a list of the dependent state variables of an observed variable. Default to returning
an empty list.
"""
function get_state_dependencies end

get_state_dependencies(store, sym) = []

"""
$(TYPEDSIGNATURES)

Return a list of the dependent observed variables of an observed variable. Default to returning
an empty list.
"""
function get_observed_dependencies end

get_observed_dependencies(store, sym) = []

"""
$(TYPEDSIGNATURES)

Return a list of the dependent state variables of all observed equations of the system.
Default to returning an empty list.
"""
function get_deps_of_observed end

function get_deps_of_observed(store)
    obs = observed(store)
    deps = mapreduce(vcat, obs, init = []) do eq
        get_state_dependencies(store, eq.lhs)
    end |> unique

    return deps
end
