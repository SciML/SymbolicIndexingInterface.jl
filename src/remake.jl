"""
    remake_buffer(indp, oldbuffer, idxs, vals)

Return a copy of the buffer `oldbuffer` with at (optionally symbolic) indexes `idxs`
replaced by corresponding values from `vals`. Both `idxs` and `vals` must be iterables of
the same length. `idxs` may contain symbolic variables whose index in the buffer is
determined using `indp`. The types of values in `vals` may not match the types of values
stored at the corresponding indexes in the buffer, in which case the type of the buffer
should be promoted accordingly. In general, this method should attempt to preserve the
types of values stored in `vals` as much as possible. Types can be promoted for
type-stability, to maintain performance. The returned buffer should be of the same type
(ignoring type-parameters) as `oldbuffer`.

This method is already implemented for `oldbuffer::AbstractArray` and `oldbuffer::Tuple`,
and supports static arrays as well.

The deprecated version of this method which takes a `Dict` mapping symbols to values
instead of `idxs` and `vals` will dispatch to the new method. In addition, if no
4-arg `remake_buffer` method exists for the buffer type, the generic 4-arg fallback
calls `remake_buffer(sys, oldbuffer, Dict(idxs .=> vals))` so packages that only
implemented the deprecated 3-arg `Dict` API still work (including methods typed more
narrowly than `Dict`, e.g. `Dict{Symbol,Float64}`). If that call re-enters this
fallback through SII's own deprecated catch-all, an `ArgumentError` is thrown naming
the buffer type instead of recursing.

Note that the new method signature allows `idxs` to be indexes, instead of requiring
that they be symbolic variables. Thus, any type which implements the new method must
also support indexes in `idxs`.
"""
function remake_buffer(sys, oldbuffer::AbstractArray, idxs, vals)
    # `similar` can change an `MArray` into a `SizedArray` for nonconcrete element types.
    if ArrayInterface.ismutable(oldbuffer) && !isa(oldbuffer, MArray)
        elT = Union{}
        for val in vals
            if val isa AbstractArray
                valT = eltype(val)
            else
                valT = typeof(val)
            end
            elT = promote_type(elT, valT)
        end

        newbuffer = similar(oldbuffer, elT)
        copyto!(newbuffer, oldbuffer)
        for (k, v) in zip(idxs, vals)
            is_variable(sys, k) || is_parameter(sys, k) || continue
            if v isa AbstractArray
                v = elT.(v)
            else
                v = elT(v)
            end
            setsym(sys, k)(newbuffer, v)
        end
    else
        mutbuffer = remake_buffer(sys, collect(oldbuffer), idxs, vals)
        newbuffer = similar_type(oldbuffer, eltype(mutbuffer))(mutbuffer)
    end
    return newbuffer
end

# We don't support `Dict`s as value providers. If we get a `Dict`,
# assume it is non-symbolic.
function remake_buffer(sys, oldbuffer::Dict, idxs, vals)
    return Dict(idxs .=> vals)
end

remake_buffer(sys, ::Nothing, idxs, vals) = nothing

const _REMAKE_BUFFER_DICT_FALLBACK = :__SII_remake_buffer_dict_fallback__

function remake_buffer(sys, oldbuffer, idxs, vals)
    # Preserve master's Dict dispatch for deprecated 3-arg implementers. Detect
    # re-entry from SII's own @deprecate catch-all instead of reflecting with `which`.
    if get(task_local_storage(), _REMAKE_BUFFER_DICT_FALLBACK, false)
        throw(
            ArgumentError(
                "remake_buffer is not implemented for buffer type $(typeof(oldbuffer)); define a method `remake_buffer(::Any, ::$(typeof(oldbuffer)), idxs, vals)`"
            )
        )
    end
    return task_local_storage(_REMAKE_BUFFER_DICT_FALLBACK, true) do
        remake_buffer(sys, oldbuffer, Dict(idxs .=> vals))
    end
end

mutable struct TupleRemakeWrapper
    t::Tuple
end

function set_parameter!(sys::TupleRemakeWrapper, val, idx)
    tp = sys.t
    @reset tp[idx] = val
    return sys.t = tp
end

function set_state!(sys::TupleRemakeWrapper, val, idx)
    tp = sys.t
    @reset tp[idx] = val
    return sys.t = tp
end

function remake_buffer(sys, oldbuffer::Tuple, idxs, vals)
    wrap = TupleRemakeWrapper(oldbuffer)
    for (idx, val) in zip(idxs, vals)
        setsym(sys, idx)(wrap, val)
    end
    return wrap.t
end

@deprecate remake_buffer(sys, oldbuffer, vals::Dict) remake_buffer(
    sys, oldbuffer, keys(vals), values(vals)
)
@deprecate remake_buffer(sys, oldbuffer::Tuple, vals::Dict) remake_buffer(
    sys, oldbuffer, keys(vals), values(vals)
)
