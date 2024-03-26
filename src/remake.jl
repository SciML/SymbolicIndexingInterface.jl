"""
    remake_buffer(sys, oldbuffer, vals::Dict)

Return a copy of the buffer `oldbuffer` with values from `vals`. The keys of `vals`
are symbolic variables whose index in the buffer is determined using `sys`. The types of
values in `vals` may not match the types of values stored at the corresponding indexes in
the buffer, in which case the type of the buffer should be promoted accordingly. In
general, this method should attempt to preserve the types of values stored in `vals` as
much as possible. Types can be promoted for type-stability, to maintain performance. The
returned buffer should be of the same type (ignoring type-parameters) as `oldbuffer`.

This method is already implemented for
`remake_buffer(sys, oldbuffer::AbstractArray, vals::Dict)` and supports static arrays
as well.
"""
function remake_buffer(sys, oldbuffer::AbstractArray, vals::Dict)
    # similar when used with an `MArray` and nonconcrete eltype returns a
    # SizedArray. `similar_type` still returns an `MArray`
    if ArrayInterface.ismutable(oldbuffer) && !isa(oldbuffer, MArray)
        elT = Union{}
        for val in values(vals)
            elT = promote_type(elT, typeof(val))
        end

        newbuffer = similar(oldbuffer, elT)
        setu(sys, collect(keys(vals)))(newbuffer, elT.(values(vals)))
    else
        mutbuffer = remake_buffer(sys, collect(oldbuffer), vals)
        newbuffer = similar_type(oldbuffer, eltype(mutbuffer))(mutbuffer)
    end
    return newbuffer
end
