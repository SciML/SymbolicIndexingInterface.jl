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

Return a function that takes an array representing the parameter vector or an integrator
or solution of `sys`, and returns the value of the parameter `p`. Note that `p` can be a
direct index or a symbolic value, or an array/tuple of the aforementioned.

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
    return function getter(sol)
        return parameter_values(sol, p)
    end
end

function _getp(sys, ::ScalarSymbolic, ::SymbolicTypeTrait, p)
    idx = parameter_index(sys, p)
    return let idx = idx
        function getter(sol)
            return parameter_values(sol, idx)
        end
    end
end

for (t1, t2) in [
    (ArraySymbolic, Any),
    (ScalarSymbolic, Any),
    (NotSymbolic, Union{<:Tuple, <:AbstractArray})
]
    @eval function _getp(sys, ::NotSymbolic, ::$t1, p::$t2)
        getters = getp.((sys,), p)

        return let getters = getters
            function getter(sol)
                map(g -> g(sol), getters)
            end
            function getter(buffer, sol)
                for (i, g) in zip(eachindex(buffer), getters)
                    buffer[i] = g(sol)
                end
                buffer
            end
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
