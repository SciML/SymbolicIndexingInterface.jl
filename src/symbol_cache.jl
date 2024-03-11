"""
    struct SymbolCache{V,P,I}
    function SymbolCache(vars, [params, [indepvars]])

A struct implementing the symbolic indexing interface for the trivial case of having a
vector of variables, parameters, and independent variables. It is considered time
dependent if it contains at least one independent variable. It returns `true` for
`is_observed(::SymbolCache, sym)` if `sym isa Expr`. Functions can be generated using
`observed` for `Expr`s involving variables in the `SymbolCache` if it has at most one
independent variable.

The independent variable may be specified as a single symbolic variable instead of an
array containing a single variable if the system has only one independent variable.
"""
struct SymbolCache{
    V <: Union{Nothing, AbstractVector},
    P <: Union{Nothing, AbstractVector},
    I,
    D <: Dict
}
    variables::V
    parameters::P
    independent_variables::I
    defaults::D
end

function SymbolCache(vars = nothing, params = nothing, indepvars = nothing;
        defaults = Dict{Symbol, Union{Symbol, Expr, Number}}())
    return SymbolCache{typeof(vars), typeof(params), typeof(indepvars), typeof(defaults)}(
        vars,
        params,
        indepvars,
        defaults)
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
is_observed(::SymbolCache, ::Expr) = true
function observed(sc::SymbolCache, expr::Expr)
    let cache = Dict{Expr, Function}()
        return get!(cache, expr) do
            fnbody = Expr(:block)
            declared = Set{Symbol}()
            MacroTools.postwalk(expr) do sym
                sym isa Symbol || return
                sym in declared && return
                if sc.variables !== nothing &&
                   (idx = findfirst(isequal(sym), sc.variables)) !== nothing
                    push!(fnbody.args, :($sym = u[$idx]))
                    push!(declared, sym)
                elseif sc.parameters !== nothing &&
                       (idx = findfirst(isequal(sym), sc.parameters)) !== nothing
                    push!(fnbody.args, :($sym = p[$idx]))
                    push!(declared, sym)
                elseif sym === sc.independent_variables ||
                       sc.independent_variables isa Vector &&
                       sym == only(sc.independent_variables)
                    push!(fnbody.args, :($sym = t))
                    push!(declared, sym)
                end
            end
            fnexpr = if is_time_dependent(sc)
                :(function (u, p, t)
                    $fnbody
                    return $expr
                end)
            else
                :(function (u, p)
                    $fnbody
                    return $expr
                end)
            end
            return RuntimeGeneratedFunctions.@RuntimeGeneratedFunction(fnexpr)
        end
    end
end
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
function all_symbols(sc::SymbolCache)
    vcat(variable_symbols(sc), parameter_symbols(sc), independent_variable_symbols(sc))
end
default_values(sc::SymbolCache) = sc.defaults

function Base.copy(sc::SymbolCache)
    return SymbolCache(sc.variables === nothing ? nothing : copy(sc.variables),
        sc.parameters === nothing ? nothing : copy(sc.parameters),
        sc.independent_variables isa AbstractArray ? copy(sc.independent_variables) :
        sc.independent_variables, copy(sc.defaults))
end
