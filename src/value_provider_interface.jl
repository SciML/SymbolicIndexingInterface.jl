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

parameter_values(arr::AbstractArray) = arr
parameter_values(arr::Tuple) = arr
parameter_values(arr::AbstractArray, i) = arr[i]
parameter_values(arr::Tuple, i) = arr[i]
parameter_values(prob, i) = parameter_values(parameter_values(prob), i)

"""
    parameter_values_at_time(valp, t)

Return an indexable collection containing the value of all parameters in `valp` at time
`t`. Note that `t` here is a floating-point time, and not an index into a timeseries.

This is useful for parameter timeseries objects, since some parameters change over time.
"""
function get_parameter_timeseries_collection end

"""
    with_updated_parameter_timeseries_values(valp, args::Pair...)

Return an indexable collection containing the value of all parameters in `valp`, with
parameters belonging to specific timeseries updated to different values. Each element in
`args...` contains the timeseries index as the first value, and the saved parameter values
in that partition. Not all parameter timeseries have to be updated using this method. If
an in-place update can be performed, it should be done and the modified `valp` returned.
"""
function with_updated_parameter_timeseries_values end

"""
    set_parameter!(valp, val, idx)

Set the parameter at index `idx` to `val` for value provider `valp`. This defaults to
modifying `parameter_values(valp)`. If any additional bookkeeping needs to be performed
or the default implementation does not work for a particular type, this method needs to
be defined to enable the proper functioning of [`setp`](@ref).

See: [`parameter_values`](@ref)
"""
function set_parameter! end

# Tuple only included for the error message
function set_parameter!(sys::Union{AbstractArray, Tuple}, val, idx)
    sys[idx] = val
end
set_parameter!(sys, val, idx) = set_parameter!(parameter_values(sys), val, idx)

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
`state_values(valp)[i]`. If `i` consists of multiple indices (for example, `Colon`,
`AbstractArray{Int}`, `AbstractArray{Bool}`) specialized methods may be defined for
efficiency. By default, `state_values(valp, ::Colon) = state_values(valp)` to avoid
copying the timeseries.

If this function is called with an `AbstractArray`, it will return the same array.

See: [`is_timeseries`](@ref)
"""
function state_values end

state_values(arr::AbstractArray) = arr
state_values(arr, i) = state_values(arr)[i]
state_values(arr, ::Colon) = state_values(arr)

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
argument method calls `current_time(p)[i]`. It is assumed that the timeseries is sorted
in increasing order.

If `i` consists of multiple indices (for example, `Colon`, `AbstractArray{Int}`,
`AbstractArray{Bool}`) specialized methods may be defined for efficiency. By default,
`current_time(valp, ::Colon) = current_time(valp)` to avoid copying the timeseries.

By default, the single-argument version acts as the identity function if
`valp isa AbstractVector`.

See: [`is_timeseries`](@ref)
"""
function current_time end

current_time(arr::AbstractVector) = arr
current_time(valp, i) = current_time(valp)[i]
current_time(valp, ::Colon) = current_time(valp)

###########
# Utilities
###########

abstract type AbstractIndexer end

abstract type AbstractGetIndexer <: AbstractIndexer end
abstract type AbstractStateGetIndexer <: AbstractGetIndexer end
abstract type AbstractParameterGetIndexer <: AbstractGetIndexer end
abstract type AbstractSetIndexer <: AbstractIndexer end

(ai::AbstractStateGetIndexer)(prob) = ai(is_timeseries(prob), prob)
(ai::AbstractStateGetIndexer)(prob, i) = ai(is_timeseries(prob), prob, i)
(ai::AbstractParameterGetIndexer)(prob) = ai(is_parameter_timeseries(prob), prob)
(ai::AbstractParameterGetIndexer)(prob, i) = ai(is_parameter_timeseries(prob), prob, i)
function (ai::AbstractParameterGetIndexer)(buffer::AbstractArray, prob)
    ai(buffer, is_parameter_timeseries(prob), prob)
end
function (ai::AbstractParameterGetIndexer)(buffer::AbstractArray, prob, i)
    ai(buffer, is_parameter_timeseries(prob), prob, i)
end

abstract type IsIndexerTimeseries end

struct IndexerTimeseries <: IsIndexerTimeseries end
struct IndexerNotTimeseries <: IsIndexerTimeseries end
struct IndexerBoth <: IsIndexerTimeseries end

const AtLeastTimeseriesIndexer = Union{IndexerTimeseries, IndexerBoth}
const AtLeastNotTimeseriesIndexer = Union{IndexerNotTimeseries, IndexerBoth}

is_indexer_timeseries(x) = is_indexer_timeseries(typeof(x))
function indexer_timeseries_index end

as_not_timeseries_indexer(x) = as_not_timeseries_indexer(is_indexer_timeseries(x), x)
as_not_timeseries_indexer(::IndexerNotTimeseries, x) = x
function as_not_timeseries_indexer(::IndexerTimeseries, x)
    error("""
        Tried to convert an `$IndexerTimeseries` to an `$IndexerNotTimeseries`. This \
        should never happen. Please file an issue with an MWE.
    """)
end

as_timeseries_indexer(x) = as_timeseries_indexer(is_indexer_timeseries(x), x)
as_timeseries_indexer(::IndexerTimeseries, x) = x
function as_timeseries_indexer(::IndexerNotTimeseries, x)
    error("""
        Tried to convert an `$IndexerNotTimeseries` to an `$IndexerTimeseries`. This \
        should never happen. Please file an issue with an MWE.
    """)
end

struct CallWith{A}
    args::A

    CallWith(args...) = new{typeof(args)}(args)
end

function (cw::CallWith)(arg)
    arg(cw.args...)
end

function _call(f, args...)
    return f(args...)
end

###########
# Errors
###########

struct ParameterTimeseriesValueIndexMismatchError{P <: IsTimeseriesTrait} <: Exception
    valp::Any
    indexer::Any
    args::Any

    function ParameterTimeseriesValueIndexMismatchError{Timeseries}(valp, indexer, args)
        if is_parameter_timeseries(valp) != Timeseries()
            throw(ArgumentError("""
                This should never happen. Expected parameter timeseries value provider, \
                got $(valp). Open an issue in SymbolicIndexingInterface.jl with an MWE.
            """))
        end
        if is_indexer_timeseries(indexer) != IndexerNotTimeseries()
            throw(ArgumentError("""
                This should never happen. Expected non-timeseries indexer, got \
                $(indexer). Open an issue in SymbolicIndexingInterface.jl with an MWE.
            """))
        end
        return new{Timeseries}(valp, indexer, args)
    end
    function ParameterTimeseriesValueIndexMismatchError{NotTimeseries}(valp, indexer)
        if is_parameter_timeseries(valp) != NotTimeseries()
            throw(ArgumentError("""
                This should never happen. Expected non-parameter timeseries value \
                provider, got $(valp). Open an issue in SymbolicIndexingInterface.jl \
                with an MWE.
            """))
        end
        if is_indexer_timeseries(indexer) != IndexerTimeseries()
            throw(ArgumentError("""
                This should never happen. Expected timeseries indexer, got $(indexer). \
                Open an issue in SymbolicIndexingInterface.jl with an MWE.
            """))
        end
        return new{NotTimeseries}(valp, indexer, nothing)
    end
end

function Base.showerror(io::IO, err::ParameterTimeseriesValueIndexMismatchError{Timeseries})
    print(io, """
        Invalid indexing operation: tried to access object of type $(typeof(err.valp)) \
        (which is a parameter timeseries object) with non-timeseries indexer \
        $(err.indexer) at index $(err.args) in the timeseries.
    """)
end

function Base.showerror(
        io::IO, err::ParameterTimeseriesValueIndexMismatchError{NotTimeseries})
    print(io, """
        Invalid indexing operation: tried to access object of type $(typeof(err.valp)) \
        (which is not a parameter timeseries object) using timeseries indexer \
        $(err.indexer).
    """)
end

struct MixedParameterTimeseriesIndexError <: Exception
    valp::Any
    ts_idxs::Any
end

function Base.showerror(io::IO, err::MixedParameterTimeseriesIndexError)
    print(io, """
        Invalid indexing operation: tried to access object of type $(typeof(err.valp)) \
        (which is a parameter timeseries object) with variables having mixed timeseries \
        indexes $(err.ts_idxs).
    """)
end
