"""
    parameter_values(p)
    parameter_values(p, i)

Return an indexable collection containing the value of each parameter in `p`. The two-
argument version of this function returns the parameter value at index `i`. The
two-argument version of this function will default to returning
`parameter_values(p)[i]`.

If this function is called with an `AbstractArray`, it will return the same array.
"""
function parameter_values end

parameter_values(arr::AbstractArray) = arr
parameter_values(arr::AbstractArray, i) = arr[i]
parameter_values(prob, i) = parameter_values(parameter_values(prob), i)

"""
    parameter_values_at_time(p, i)

Return an indexable collection containing the value of all parameters in `p` at time index
`i`. This is useful when parameter values change during the simulation
(such as through callbacks) and their values are saved. `i` is the time index in the
timeseries formed by these changing parameter values, obtained using
[`parameter_timeseries`](@ref).

By default, this function returns `parameter_values(p)` regardless of `i`, and only needs
to be specialized for timeseries objects where parameter values are not constant at all
times. The resultant object should be indexable using [`parameter_values`](@ref).

If this function is implemented, [`parameter_values_at_state_time`](@ref) must be 
implemented for [`getu`](@ref) to work correctly.
"""
function parameter_values_at_time end
parameter_values_at_time(p, i) = parameter_values(p)

"""
    parameter_values_at_state_time(p, i)

Return an indexable collection containing the value of all parameters in `p` at time
index `i`. This is useful when parameter values change during the simulation (such as
through callbacks) and their values are saved. `i` is the time index in the timeseries
formed by dependent variables (as opposed to the timeseries of the parameters, as in
[`parameter_values_at_time`](@ref)).

By default, this function returns `parameter_values(p)` regardless of `i`, and only needs
to be specialized for timeseries objects where parameter values are not constant at
all times. The resultant object should be indexable using [`parameter_values`](@ref).

If this function is implemented, [`parameter_values_at_time`](@ref) must be implemented for
[`getp`](@ref) to work correctly.
"""
function parameter_values_at_state_time end
parameter_values_at_state_time(p, i) = parameter_values(p)

"""
    parameter_timeseries(p)

Return an iterable of time steps at which the parameter values are saved. This is only
required for objects where `is_timeseries(p) === Timeseries()` and the parameter values
change during the simulation (such as through callbacks). By default, this returns `[0]`.

See also: [`parameter_values_at_time`](@ref).
"""
function parameter_timeseries end
parameter_timeseries(_) = [0]

"""
    set_parameter!(sys, val, idx)

Set the parameter at index `idx` to `val` for system `sys`. This defaults to modifying
`parameter_values(sys)`. If any additional bookkeeping needs to be performed or the
default implementation does not work for a particular type, this method needs to be
defined to enable the proper functioning of [`setp`](@ref).

See: [`parameter_values`](@ref)
"""
function set_parameter! end

function set_parameter!(sys::AbstractArray, val, idx)
    sys[idx] = val
end
set_parameter!(sys, val, idx) = set_parameter!(parameter_values(sys), val, idx)

"""
    getp(sys, p)

Return a function that takes an array representing the parameter object or an integrator
or solution of `sys`, and returns the value of the parameter `p`. Note that `p` can be a
direct index or a symbolic value, or an array/tuple of the aforementioned.

If `p` is an array/tuple of parameters, then the returned function can also be used
as an in-place getter function. The first argument is the buffer to which the parameter
values should be written, and the second argument is the parameter object/integrator/
solution from which the values are obtained.

Requires that the integrator or solution implement [`parameter_values`](@ref). This function
typically does not need to be implemented, and has a default implementation relying on
[`parameter_values`](@ref).
"""
function getp(sys, p)
    symtype = symbolic_type(p)
    elsymtype = symbolic_type(eltype(p))
    _getp(sys, symtype, elsymtype, p)
end

function _getp(sys, ::NotSymbolic, ::NotSymbolic, p)
    _getter = let p = p
        function _getter(::NotTimeseries, prob)
            parameter_values(prob, p)
        end
        function _getter(::Timeseries, prob)
            parameter_values(prob, p)
        end
        function _getter(::Timeseries, prob, i)
            parameter_values(parameter_values_at_time(prob, i), p)
        end
        function _getter(::Timeseries, prob, ::Colon)
            parameter_values.((parameter_values_at_time(prob, i) for i in eachindex(parameter_timeseries(prob))), (p,))
        end
    end
    return let _getter = _getter
        function getter(prob, args...)
            return _getter(is_timeseries(prob), prob, args...)
        end
    end
end

function _getp(sys, ::ScalarSymbolic, ::SymbolicTypeTrait, p)
    idx = parameter_index(sys, p)
    return getp(sys, idx)
end

for (t1, t2) in [
    (ArraySymbolic, Any),
    (ScalarSymbolic, Any),
    (NotSymbolic, Union{<:Tuple, <:AbstractArray})
]
    @eval function _getp(sys, ::NotSymbolic, ::$t1, p::$t2)
        getters = getp.((sys,), p)

        _getter = return let getters = getters
            function _getter(::NotTimeseries, prob)
                map(g -> g(prob), getters)
            end
            function _getter(::Timeseries, prob)
                map(g -> g(prob), getters)
            end
            function _getter(::Timeseries, prob, i)
                map(g -> g(prob, i), getters)
            end
            function _getter(::Timeseries, prob, ::Colon)
                [map(g -> g(prob, i), getters) for i in eachindex(parameter_timeseries(prob))]
            end
            function _getter(buffer, ::NotTimeseries, prob)
                map!(g -> g(prob), buffer, getters)
            end
            function _getter(buffer, ::Timeseries, prob)
                map!(g -> g(prob), buffer, getters)
            end
            function _getter(buffer, ::Timeseries, prob, i)
                map!(g -> g(prob, i), buffer, getters)
            end
            function _getter(buffer, ::Timeseries, prob, ::Colon)
                for (bufi, tsi) in zip(eachindex(buffer), eachindex(parameter_timeseries(prob)))
                    map!(g -> g(prob, tsi), buffer[bufi], getters)
                end
                buffer
            end
            _getter
        end

        return let _getter = _getter
            function getter(prob, i...)
                return _getter(is_timeseries(prob), prob, i...)
            end
            function getter(buffer::AbstractArray, prob, i...)
                return _getter(buffer, is_timeseries(prob), prob, i...)
            end
            getter
        end
    end
end

function _getp(sys, ::ArraySymbolic, ::NotSymbolic, p)
    return getp(sys, collect(p))
end

"""
    setp(sys, p)

Return a function that takes an array representing the parameter vector or an integrator
or problem of `sys`, and a value, and sets the parameter `p` to that value. Note that `p`
can be a direct index or a symbolic value.

Requires that the integrator implement [`parameter_values`](@ref) and the returned
collection be a mutable reference to the parameter vector in the integrator. In
case `parameter_values` cannot return such a mutable reference, or additional actions
need to be performed when updating parameters, [`set_parameter!`](@ref) must be
implemented.
"""
function setp(sys, p)
    symtype = symbolic_type(p)
    elsymtype = symbolic_type(eltype(p))
    _setp(sys, symtype, elsymtype, p)
end

function _setp(sys, ::NotSymbolic, ::NotSymbolic, p)
    return function setter!(sol, val)
        set_parameter!(sol, val, p)
    end
end

function _setp(sys, ::ScalarSymbolic, ::SymbolicTypeTrait, p)
    idx = parameter_index(sys, p)
    return function setter!(sol, val)
        set_parameter!(sol, val, idx)
    end
end

for (t1, t2) in [
    (ArraySymbolic, Any),
    (ScalarSymbolic, Any),
    (NotSymbolic, Union{<:Tuple, <:AbstractArray})
]
    @eval function _setp(sys, ::NotSymbolic, ::$t1, p::$t2)
        setters = setp.((sys,), p)
        return function setter!(sol, val)
            map((s!, v) -> s!(sol, v), setters, val)
        end
    end
end

function _setp(sys, ::ArraySymbolic, ::NotSymbolic, p)
    return setp(sys, collect(p))
end
