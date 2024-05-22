"""
    remake_buffer(indp, oldbuffer, vals::Dict)

Return a copy of the buffer `oldbuffer` with values from `vals`. The keys of `vals`
are symbolic variables whose index in the buffer is determined using `indp`. The types of
values in `vals` may not match the types of values stored at the corresponding indexes in
the buffer, in which case the type of the buffer should be promoted accordingly. In
general, this method should attempt to preserve the types of values stored in `vals` as
much as possible. Types can be promoted for type-stability, to maintain performance. The
returned buffer should be of the same type (ignoring type-parameters) as `oldbuffer`.

This method is already implemented for
`remake_buffer(indp, oldbuffer::AbstractArray, vals::Dict)` and supports static arrays
as well. It is also implemented for `oldbuffer::Tuple`.
"""
function remake_buffer(sys, oldbuffer::AbstractArray, vals::Dict)
    # similar when used with an `MArray` and nonconcrete eltype returns a
    # SizedArray. `similar_type` still returns an `MArray`
    if ArrayInterface.ismutable(oldbuffer) && !isa(oldbuffer, MArray)
        elT = Union{}
        for val in values(vals)
            if val isa AbstractArray
                valT = eltype(val)
            else
                valT = typeof(val)
            end
            elT = promote_type(elT, valT)
        end

        newbuffer = similar(oldbuffer, elT)
        copyto!(newbuffer, oldbuffer)
        for (k, v) in vals
            if v isa AbstractArray
                v = elT.(v)
            else
                v = elT(v)
            end
            setu(sys, k)(newbuffer, v)
        end
    else
        mutbuffer = remake_buffer(sys, collect(oldbuffer), vals)
        newbuffer = similar_type(oldbuffer, eltype(mutbuffer))(mutbuffer)
    end
    return newbuffer
end

mutable struct TupleRemakeWrapper
    t::Tuple
end

function set_parameter!(sys::TupleRemakeWrapper, val, idx)
    tp = sys.t
    @reset tp[idx] = val
    sys.t = tp
end

function remake_buffer(sys, oldbuffer::Tuple, vals::Dict)
    wrap = TupleRemakeWrapper(oldbuffer)
    setu(sys, collect(keys(vals)))(wrap, values(vals))
    return wrap.t
end
