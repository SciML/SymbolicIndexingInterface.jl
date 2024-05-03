function set_state!(sys, val, idx)
    state_values(sys)[idx] = val
end

"""
    getu(indp, sym)

Return a function that takes a value provider and returns the value of the symbolic
variable `sym`. If `sym` is not an observed quantity, the returned function can also
directly be called with an array of values representing the state vector. `sym` can be an
index into the state vector, a symbolic variable, a symbolic expression involving symbolic
variables in the index provider `indp`, a parameter symbol, the independent variable
symbol, or an array/tuple of the aforementioned. If the returned function is called with
a timeseries object, it can also be given a second argument representing the index at
which to return the value of `sym`.

At minimum, this requires that the value provider implement [`state_values`](@ref). To
support symbolic expressions, the value provider must implement [`observed`](@ref),
[`parameter_values`](@ref) and [`current_time`](@ref).

This function typically does not need to be implemented, and has a default implementation
relying on the above functions.

If the value provider is a parameter timeseries object, the same rules apply as
[`getp`](@ref). The difference here is that `sym` may also contain non-parameter symbols,
and the values are always returned corresponding to the state timeseries.
"""
function getu(sys, sym)
    symtype = symbolic_type(sym)
    elsymtype = symbolic_type(eltype(sym))
    _getu(sys, symtype, elsymtype, sym)
end

struct GetStateIndex{I} <: AbstractStateGetIndexer
    idx::I
end
function (gsi::GetStateIndex)(::Timeseries, prob)
    getindex.(state_values(prob), (gsi.idx,))
end
function (gsi::GetStateIndex)(::Timeseries, prob, i::Union{Int, CartesianIndex})
    getindex(state_values(prob, i), gsi.idx)
end
function (gsi::GetStateIndex)(::Timeseries, prob, i)
    getindex.(state_values(prob, i), gsi.idx)
end
function (gsi::GetStateIndex)(::NotTimeseries, prob)
    state_values(prob, gsi.idx)
end

function _getu(sys, ::NotSymbolic, ::NotSymbolic, sym)
    return GetStateIndex(sym)
end

struct GetpAtStateTime{G} <: AbstractStateGetIndexer
    getter::G
end

function (g::GetpAtStateTime)(ts::Timeseries, prob)
    g(ts, is_parameter_timeseries(prob), prob)
end
function (g::GetpAtStateTime)(ts::Timeseries, prob, i)
    g(ts, is_parameter_timeseries(prob), prob, i)
end
function (g::GetpAtStateTime)(::Timeseries, ::NotTimeseries, prob, _...)
    g.getter(prob)
end
function (g::GetpAtStateTime)(ts::Timeseries, p_ts::Timeseries, prob)
    g(ts, p_ts, is_indexer_timeseries(g.getter), prob)
end
function (g::GetpAtStateTime)(
        ::Timeseries, ::Timeseries, ::Union{IndexerTimeseries, IndexerBoth}, prob)
    g.getter.((prob,),
        parameter_timeseries_at_state_time(prob, indexer_timeseries_index(g.getter)))
end
function (g::GetpAtStateTime)(::Timeseries, ::Timeseries, ::IndexerNotTimeseries, prob)
    g.getter(prob)
end
function (g::GetpAtStateTime)(ts::Timeseries, p_ts::Timeseries, prob, i)
    g(ts, p_ts, is_indexer_timeseries(g.getter), prob, i)
end
function (g::GetpAtStateTime)(
        ::Timeseries, ::Timeseries, ::Union{IndexerTimeseries, IndexerBoth}, prob, i)
    g.getter(prob,
        parameter_timeseries_at_state_time(prob, indexer_timeseries_index(g.getter), i))
end
function (g::GetpAtStateTime)(::Timeseries, ::Timeseries, ::IndexerNotTimeseries,
        prob, ::Union{Int, CartesianIndex})
    g.getter(prob)
end
function (g::GetpAtStateTime)(
        ::Timeseries, ::Timeseries, ::IndexerNotTimeseries, prob, ::Colon)
    map(_ -> g.getter(prob), current_time(prob))
end
function (g::GetpAtStateTime)(
        ::Timeseries, ::Timeseries, ::IndexerNotTimeseries, prob, i::AbstractArray{Bool})
    num_ones = sum(i)
    map(_ -> g.getter(prob), 1:num_ones)
end
function (g::GetpAtStateTime)(::Timeseries, ::Timeseries, ::IndexerNotTimeseries, prob, i)
    map(_ -> g.getter(prob), 1:length(i))
end
function (g::GetpAtStateTime)(::NotTimeseries, prob)
    g.getter(prob)
end

struct GetIndepvar <: AbstractStateGetIndexer end

(::GetIndepvar)(::IsTimeseriesTrait, prob) = current_time(prob)
(::GetIndepvar)(::Timeseries, prob, i) = current_time(prob, i)

struct TimeDependentObservedFunction{F} <: AbstractStateGetIndexer
    obsfn::F
end

function (o::TimeDependentObservedFunction)(ts::Timeseries, prob)
    return o(ts, is_parameter_timeseries(prob), prob)
end
function (o::TimeDependentObservedFunction)(::Timeseries, ::Timeseries, prob)
    map(o.obsfn, state_values(prob),
        parameter_values_at_state_time(prob), current_time(prob))
end
function (o::TimeDependentObservedFunction)(::Timeseries, ::NotTimeseries, prob)
    o.obsfn.(state_values(prob),
        (parameter_values(prob),),
        current_time(prob))
end
function (o::TimeDependentObservedFunction)(ts::Timeseries, prob, i)
    return o(ts, is_parameter_timeseries(prob), prob, i)
end
function (o::TimeDependentObservedFunction)(
        ::Timeseries, ::Timeseries, prob, i::Union{Int, CartesianIndex})
    return o.obsfn(state_values(prob, i),
        parameter_values_at_state_time(prob, i),
        current_time(prob, i))
end
function (o::TimeDependentObservedFunction)(
        ts::Timeseries, p_ts::IsTimeseriesTrait, prob, ::Colon)
    return o(ts, p_ts, prob)
end
function (o::TimeDependentObservedFunction)(
        ts::Timeseries, p_ts::IsTimeseriesTrait, prob, i::AbstractArray{Bool})
    map(only(to_indices(current_time(prob), (i,)))) do idx
        o(ts, p_ts, prob, idx)
    end
end
function (o::TimeDependentObservedFunction)(
        ts::Timeseries, p_ts::IsTimeseriesTrait, prob, i)
    o.((ts,), (p_ts,), (prob,), i)
end
function (o::TimeDependentObservedFunction)(
        ::Timeseries, ::NotTimeseries, prob, i::Union{Int, CartesianIndex})
    o.obsfn(state_values(prob, i), parameter_values(prob), current_time(prob, i))
end
function (o::TimeDependentObservedFunction)(::NotTimeseries, prob)
    return o.obsfn(state_values(prob), parameter_values(prob), current_time(prob))
end

struct TimeIndependentObservedFunction{F} <: AbstractStateGetIndexer
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

struct MultipleGetters{G} <: AbstractStateGetIndexer
    getters::G
end

function (mg::MultipleGetters)(ts::Timeseries, prob)
    return mg.((ts,), (prob,), eachindex(current_time(prob)))
end
function (mg::MultipleGetters)(::Timeseries, prob, i::Union{Int, CartesianIndex})
    return map(CallWith(prob, i), mg.getters)
end
function (mg::MultipleGetters)(ts::Timeseries, prob, ::Colon)
    return mg(ts, prob)
end
function (mg::MultipleGetters)(ts::Timeseries, prob, i::AbstractArray{Bool})
    return map(only(to_indices(current_time(prob), (i,)))) do idx
        mg(ts, prob, idx)
    end
end
function (mg::MultipleGetters)(ts::Timeseries, prob, i)
    mg.((ts,), (prob,), i)
end
function (mg::MultipleGetters)(::NotTimeseries, prob)
    return map(g -> g(prob), mg.getters)
end

struct AsTupleWrapper{N, G} <: AbstractStateGetIndexer
    getter::G
end

AsTupleWrapper{N}(getter::G) where {N, G} = AsTupleWrapper{N, G}(getter)

wrap_tuple(::AsTupleWrapper{N}, val) where {N} = ntuple(i -> val[i], Val(N))

function (atw::AsTupleWrapper)(::Timeseries, prob)
    return wrap_tuple.((atw,), atw.getter(prob))
end
function (atw::AsTupleWrapper)(::Timeseries, prob, i::Union{Int, CartesianIndex})
    return wrap_tuple(atw, atw.getter(prob, i))
end
function (atw::AsTupleWrapper)(::Timeseries, prob, i)
    return wrap_tuple.((atw,), atw.getter(prob, i))
end
function (atw::AsTupleWrapper)(::NotTimeseries, prob)
    wrap_tuple(atw, atw.getter(prob))
end

for (t1, t2) in [
    (ScalarSymbolic, Any),
    (ArraySymbolic, Any),
    (NotSymbolic, Union{<:Tuple, <:AbstractArray})
]
    @eval function _getu(sys, ::NotSymbolic, ::$t1, sym::$t2)
        num_observed = count(x -> is_observed(sys, x), sym)
        if num_observed == 0 || num_observed == 1 && sym isa Tuple
            if all(Base.Fix1(is_parameter, sys), sym) &&
               all(!Base.Fix1(is_timeseries_parameter, sys), sym)
                GetpAtStateTime(getp(sys, sym))
            else
                getters = getu.((sys,), sym)
                return MultipleGetters(getters)
            end
        else
            obs = observed(sys, sym isa Tuple ? collect(sym) : sym)
            getter = if is_time_dependent(sys)
                TimeDependentObservedFunction(obs)
            else
                TimeIndependentObservedFunction(obs)
            end
            if sym isa Tuple
                getter = AsTupleWrapper{length(sym)}(getter)
            end
            return getter
        end
    end
end

function _getu(sys, ::ArraySymbolic, ::SymbolicTypeTrait, sym)
    if is_variable(sys, sym)
        idx = variable_index(sys, sym)
        return getu(sys, idx)
    elseif is_parameter(sys, sym)
        return GetpAtStateTime(getp(sys, sym))
    end
    return getu(sys, collect(sym))
end

# setu doesn't need the same `let` blocks to be inferred for some reason

"""
    setu(sys, sym)

Return a function that takes a value provider and a value, and sets the the state `sym` to
that value. Note that `sym` can be an index, a symbolic variable, or an array/tuple of the
aforementioned.

Requires that the value provider implement [`state_values`](@ref) and the returned
collection be a mutable reference to the state vector in the value provider. Alternatively,
if this is not possible or additional actions need to be performed when updating state,
[`set_state!`](@ref) can be defined. This function does not work on types for which
[`is_timeseries`](@ref) is [`Timeseries`](@ref).
"""
function setu(sys, sym)
    symtype = symbolic_type(sym)
    elsymtype = symbolic_type(eltype(sym))
    _setu(sys, symtype, elsymtype, sym)
end

struct SetStateIndex{I} <: AbstractSetIndexer
    idx::I
end

function (ssi::SetStateIndex)(prob, val)
    set_state!(prob, val, ssi.idx)
end

function _setu(sys, ::NotSymbolic, ::NotSymbolic, sym)
    return SetStateIndex(sym)
end

function _setu(sys, ::ScalarSymbolic, ::SymbolicTypeTrait, sym)
    if is_variable(sys, sym)
        idx = variable_index(sys, sym)
        return SetStateIndex(idx)
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
        return MultipleSetters(setters)
    end
end

function _setu(sys, ::ArraySymbolic, ::SymbolicTypeTrait, sym)
    if is_variable(sys, sym)
        idx = variable_index(sys, sym)
        if idx isa AbstractArray
            return MultipleSetters(SetStateIndex.(idx))
        else
            return SetStateIndex(idx)
        end
    elseif is_parameter(sys, sym)
        return setp(sys, sym)
    end
    return setu(sys, collect(sym))
end
