"""
    struct SymbolCache{V,P,I}
    function SymbolCache(vars, [params, [indepvars]])

A struct implementing the symbolic indexing interface for the trivial case
of having a vector of variables, parameters and independent variables. This
struct does not implement `observed`, and `is_observed` returns `false` for
all input symbols. It is considered to be time dependent if it contains
at least one independent variable.
"""
struct SymbolCache{V, P, I}
    variables::Vector{V}
    parameters::Vector{P}
    independent_variables::Vector{I}
end

function SymbolCache(vars::Vector{V}, params = [], indepvars = []) where {V}
    return SymbolCache{V, eltype(params), eltype(indepvars)}(vars, params, indepvars)
end

is_variable(sc::SymbolCache, sym) = sym in sc.variables
variable_index(sc::SymbolCache, sym) = findfirst(isequal(sym), sc.variables)
is_parameter(sc::SymbolCache, sym) = sym in sc.parameters
parameter_index(sc::SymbolCache, sym) = findfirst(isequal(sym), sc.parameters)
is_independent_variable(sc::SymbolCache, sym) = sym in sc.independent_variables
current_state(sc::SymbolCache) = sc.variables
is_observed(sc::SymbolCache, sym) = false
is_time_dependent(sc::SymbolCache) = !isempty(sc.independent_variables)
constant_structure(::SymbolCache) = true
