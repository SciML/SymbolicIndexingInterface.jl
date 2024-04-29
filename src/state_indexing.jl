"""
    state_values(p)
    state_values(p, i)

Return an indexable collection containing the values of all states in the integrator or
problem `p`. If `is_timeseries(p)` is [`Timeseries`](@ref), return a vector of arrays,
each of which contain the state values at the corresponding timestep. In this case, the
two-argument version of the function can also be implemented to efficiently return
the state values at timestep `i`. By default, the two-argument method calls
`state_values(p)[i]`

If this function is called with an `AbstractArray`, it will return the same array.

See: [`is_timeseries`](@ref)
"""
function state_values end
state_values(arr::AbstractArray) = arr
state_values(arr, i) = state_values(arr)[i]

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
    current_time(p, i)

Return the current time in the integrator or problem `p`. If
`is_timeseries(p)` is [`Timeseries`](@ref), return the vector of timesteps at which
the state value is saved. In this case, the two-argument version of the function can
also be implemented to efficiently return the time at timestep `i`. By default, the two-
argument method calls `current_time(p)[i]`

See: [`is_timeseries`](@ref)
"""
function current_time end

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

function _getu(sys, ::NotSymbolic, ::NotSymbolic, sym)
    _getter(::Timeseries, prob) = getindex.(state_values(prob), (sym,))
    _getter(::Timeseries, prob, i) = getindex(state_values(prob, i), sym)
    _getter(::NotTimeseries, prob) = state_values(prob, sym)
    return let _getter = _getter
        function getter(prob)
            return _getter(is_timeseries(prob), prob)
        end
        function getter(prob, i)
            return _getter(is_timeseries(prob), prob, i)
        end
        getter
    end
end

function _getu(sys, ::ScalarSymbolic, ::SymbolicTypeTrait, sym)
    if is_variable(sys, sym)
        idx = variable_index(sys, sym)
        return getu(sys, idx)
    elseif is_parameter(sys, sym)
        return let fn = getp(sys, sym)
            _getter_p(::NotTimeseries, prob) = fn(prob)
            function _getter_p(::Timeseries, prob)
                [fn(parameter_values_at_state_time(prob, i))
                 for i in eachindex(current_time(prob))]
            end
            _getter_p(::Timeseries, prob, i) = fn(parameter_values_at_state_time(prob, i))
            let _getter = _getter_p
                getter(prob, args...) = _getter(is_timeseries(prob), prob, args...)
                getter
            end
        end
    elseif is_independent_variable(sys, sym)
        _getter(::IsTimeseriesTrait, prob) = current_time(prob)
        _getter(::Timeseries, prob, i) = current_time(prob, i)
        return let _getter = _getter
            getter(prob) = _getter(is_timeseries(prob), prob)
            getter(prob, i) = _getter(is_timeseries(prob), prob, i)
            getter
        end
    elseif is_observed(sys, sym)
        fn = observed(sys, sym)
        if is_time_dependent(sys)
            function _getter2(::Timeseries, prob)
                curtime = current_time(prob)
                return fn.(state_values(prob),
                    (parameter_values_at_state_time(prob, i) for i in eachindex(curtime)),
                    curtime)
            end
            function _getter2(::Timeseries, prob, i)
                return fn(state_values(prob, i),
                    parameter_values_at_state_time(prob, i),
                    current_time(prob, i))
            end
            function _getter2(::NotTimeseries, prob)
                return fn(state_values(prob), parameter_values(prob), current_time(prob))
            end

            return let _getter2 = _getter2
                function getter2(prob)
                    return _getter2(is_timeseries(prob), prob)
                end
                function getter2(prob, i)
                    return _getter2(is_timeseries(prob), prob, i)
                end
                getter2
            end
        else
            # if there is no time, there is no timeseries
            return let fn = fn
                function getter3(prob)
                    return fn(state_values(prob), parameter_values(prob))
                end
            end
        end
    end
    error("Invalid symbol $sym for `getu`")
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
            _call(getter, args...) = getter(args...)
            return let getters = getters, _call = _call
                _getter(::NotTimeseries, prob) = map(g -> g(prob), getters)
                function _getter(::Timeseries, prob)
                    broadcast(i -> map(g -> _call(g, prob, i), getters),
                        eachindex(state_values(prob)))
                end
                function _getter(::Timeseries, prob, i)
                    return map(g -> _call(g, prob, i), getters)
                end

                # Need another scope for this to not box `_getter`
                let _getter = _getter
                    function getter(prob)
                        return _getter(is_timeseries(prob), prob)
                    end
                    function getter(prob, i)
                        return _getter(is_timeseries(prob), prob, i)
                    end
                    getter
                end
            end
        else
            obs = observed(sys, sym isa Tuple ? collect(sym) : sym)
            _getter2 = if is_time_dependent(sys)
                let obs = obs, is_tuple = sym isa Tuple
                    function _getter2a(::NotTimeseries, prob)
                        obs(state_values(prob), parameter_values(prob), current_time(prob))
                    end
                    function _getter2a(::Timeseries, prob)
                        curtime = current_time(prob)
                        obs.(state_values(prob),
                            (parameter_values_at_state_time(prob, i)
                            for i in eachindex(curtime)),
                            curtime)
                    end
                    function _getter2a(::Timeseries, prob, i)
                        obs(state_values(prob, i),
                            parameter_values_at_state_time(prob, i),
                            current_time(prob, i))
                    end
                    _getter2a
                end
            else
                let obs = obs
                    function _getter2b(::NotTimeseries, prob)
                        obs(state_values(prob), parameter_values(prob))
                    end
                    _getter2b
                end
            end
            return if sym isa Tuple
                let _getter2 = _getter2
                    function getter2(prob)
                        Tuple(_getter2(is_timeseries(prob), prob))
                    end
                    function getter2(prob, i)
                        Tuple(_getter2(is_timeseries(prob), prob, i))
                    end
                    getter2
                end
            else
                let _getter2 = _getter2
                    function getter3(prob)
                        _getter2(is_timeseries(prob), prob)
                    end
                    function getter3(prob, i)
                        _getter2(is_timeseries(prob), prob, i)
                    end
                    getter3
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
