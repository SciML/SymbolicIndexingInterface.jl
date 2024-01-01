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

See: [`is_timeseries`](@ref)
"""
function state_values end

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
the value of the symbolic `sym`. `sym` can be a direct index into the state vector, a
symbolic state, a symbolic expression involving symbolic quantities in the system
`sys`, or an array/tuple of the aforementioned.

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

    if symtype != NotSymbolic()
        _getu(sys, symtype, sym)
    else
        _getu(sys, elsymtype, sym)
    end
end

function _getu(sys, ::NotSymbolic, sym)
    _getter(::Timeseries, prob) = getindex.(state_values(prob), (sym,))
    _getter(::NotTimeseries, prob) = state_values(prob)[sym]
    return function getter(prob)
        return _getter(is_timeseries(prob), prob)
    end
end

function _getu(sys, ::ScalarSymbolic, sym)
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

            return function getter2(prob)
                return _getter2(is_timeseries(prob), prob)
            end
        else
            function _getter3(::Timeseries, prob)
                return fn.(state_values(prob), (parameter_values(prob),))
            end
            function _getter3(::NotTimeseries, prob)
                return fn(state_values(prob), parameter_values(prob))
            end

            return function getter3(prob)
                return _getter3(is_timeseries(prob), prob)
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

function _getu(sys, ::ScalarSymbolic, sym::Union{<:Tuple, <:AbstractArray})
    getters = getu.((sys,), sym)
    _call(getter, prob) = getter(prob)

    function _getter(::Timeseries, prob)
        tiws = TimeseriesIndexWrapper.((prob,), eachindex(state_values(prob)))
        return [_getter(NotTimeseries(), tiw) for tiw in tiws]
    end
    _getter(::NotTimeseries, prob) = _call.(getters, (prob,))
    return function getter(prob)
        return _getter(is_timeseries(prob), prob)
    end
end

function _getu(sys, ::ArraySymbolic, sym)
    return getu(sys, collect(sym))
end

"""
    setu(sys, sym)

Return a function that takes an integrator or problem of `sys` and a value, and sets the
the state `sym` to that value. Note that `sym` can be a direct numerical index, a symbolic state, or an array/tuple of the aforementioned.

Requires that the integrator implement [`state_values`](@ref) and the
returned collection be a mutable reference to the state vector in the integrator/problem.
This function does not work on types for which [`is_timeseries`](@ref) is
[`Timeseries`](@ref).

In case `state_values` cannot return such a mutable reference, `setu` needs to be
implemented manually.
"""
function setu(sys, sym)
    symtype = symbolic_type(sym)
    elsymtype = symbolic_type(eltype(sym))

    if symtype != NotSymbolic()
        _setu(sys, symtype, sym)
    else
        _setu(sys, elsymtype, sym)
    end
end

function _setu(sys, ::NotSymbolic, sym)
    return function setter!(prob, val)
        state_values(prob)[sym] = val
    end
end

function _setu(sys, ::ScalarSymbolic, sym)
    is_variable(sys, sym) || error("Invalid symbol $sym for `setu`")
    idx = variable_index(sys, sym)
    return function setter!(prob, val)
        state_values(prob)[idx] = val
    end
end

function _setu(sys, ::ScalarSymbolic, sym::Union{<:Tuple, <:AbstractArray})
    setters = setu.((sys,), sym)
    _call!(setter!, prob, val) = setter!(prob, val)
    return function setter!(prob, val)
        _call!.(setters, (prob,), val)
    end
end

function _setu(sys, ::ArraySymbolic, sym)
    return setu(sys, collect(sym))
end
