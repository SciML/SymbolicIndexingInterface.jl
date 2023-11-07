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
variable_symbols(sc::SymbolCache, i = nothing) = sc.variables
is_parameter(sc::SymbolCache, sym) = sym in sc.parameters
parameter_index(sc::SymbolCache, sym) = findfirst(isequal(sym), sc.parameters)
parameter_symbols(sc::SymbolCache) = sc.parameters
is_independent_variable(sc::SymbolCache, sym) = sym in sc.independent_variables
independent_variable_symbols(sc::SymbolCache) = sc.independent_variables
is_observed(sc::SymbolCache, sym) = false
is_time_dependent(sc::SymbolCache) = !isempty(sc.independent_variables)
constant_structure(::SymbolCache) = true

function Base.copy(sc::SymbolCache)
    return SymbolCache(sc.variables === nothing ? nothing : copy(sc.variables),
        sc.parameters === nothing ? nothing : copy(sc.parameters),
        sc.independent_variables === nothing ? nothing : copy(sc.independent_variables))
end
