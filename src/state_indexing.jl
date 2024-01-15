abstract type IsTimeseriesTrait end

"""
    struct Timeseries <: IsTimeseriesTrait end

Trait indicating a type contains timeseries data. This affects the behaviour of
functions such as [`state_values`](@ref) and [`current_time`](@ref).

See also: [`NotTimeseries`](@ref), [`is_timeseries`](@ref)
"""
struct Timeseries <: IsTimeseriesTrait end

"""
    struct NotTimeseries <: IsTimeseriesTrait end

Trait indicating a type does not contain timeseries data. This affects the behaviour
of functions such as [`state_values`](@ref) and [`current_time`](@ref). Note that
if a type is `NotTimeseries` this only implies that it does not _store_ timeseries
data. It may still be time-dependent. For example, an `ODEProblem` only stores
the initial state of a system, so it is `NotTimeseries`, but still time-dependent.
This is the default trait variant for all types.

See also: [`Timeseries`](@ref), [`is_timeseries`](@ref)
"""
struct NotTimeseries <: IsTimeseriesTrait end

"""
    is_timeseries(x) = is_timeseries(typeof(x))
    is_timeseries(::Type)

Get the timeseries trait of a type. Defaults to [`NotTimeseries`](@ref) for all types.

See also: [`Timeseries`](@ref), [`NotTimeseries`](@ref)
"""
function is_timeseries end

is_timeseries(x) = is_timeseries(typeof(x))
is_timeseries(::Type) = NotTimeseries()

"""
    state_values(p)

Return an indexable collection containing the values of all states in the integrator or
problem `p`. If `is_timeseries(p)` is [`Timeseries`](@ref), return a vector of arrays,
each of which contain the state values at the corresponding timestep.

If this function is called with an `AbstractArray`, it will return the same array.

See: [`is_timeseries`](@ref)
"""
function state_values end
state_values(arr::AbstractArray) = arr

"""
    set_state!(sys, val, idx)

Set the state at index `idx` to `val` for system `sys`. This defaults to modifying
`state_values(sys)`. If any additional bookkeeping needs to be performed or the
default implementation does not work for a particular type, this method needs to be
defined to enable the proper functioning of [`setu`](@ref).

See: [`state_values`](@ref)
"""
function set_state!(sys, val, idx)
    state_values(sys)[idx] = val
end

"""
    current_time(p)

Return the current time in the integrator or problem `p`. If
`is_timeseries(p)` is [`Timeseries`](@ref), return the vector of timesteps at which
the state value is saved.


See: [`is_timeseries`](@ref)
"""
function current_time end

"""
    getu(sys, sym)

Return a function that takes an integrator, problem or solution of `sys`, and returns
the value of the symbolic `sym`. If `sym` is not an observed quantity, the returned
function can also directly be called with an array of values representing the state
vector. `sym` can be a direct index into the state vector, a symbolic state, a symbolic
expression involving symbolic quantities in the system `sys`, or an array/tuple of the
aforementioned.

At minimum, this requires that the integrator, problem or solution implement
[`state_values`](@ref). To support symbolic expressions, the integrator or problem
must implement [`observed`](@ref), [`parameter_values`](@ref) and
[`current_time`](@ref).

This function typically does not need to be implemented, and has a default implementation
relying on the above functions.
"""
function getu(sys, sym)
    symtype = symbolic_type(sym)
    elsymtype = symbolic_type(eltype(sym))
    _getu(sys, symtype, elsymtype, sym)
end

function _getu(sys, ::NotSymbolic, ::NotSymbolic, sym)
    _getter(::Timeseries, prob) = getindex.(state_values(prob), (sym,))
    _getter(::NotTimeseries, prob) = state_values(prob)[sym]
    return let _getter = _getter
        function getter(prob)
            return _getter(is_timeseries(prob), prob)
        end
    end
end

function _getu(sys, ::ScalarSymbolic, ::SymbolicTypeTrait, sym)
    if is_variable(sys, sym)
        idx = variable_index(sys, sym)
        return getu(sys, idx)
    elseif is_observed(sys, sym)
        fn = observed(sys, sym)
        if is_time_dependent(sys)
            function _getter2(::Timeseries, prob)
                return fn.(state_values(prob),
                    (parameter_values(prob),),
                    current_time(prob))
            end
            function _getter2(::NotTimeseries, prob)
                return fn(state_values(prob), parameter_values(prob), current_time(prob))
            end

            return let _getter2 = _getter2
                function getter2(prob)
                    return _getter2(is_timeseries(prob), prob)
                end
            end
        else
            function _getter3(::Timeseries, prob)
                return fn.(state_values(prob), (parameter_values(prob),))
            end
            function _getter3(::NotTimeseries, prob)
                return fn(state_values(prob), parameter_values(prob))
            end

            return let _getter3 = _getter3
                function getter3(prob)
                    return _getter3(is_timeseries(prob), prob)
                end
            end
        end
    end
    error("Invalid symbol $sym for `getu`")
end

struct TimeseriesIndexWrapper{T, I}
    timeseries::T
    idx::I
end

state_values(t::TimeseriesIndexWrapper) = state_values(t.timeseries)[t.idx]
parameter_values(t::TimeseriesIndexWrapper) = parameter_values(t.timeseries)
current_time(t::TimeseriesIndexWrapper) = current_time(t.timeseries)[t.idx]

for (t1, t2) in [(ScalarSymbolic, Any), (ArraySymbolic, Any), (NotSymbolic, Union{<:Tuple, <:AbstractArray})]
    @eval function _getu(sys, ::NotSymbolic, ::$t1, sym::$t2)
        getters = getu.((sys,), sym)
        _call(getter, prob) = getter(prob)

        return let getters = getters, _call = _call
            _getter(::NotTimeseries, prob) = map(g -> g(prob), getters)
            function _getter(::Timeseries, prob)
                tiws = TimeseriesIndexWrapper.((prob,), eachindex(state_values(prob)))
                # Ideally this should recursively call `_getter` but that leads to type-instability
                # since the reference to itself is boxed
                # Turning this broadcasted `_call` into a map also makes this type-unstable

                return map(tiw -> _call.(getters, (tiw,)), tiws)
            end

            # Need another scope for this to not box `_getter`
            let _getter = _getter
                function getter(prob)
                    return _getter(is_timeseries(prob), prob)
                end
            end
        end
    end
end

function _getu(sys, ::ArraySymbolic, ::NotSymbolic, sym)
    return getu(sys, collect(sym))
end

# setu doesn't need the same `let` blocks to be inferred for some reason

"""
    setu(sys, sym)

Return a function that takes an array representing the state vector or an integrator or
problem of `sys`, and a value, and sets the the state `sym` to that value. Note that `sym`
can be a direct numerical index, a symbolic state, or an array/tuple of the aforementioned.

Requires that the integrator implement [`state_values`](@ref) and the
returned collection be a mutable reference to the state vector in the integrator/problem. Alternatively, if this is not possible or additional actions need to
be performed when updating state, [`set_state!`](@ref) can be defined.
This function does not work on types for which [`is_timeseries`](@ref) is
[`Timeseries`](@ref).
"""
function setu(sys, sym)
    symtype = symbolic_type(sym)
    elsymtype = symbolic_type(eltype(sym))
    _setu(sys, symtype, elsymtype, sym)
end

function _setu(sys, ::NotSymbolic, ::NotSymbolic, sym)
    return function setter!(prob, val)
        set_state!(prob, val, sym)
    end
end

function _setu(sys, ::ScalarSymbolic, ::SymbolicTypeTrait, sym)
    is_variable(sys, sym) || error("Invalid symbol $sym for `setu`")
    idx = variable_index(sys, sym)
    return function setter!(prob, val)
        set_state!(prob, val, idx)
    end
end

for (t1, t2) in [(ScalarSymbolic, Any), (ArraySymbolic, Any), (NotSymbolic, Union{<:Tuple, <:AbstractArray})]
    @eval function _setu(sys, ::NotSymbolic, ::$t1, sym::$t2)
        setters = setu.((sys,), sym)
        return function setter!(prob, val)
            map((s!, v) -> s!(prob, v), setters, val)
        end
    end
end

function _setu(sys, ::ArraySymbolic, ::NotSymbolic, sym)
    return setu(sys, collect(sym))
end
