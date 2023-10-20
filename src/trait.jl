abstract type IsSymbolicTrait end

"""
    struct Symbolic <: IsSymbolicTrait end

Trait indicating a type is symbolic.

See also: [`NotSymbolic`](@ref), [`issymbolic`](@ref)
"""
struct Symbolic <: IsSymbolicTrait end

"""
    struct NotSymbolic <: IsSymbolicTrait end

Trait indicating a type is not symbolic.

See also: [`Symbolic`](@ref), [`issymbolic`](@ref)
"""
struct NotSymbolic <: IsSymbolicTrait end

"""
    issymbolic(x) = issymbolic(typeof(x))
    issymbolic(::Type)

Check whether a type implements the [`Symbolic`](@ref) trait or not. Default to
[`NotSymbolic`](@ref) for all types except `Symbol`.
"""
issymbolic(x) = issymbolic(typeof(x))
issymbolic(::Type) = NotSymbolic()
issymbolic(::Type{Symbol}) = Symbolic()
