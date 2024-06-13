"""
    symbolic_container(indp)

Using `indp`, return an object that implements the index provider interface. In case `indp`
itself implements the interface, `indp` can be returned as-is. All index provider interface
methods fall back to calling the same method on `symbolic_container(indp)`, so this may be
used for trivial implementations of the interface that forward all calls to another object.
"""
function symbolic_container end

"""
    is_variable(indp, sym)

Check whether the given `sym` is a variable in `indp`.
"""
is_variable(indp, sym) = is_variable(symbolic_container(indp), sym)

"""
    variable_index(indp, sym, [i])

Return the index of the given variable `sym` in `indp`, or `nothing` otherwise. If
[`constant_structure`](@ref) is `false`, this accepts the current time index as an
additional parameter `i`.
"""
variable_index(indp, sym) = variable_index(symbolic_container(indp), sym)
variable_index(indp, sym, i) = variable_index(symbolic_container(indp), sym, i)

"""
    variable_symbols(indp, [i])

Return a vector of the symbolic variables being solved for in the index provider `indp`.
If `constant_structure(sys) == false` this accepts an additional parameter indicating
the current time index. The returned vector should not be mutated.

For types that implement `Base.getindex` with symbolic indices using this interface,
the shorthand `valp[solvedvariables]` can be used as shorthand for
`valp[variable_symbols(sys)]`. See: [`solvedvariables`](@ref).
"""
variable_symbols(indp) = variable_symbols(symbolic_container(indp))
variable_symbols(indp, i) = variable_symbols(symbolic_container(indp), i)

"""
    is_parameter(indp, sym)

Check whether the given `sym` is a parameter in `indp`.
"""
is_parameter(indp, sym) = is_parameter(symbolic_container(indp), sym)

"""
    parameter_index(indp, sym)

Return the index of the given parameter `sym` in `indp`, or `nothing` otherwise.
"""
parameter_index(indp, sym) = parameter_index(symbolic_container(indp), sym)

"""
    is_timeseries_parameter(indp, sym)

Check whether the given `sym` is a timeseries parameter in `indp`.
"""
function is_timeseries_parameter(indp, sym)
    if hasmethod(symbolic_container, Tuple{typeof(indp)})
        is_timeseries_parameter(symbolic_container(indp), sym)
    else
        return false
    end
end

"""
    struct ParameterTimeseriesIndex
    function ParameterTimeseriesIndex(timeseries_idx, parameter_idx)

A struct storing the index of the timeseries of a timeseries parameter in a parameter
timeseries object. `timeseries_idx` refers to an index that identifies the timeseries
that the parameter belongs to. `parameter_idx` refers to the index of the parameter's
timeseries in that timeseries object. Note that `parameter_idx` may be different from
the object returned by [`parameter_index`](@ref) for a given parameter. The two fields in
this struct are `timeseries_idx` and `parameter_idx`.
"""
struct ParameterTimeseriesIndex{T, I}
    timeseries_idx::T
    parameter_idx::I
end

"""
    timeseries_parameter_index(indp, sym)

Return the index of timeseries parameter `sym` in `indp`. Must return this index as a
[`ParameterTimeseriesIndex`](@ref) object. Return `nothing` if `sym` is not a timeseries
parameter in `indp`. Defaults to returning `nothing`. Respects the
[`symbolic_container`](@ref) fallback for `indp` if present.
"""
function timeseries_parameter_index(indp, sym)
    if hasmethod(symbolic_container, Tuple{typeof(indp)})
        timeseries_parameter_index(symbolic_container(indp), sym)
    else
        return nothing
    end
end

"""
    struct ParameterObservedFunction
    function ParameterObservedFunction(timeseries_idx, observed_fn::Function)
    function ParameterObservedFunction(observed_fn::Function)

A struct which stores the parameter observed function and optional timeseries index for
a particular symbol. The timeseries index is optional and may be omitted. Specifying the
timeseries index allows [`getp`](@ref) to return the appropriate timeseries for a
timeseries parameter.

For time-dependent index providers (where `is_time_dependent(indp)`) `observed_fn` must
have the signature `(p, t) -> [values...]`. For non-time-dependent index providers
(where `!is_time_dependent(indp)`) `observed_fn` must have the signature
`(p) -> [values...]`. To support in-place `getp` methods, `observed_fn` must also have an
additional method which takes `buffer::AbstractArray` as its first argument. The required
values must be written to the buffer in the appropriate order.
"""
struct ParameterObservedFunction{I, F <: Function}
    timeseries_idx::I
    observed_fn::F
end

"""
    parameter_observed(indp, sym)

Return the observed function of `sym` in `indp` as a [`ParameterObservedFunction`](@ref).
If `sym` only involves variables from a single parameter timeseries (optionally along
with non-timeseries parameters) the timeseries index of the parameter timeseries should
be provided in the [`ParameterObservedFunction`](@ref). In all other cases, just the
observed function should be returned as part of the `ParameterObservedFunction` object.

By default, this function returns `nothing`.
"""
function parameter_observed(indp, sym)
    if hasmethod(symbolic_container, Tuple{typeof(indp)})
        return parameter_observed(symbolic_container(indp), sym)
    else
        return nothing
    end
end

"""
    parameter_symbols(indp)

Return a vector of the symbolic parameters of the given index provider `indp`. The returned
vector should not be mutated.
"""
parameter_symbols(indp) = parameter_symbols(symbolic_container(indp))

"""
    is_independent_variable(indp, sym)

Check whether the given `sym` is an independent variable in `indp`. The returned vector
should not be mutated.
"""
is_independent_variable(indp, sym) = is_independent_variable(symbolic_container(indp), sym)

"""
    independent_variable_symbols(indp)

Return a vector of the symbolic independent variables of the given index provider `indp`.
"""
independent_variable_symbols(indp) = independent_variable_symbols(symbolic_container(indp))

"""
    is_observed(indp, sym)

Check whether the given `sym` is an observed value in `indp`.
"""
is_observed(indp, sym) = is_observed(symbolic_container(indp), sym)

"""
    observed(indp, sym, [states])

Return the observed function of the given `sym` in `indp`. The returned function should
have the signature `(u, p) -> [values...]` where `u` and `p` is the current state and
parameter object, respectively. If `istimedependent(indp) == true`, the function should
accept the current time `t` as its third parameter. If `constant_structure(indp) == false`,
`observed` accepts a third parameter, which can either be a vector of symbols indicating
the order of states or a time index, which identifies the order of states. This function
does not need to be defined if [`is_observed`](@ref) always returns `false`. Thus,
it is mandatory to always check `is_observed` before using this function.

See also: [`is_time_dependent`](@ref), [`constant_structure`](@ref)
"""
observed(indp, sym) = observed(symbolic_container(indp), sym)
observed(indp, sym, states) = observed(symbolic_container(indp), sym, states)

"""
    is_time_dependent(indp)

Check if `indp` has time as (one of) its independent variables.
"""
is_time_dependent(indp) = is_time_dependent(symbolic_container(indp))

"""
    constant_structure(indp)

Check if `indp` has a constant structure. Constant structure index providers do not change
the number of variables or parameters over time.
"""
constant_structure(indp) = constant_structure(symbolic_container(indp))

"""
    all_variable_symbols(indp)

Return a vector of variable symbols in the system, including observed quantities.

For types that implement `Base.getindex` with symbolic indices using this interface,
The shorthand `sys[allvariables]` can be used as shorthand for
`valp[all_variable_symbols(indp)]`.

See: [`allvariables`](@ref).
"""
all_variable_symbols(indp) = all_variable_symbols(symbolic_container(indp))

"""
    all_symbols(indp)

Return an array of all symbols in the index provider. This includes parameters and
independent variables.
"""
all_symbols(indp) = all_symbols(symbolic_container(indp))

"""
    name_to_symbolic(indp, sym::Symbol)

Return the symbolic variable in `indp` with name `sym`. If there is no such variable,
return `nothing`. This roughly corresponds to the reverse operation of [`getname`](@ref),
in the context of index provider `indp`. By default, this method will search through
`all_symbols(indp)` for one with the required name.

See also: [`all_symbols`](@ref).
"""
function name_to_symbolic(indp, sym::Symbol)
    for s in all_symbols(indp)
        if hasname(s) && getname(s) == sym
            return s
        end
    end
    return nothing
end

"""
    default_values(indp)

Return a dictionary mapping symbols in the index provider to their default value, if any.
This includes parameter symbols. The dictionary must be mutable.
"""
function default_values(indp)
    if hasmethod(symbolic_container, Tuple{typeof(indp)})
        default_values(symbolic_container(indp))
    else
        Dict()
    end
end

struct SolvedVariables end

"""
    const solvedvariables = SolvedVariables()

This singleton is used as a shortcut to allow indexing of all solution variables
(excluding observed quantities). It has a [`symbolic_type`](@ref) of
[`ScalarSymbolic`](@ref). See: [`variable_symbols`](@ref).
"""
const solvedvariables = SolvedVariables()
symbolic_type(::Type{SolvedVariables}) = ScalarSymbolic()

struct AllVariables end

"""
    const allvariables = AllVariables()

This singleton is used as a shortcut to allow indexing of all solution variables
(including observed quantities). It has a [`symbolic_type`](@ref) of
[`ScalarSymbolic`](@ref). See [`all_variable_symbols`](@ref).
"""
const allvariables = AllVariables()
symbolic_type(::Type{AllVariables}) = ScalarSymbolic()
