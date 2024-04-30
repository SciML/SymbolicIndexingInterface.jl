###########
# Parameter Indexing
###########

"""
    parameter_values(p)
    parameter_values(p, i)

Return an indexable collection containing the value of each parameter in `p`. The two-
argument version of this function returns the parameter value at index `i`. The
two-argument version of this function will default to returning
`parameter_values(p)[i]`.

If this function is called with an `AbstractArray` or `Tuple`, it will return the same
array/tuple.
"""
function parameter_values end

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

"""
    parameter_timeseries(p)

Return an iterable of time steps at which the parameter values are saved. This is only
required for objects where `is_timeseries(p) === Timeseries()` and the parameter values
change during the simulation (such as through callbacks). By default, this returns `[0]`.

See also: [`parameter_values_at_time`](@ref).
"""
function parameter_timeseries end

"""
    set_parameter!(sys, val, idx)

Set the parameter at index `idx` to `val` for system `sys`. This defaults to modifying
`parameter_values(sys)`. If any additional bookkeeping needs to be performed or the
default implementation does not work for a particular type, this method needs to be
defined to enable the proper functioning of [`setp`](@ref).

See: [`parameter_values`](@ref)
"""
function set_parameter! end

"""
    finalize_parameters_hook!(prob, p)

This is a callback run one for each call to the function returned by [`setp`](@ref)
which can be used to update internal data structures when parameters are modified.
This is in contrast to [`set_parameter!`](@ref) which is run once for each parameter
that is updated.
"""
finalize_parameters_hook!(prob, p) = nothing

###########
# State Indexing
###########

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

"""
    set_state!(sys, val, idx)

Set the state at index `idx` to `val` for system `sys`. This defaults to modifying
`state_values(sys)`. If any additional bookkeeping needs to be performed or the
default implementation does not work for a particular type, this method needs to be
defined to enable the proper functioning of [`setu`](@ref).

See: [`state_values`](@ref)
"""
function set_state! end

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

###########
# Utilities
###########

abstract type AbstractIndexer end

(ai::AbstractIndexer)(prob) = ai(is_timeseries(prob), prob)
(ai::AbstractIndexer)(prob, i) = ai(is_timeseries(prob), prob, i)
