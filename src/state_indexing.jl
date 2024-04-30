state_values(arr::AbstractArray) = arr
state_values(arr, i) = state_values(arr)[i]

function set_state!(sys, val, idx)
    state_values(sys)[idx] = val
end

current_time(p, i) = current_time(p)[i]

"""
    getu(sys, sym)

Return a function that takes an integrator, problem or solution of `sys`, and returns
the value of the symbolic `sym`. If `sym` is not an observed quantity, the returned
function can also directly be called with an array of values representing the state
vector. `sym` can be a direct index into the state vector, a symbolic state, a symbolic
expression involving symbolic quantities in the system `sys`, a parameter symbol, or the
independent variable symbol, or an array/tuple of the aforementioned. If the returned
function is called with a timeseries object, it can also be given a second argument
representing the index at which to find the value of `sym`.

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

struct GetStateIndex{I} <: AbstractIndexer
    idx::I
end
function (gsi::GetStateIndex)(::Timeseries, prob)
    getindex.(state_values(prob), (gsi.idx,))
end
function (gsi::GetStateIndex)(::Timeseries, prob, i)
    getindex(state_values(prob, i), gsi.idx)
end
function (gsi::GetStateIndex)(::NotTimeseries, prob)
    state_values(prob, gsi.idx)
end

function _getu(sys, ::NotSymbolic, ::NotSymbolic, sym)
    return GetStateIndex(sym)
end

struct GetpAtStateTime{G} <: AbstractIndexer
    getter::G
end

function (g::GetpAtStateTime)(::Timeseries, prob)
    [g.getter(parameter_values_at_state_time(prob, i))
     for i in eachindex(current_time(prob))]
end
function (g::GetpAtStateTime)(::Timeseries, prob, i)
    g.getter(parameter_values_at_state_time(prob, i))
end
function (g::GetpAtStateTime)(::NotTimeseries, prob)
    g.getter(prob)
end

struct GetIndepvar <: AbstractIndexer end

(::GetIndepvar)(::IsTimeseriesTrait, prob) = current_time(prob)
(::GetIndepvar)(::Timeseries, prob, i) = current_time(prob, i)

struct TimeDependentObservedFunction{F} <: AbstractIndexer
    obsfn::F
end

function (o::TimeDependentObservedFunction)(::Timeseries, prob)
    curtime = current_time(prob)
    return o.obsfn.(state_values(prob),
        (parameter_values_at_state_time(prob, i) for i in eachindex(curtime)),
        curtime)
end
function (o::TimeDependentObservedFunction)(::Timeseries, prob, i)
    return o.obsfn(state_values(prob, i),
        parameter_values_at_state_time(prob, i),
        current_time(prob, i))
end
function (o::TimeDependentObservedFunction)(::NotTimeseries, prob)
    return o.obsfn(state_values(prob), parameter_values(prob), current_time(prob))
end

struct TimeIndependentObservedFunction{F} <: AbstractIndexer
    obsfn::F
end

function (o::TimeIndependentObservedFunction)(::IsTimeseriesTrait, prob)
    return o.obsfn(state_values(prob), parameter_values(prob))
end

function _getu(sys, ::ScalarSymbolic, ::SymbolicTypeTrait, sym)
    if is_variable(sys, sym)
        idx = variable_index(sys, sym)
        return getu(sys, idx)
    elseif is_parameter(sys, sym)
        return GetpAtStateTime(getp(sys, sym))
    elseif is_independent_variable(sys, sym)
        return GetIndepvar()
    elseif is_observed(sys, sym)
        fn = observed(sys, sym)
        if is_time_dependent(sys)
            return TimeDependentObservedFunction(fn)
        else
            return TimeIndependentObservedFunction(fn)
        end
    end
    error("Invalid symbol $sym for `getu`")
end

struct MultipleGetters{G} <: AbstractIndexer
    getters::G
end

function (mg::MultipleGetters)(::Timeseries, prob)
    return broadcast(i -> map(g -> g(prob, i), mg.getters),
        eachindex(state_values(prob)))
end
function (mg::MultipleGetters)(::Timeseries, prob, i)
    return map(g -> g(prob, i), mg.getters)
end
function (mg::MultipleGetters)(::NotTimeseries, prob)
    return map(g -> g(prob), mg.getters)
end

struct AsTupleWrapper{G} <: AbstractIndexer
    getter::G
end

function (atw::AsTupleWrapper)(::IsTimeseriesTrait, args...)
    return Tuple(atw.getter(args...))
end

for (t1, t2) in [
    (ScalarSymbolic, Any),
    (ArraySymbolic, Any),
    (NotSymbolic, Union{<:Tuple, <:AbstractArray})
]
    @eval function _getu(sys, ::NotSymbolic, ::$t1, sym::$t2)
        num_observed = count(x -> is_observed(sys, x), sym)
        if num_observed <= 1
            getters = getu.((sys,), sym)
            return MultipleGetters(getters)
        else
            obs = observed(sys, sym isa Tuple ? collect(sym) : sym)
            getter = if is_timeseries(sys)
                TimeDependentObservedFunction(obs)
            else
                TimeIndependentObservedFunction(obs)
            end
            if sym isa Tuple
                getter = AsTupleWrapper(getter)
            end
            return getter
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
can be a direct index, a symbolic state, or an array/tuple of the aforementioned.

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
    if is_variable(sys, sym)
        idx = variable_index(sys, sym)
        return function setter!(prob, val)
            set_state!(prob, val, idx)
        end
    elseif is_parameter(sys, sym)
        return setp(sys, sym)
    end
    error("Invalid symbol $sym for `setu`")
end

for (t1, t2) in [
    (ScalarSymbolic, Any),
    (ArraySymbolic, Any),
    (NotSymbolic, Union{<:Tuple, <:AbstractArray})
]
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
