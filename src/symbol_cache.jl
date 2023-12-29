"""
    struct SymbolCache{V,P,I}
    function SymbolCache(vars, [params, [indepvars]])

A struct implementing the symbolic indexing interface for the trivial case
of having a vector of variables, parameters, and independent variables. This
struct does not implement `observed`, and `is_observed` returns `false` for
all input symbols. It is considered time dependent if it contains
at least one independent variable.

The independent variable may be specified as a single symbolic variable instead of an
array containing a single variable if the system has only one independent variable.
"""
struct SymbolCache{
    V <: Union{Nothing, AbstractVector},
    P <: Union{Nothing, AbstractVector},
    I,
}
    variables::V
    parameters::P
    independent_variables::I
end

function SymbolCache(vars = nothing, params = nothing, indepvars = nothing)
    return SymbolCache{typeof(vars), typeof(params), typeof(indepvars)}(vars,
        params,
        indepvars)
end

function is_variable(sc::SymbolCache, sym)
    sc.variables !== nothing && any(isequal(sym), sc.variables)
end
function variable_index(sc::SymbolCache, sym)
    sc.variables === nothing ? nothing : findfirst(isequal(sym), sc.variables)
end
variable_symbols(sc::SymbolCache, i = nothing) = something(sc.variables, [])
function is_parameter(sc::SymbolCache, sym)
    sc.parameters !== nothing && any(isequal(sym), sc.parameters)
end
function parameter_index(sc::SymbolCache, sym)
    sc.parameters === nothing ? nothing : findfirst(isequal(sym), sc.parameters)
end
parameter_symbols(sc::SymbolCache) = something(sc.parameters, [])
function is_independent_variable(sc::SymbolCache, sym)
    sc.independent_variables === nothing && return false
    if symbolic_type(sc.independent_variables) == NotSymbolic()
        return any(isequal(sym), sc.independent_variables)
    elseif symbolic_type(sc.independent_variables) == ScalarSymbolic()
        return sym == sc.independent_variables
    else
        return any(isequal(sym), collect(sc.independent_variables))
    end
end
function independent_variable_symbols(sc::SymbolCache)
    sc.independent_variables === nothing && return []
    if symbolic_type(sc.independent_variables) == NotSymbolic()
        return sc.independent_variables
    elseif symbolic_type(sc.independent_variables) == ScalarSymbolic()
        return [sc.independent_variables]
    else
        return collect(sc.independent_variables)
    end
end
is_observed(sc::SymbolCache, sym) = false
function is_time_dependent(sc::SymbolCache)
    sc.independent_variables === nothing && return false
    if symbolic_type(sc.independent_variables) == NotSymbolic()
        return !isempty(sc.independent_variables)
    else
        return true
    end
end
constant_structure(::SymbolCache) = true
all_variable_symbols(sc::SymbolCache) = variable_symbols(sc)
all_symbols(sc::SymbolCache) = vcat(variable_symbols(sc), parameter_symbols(sc), independent_variable_symbols(sc))

function Base.copy(sc::SymbolCache)
    return SymbolCache(sc.variables === nothing ? nothing : copy(sc.variables),
        sc.parameters === nothing ? nothing : copy(sc.parameters),
        sc.independent_variables isa AbstractArray ? copy(sc.independent_variables) :
        sc.independent_variables)
end
