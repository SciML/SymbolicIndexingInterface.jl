###########
# Parameter Indexing
###########

"""
    parameter_values(valp)
    parameter_values(valp, i)

Return an indexable collection containing the value of each parameter in `valp`. The two-
argument version of this function returns the parameter value at index `i`. The
two-argument version of this function will default to returning
`parameter_values(valp)[i]`.

If this function is called with an `AbstractArray` or `Tuple`, it will return the same
array/tuple.
"""
function parameter_values end

"""
    parameter_values_at_time(valp, i)

Return an indexable collection containing the value of all parameters in `valp` at time
index `i`. This is useful when parameter values change during the simulation (such as
through callbacks) and their values are saved. `i` is the time index in the timeserie
 formed by these changing parameter values, obtained using [`parameter_timeseries`](@ref).

By default, this function returns `parameter_values(valp)` regardless of `i`, and only needs
to be specialized for timeseries objects where parameter values are not constant at all
times. The resultant object should be indexable using [`parameter_values`](@ref).

If this function is implemented, [`parameter_values_at_state_time`](@ref) must be 
implemented for [`getu`](@ref) to work correctly.
"""
function parameter_values_at_time end

"""
    parameter_values_at_state_time(valp, i)

Return an indexable collection containing the value of all parameters in `valp` at time
index `i`. This is useful when parameter values change during the simulation (such as
through callbacks) and their values are saved. `i` is the time index in the timeseries
formed by dependent variables (as opposed to the timeseries of the parameters, as in
[`parameter_values_at_time`](@ref)).

By default, this function returns `parameter_values(valp)` regardless of `i`, and only
needs to be specialized for timeseries objects where parameter values are not constant at
all times. The resultant object should be indexable using [`parameter_values`](@ref).

If this function is implemented, [`parameter_values_at_time`](@ref) must be implemented for
[`getp`](@ref) to work correctly.
"""
function parameter_values_at_state_time end

"""
    parameter_timeseries(valp)

Return an iterable of time steps at which the parameter values are saved. This is only
required for objects where `is_timeseries(valp) === Timeseries()` and the parameter values
change during the simulation (such as through callbacks). By default, this returns `[0]`.

See also: [`parameter_values_at_time`](@ref).
"""
function parameter_timeseries end

"""
    set_parameter!(valp, val, idx)

Set the parameter at index `idx` to `val` for value provider `valp`. This defaults to
modifying `parameter_values(valp)`. If any additional bookkeeping needs to be performed
or the default implementation does not work for a particular type, this method needs to
be defined to enable the proper functioning of [`setp`](@ref).

See: [`parameter_values`](@ref)
"""
function set_parameter! end

"""
    finalize_parameters_hook!(valp, sym)

This is a callback run one for each call to the function returned by [`setp`](@ref)
which can be used to update internal data structures when parameters are modified.
This is in contrast to [`set_parameter!`](@ref) which is run once for each parameter
that is updated.
"""
finalize_parameters_hook!(valp, sym) = nothing

###########
# State Indexing
###########

"""
    state_values(valp)
    state_values(valp, i)

Return an indexable collection containing the values of all states in the value provider
`p`. If `is_timeseries(valp)` is [`Timeseries`](@ref), return a vector of arrays,
each of which contain the state values at the corresponding timestep. In this case, the
two-argument version of the function can also be implemented to efficiently return
the state values at timestep `i`. By default, the two-argument method calls
`state_values(valp)[i]`

If this function is called with an `AbstractArray`, it will return the same array.

See: [`is_timeseries`](@ref)
"""
function state_values end

"""
    set_state!(valp, val, idx)

Set the state at index `idx` to `val` for value provider `valp`. This defaults to modifying
`state_values(valp)`. If any additional bookkeeping needs to be performed or the
default implementation does not work for a particular type, this method needs to be
defined to enable the proper functioning of [`setu`](@ref).

See: [`state_values`](@ref)
"""
function set_state! end

"""
    current_time(valp)
    current_time(valp, i)

Return the current time in the value provider `valp`. If
`is_timeseries(valp)` is [`Timeseries`](@ref), return the vector of timesteps at which
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

abstract type AbstractGetIndexer <: AbstractIndexer end
abstract type AbstractSetIndexer <: AbstractIndexer end

(ai::AbstractGetIndexer)(prob) = ai(is_timeseries(prob), prob)
(ai::AbstractGetIndexer)(prob, i) = ai(is_timeseries(prob), prob, i)
