parameter_values(arr::AbstractArray) = arr
parameter_values(arr::Tuple) = arr
parameter_values(arr::AbstractArray, i) = arr[i]
parameter_values(arr::Tuple, i) = arr[i]
parameter_values(prob, i) = parameter_values(parameter_values(prob), i)

parameter_values_at_time(p, i) = parameter_values(p)

parameter_values_at_state_time(p, i) = parameter_values(p)

parameter_timeseries(_) = [0]

# Tuple only included for the error message
function set_parameter!(sys::Union{AbstractArray, Tuple}, val, idx)
    sys[idx] = val
end
set_parameter!(sys, val, idx) = set_parameter!(parameter_values(sys), val, idx)

"""
    getp(indp, sym)

Return a function that takes an value provider, and returns the value of the
parameter `sym`. The value provider has to at least store the values of parameters
in the corresponding index provider. Note that `sym` can be an index, symbolic variable,
or an array/tuple of the aforementioned.

If `sym` is an array/tuple of parameters, then the returned function can also be used
as an in-place getter function. The first argument is the buffer (must be an
`AbstractArray`) to which the parameter values should be written, and the second argument
is the value provider.

Requires that the value provider implement [`parameter_values`](@ref). This function
may not always need to be implemented, and has a default implementation for collections
that implement `getindex`.

If the returned function is used on a timeseries object which saves parameter timeseries, it
can be used to index said timeseries. The timeseries object must implement
[`parameter_timeseries`](@ref), [`parameter_values_at_time`](@ref) and
[`parameter_values_at_state_time`](@ref). The function returned from `getp` will can be passed
`Colon()` (`:`) as the last argument to return the entire parameter timeseries for `p`, or
any index into the parameter timeseries for a subset of values.
"""
function getp(sys, p)
    symtype = symbolic_type(p)
    elsymtype = symbolic_type(eltype(p))
    _getp(sys, symtype, elsymtype, p)
end

struct GetParameterIndex{I} <: AbstractGetIndexer
    idx::I
end

function (gpi::GetParameterIndex)(::IsTimeseriesTrait, prob)
    parameter_values(prob, gpi.idx)
end
function (gpi::GetParameterIndex)(::Timeseries, prob, i::Union{Int, CartesianIndex})
    parameter_values(
        parameter_values_at_time(
            prob, only(to_indices(parameter_timeseries(prob), (i,)))),
        gpi.idx)
end
function (gpi::GetParameterIndex)(::Timeseries, prob, i::Union{AbstractArray{Bool}, Colon})
    parameter_values.(
        parameter_values_at_time.((prob,),
            (j for j in only(to_indices(parameter_timeseries(prob), (i,))))),
        (gpi.idx,))
end
function (gpi::GetParameterIndex)(::Timeseries, prob, i)
    parameter_values.(parameter_values_at_time.((prob,), i), (gpi.idx,))
end

function _getp(sys, ::NotSymbolic, ::NotSymbolic, p)
    return GetParameterIndex(p)
end

function _getp(sys, ::ScalarSymbolic, ::SymbolicTypeTrait, p)
    idx = parameter_index(sys, p)
    return invoke(_getp, Tuple{Any, NotSymbolic, NotSymbolic, Any},
        sys, NotSymbolic(), NotSymbolic(), idx)
end

struct MultipleParameterGetters{G} <: AbstractGetIndexer
    getters::G
end

function (mpg::MultipleParameterGetters)(::IsTimeseriesTrait, prob)
    map(g -> g(prob), mpg.getters)
end
function (mpg::MultipleParameterGetters)(::Timeseries, prob, i::Union{Int, CartesianIndex})
    map(g -> g(prob, i), mpg.getters)
end
function (mpg::MultipleParameterGetters)(::Timeseries, prob, i)
    [map(g -> g(prob, j), mpg.getters)
     for j in only(to_indices(parameter_timeseries(prob), (i,)))]
end
function (mpg::MultipleParameterGetters)(buffer::AbstractArray, ::Timeseries, prob)
    for (g, bufi) in zip(mpg.getters, eachindex(buffer))
        buffer[bufi] = g(prob)
    end
    buffer
end
function (mpg::MultipleParameterGetters)(
        buffer::AbstractArray, ::Timeseries, prob, i::Union{Int, CartesianIndex})
    for (g, bufi) in zip(mpg.getters, eachindex(buffer))
        buffer[bufi] = g(prob, i)
    end
    buffer
end
function (mpg::MultipleParameterGetters)(buffer::AbstractArray, ::Timeseries, prob, i)
    for (bufi, tsi) in zip(
        eachindex(buffer), only(to_indices(parameter_timeseries(prob), (i,))))
        for (g, bufj) in zip(mpg.getters, eachindex(buffer[bufi]))
            buffer[bufi][bufj] = g(prob, tsi)
        end
    end
    buffer
end
function (mpg::MultipleParameterGetters)(buffer::AbstractArray, ::NotTimeseries, prob)
    for (g, bufi) in zip(mpg.getters, eachindex(buffer))
        buffer[bufi] = g(prob)
    end
    buffer
end

function (mpg::MultipleParameterGetters)(buffer::AbstractArray, prob, i...)
    mpg(buffer, is_timeseries(prob), prob, i...)
end
function (mpg::MultipleParameterGetters)(prob, i...)
    mpg(is_timeseries(prob), prob, i...)
end

for (t1, t2) in [
    (ArraySymbolic, Any),
    (ScalarSymbolic, Any),
    (NotSymbolic, Union{<:Tuple, <:AbstractArray})
]
    @eval function _getp(sys, ::NotSymbolic, ::$t1, p::$t2)
        getters = getp.((sys,), p)
        return MultipleParameterGetters(getters)
    end
end

function _getp(sys, ::ArraySymbolic, ::NotSymbolic, p)
    if is_parameter(sys, p)
        idx = parameter_index(sys, p)
        return invoke(_getp, Tuple{Any, NotSymbolic, NotSymbolic, Any},
            sys, NotSymbolic(), NotSymbolic(), idx)
    end
    return getp(sys, collect(p))
end

struct ParameterHookWrapper{S, O} <: AbstractSetIndexer
    setter::S
    original_index::O
end

function (phw::ParameterHookWrapper)(prob, args...)
    res = phw.setter(prob, args...)
    finalize_parameters_hook!(prob, phw.original_index)
    res
end

"""
    setp(indp, sym)

Return a function that takes an index provider and a value, and sets the parameter `sym`
to that value. Note that `sym` can be an index, a symbolic variable, or an array/tuple of
the aforementioned.

Requires that the value provider implement [`parameter_values`](@ref) and the returned
collection be a mutable reference to the parameter object. In case `parameter_values`
cannot return such a mutable reference, or additional actions need to be performed when
updating parameters, [`set_parameter!`](@ref) must be implemented.
"""
function setp(sys, p; run_hook = true)
    symtype = symbolic_type(p)
    elsymtype = symbolic_type(eltype(p))
    return if run_hook
        return ParameterHookWrapper(_setp(sys, symtype, elsymtype, p), p)
    else
        _setp(sys, symtype, elsymtype, p)
    end
end

struct SetParameterIndex{I} <: AbstractSetIndexer
    idx::I
end

function (spi::SetParameterIndex)(prob, val)
    set_parameter!(prob, val, spi.idx)
end

function _setp(sys, ::NotSymbolic, ::NotSymbolic, p)
    return SetParameterIndex(p)
end

function _setp(sys, ::ScalarSymbolic, ::SymbolicTypeTrait, p)
    idx = parameter_index(sys, p)
    return SetParameterIndex(idx)
end

struct MultipleSetters{S} <: AbstractSetIndexer
    setters::S
end

function (ms::MultipleSetters)(prob, val)
    map((s!, v) -> s!(prob, v), ms.setters, val)
end

for (t1, t2) in [
    (ArraySymbolic, Any),
    (ScalarSymbolic, Any),
    (NotSymbolic, Union{<:Tuple, <:AbstractArray})
]
    @eval function _setp(sys, ::NotSymbolic, ::$t1, p::$t2)
        setters = setp.((sys,), p; run_hook = false)
        return MultipleSetters(setters)
    end
end

function _setp(sys, ::ArraySymbolic, ::NotSymbolic, p)
    if is_parameter(sys, p)
        idx = parameter_index(sys, p)
        return setp(sys, idx; run_hook = false)
    end
    return setp(sys, collect(p); run_hook = false)
end
