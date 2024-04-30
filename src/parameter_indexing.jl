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

struct GetParameterIndex{I} <: AbstractIndexer
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

struct MultipleParameterGetters{G}
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
function setp(sys, p; run_hook = true)
    symtype = symbolic_type(p)
    elsymtype = symbolic_type(eltype(p))
    return if run_hook
        let _setter! = _setp(sys, symtype, elsymtype, p), p = p
            function setter!(prob, args...)
                res = _setter!(prob, args...)
                finalize_parameters_hook!(prob, p)
                res
            end
        end
    else
        _setp(sys, symtype, elsymtype, p)
    end
end

function _setp(sys, ::NotSymbolic, ::NotSymbolic, p)
    return let p = p
        function setter!(sol, val)
            set_parameter!(sol, val, p)
        end
    end
end

function _setp(sys, ::ScalarSymbolic, ::SymbolicTypeTrait, p)
    idx = parameter_index(sys, p)
    return let idx = idx
        function setter!(sol, val)
            set_parameter!(sol, val, idx)
        end
    end
end

for (t1, t2) in [
    (ArraySymbolic, Any),
    (ScalarSymbolic, Any),
    (NotSymbolic, Union{<:Tuple, <:AbstractArray})
]
    @eval function _setp(sys, ::NotSymbolic, ::$t1, p::$t2)
        setters = setp.((sys,), p; run_hook = false)
        return let setters = setters
            function setter!(sol, val)
                map((s!, v) -> s!(sol, v), setters, val)
            end
        end
    end
end

function _setp(sys, ::ArraySymbolic, ::NotSymbolic, p)
    return setp(sys, collect(p); run_hook = false)
end
