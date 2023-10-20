module SymbolicIndexingInterface

export Symbolic, NotSymbolic, issymbolic, isvariable, variableindex, isparameter,
    parameterindex, isindependent_variable, isobserved, observed, istimedependent,
    constant_structure

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

"""
    isvariable(sys, sym)

Check whether the given `sym` is a variable in `sys`.
"""
function isvariable end

"""
    variableindex(sys, sym)

Return the index of the given variable `sym` in `sys`, or `nothing` otherwise.
"""
function variableindex end

"""
    isparameter(sys, sym)

Check whether the given `sym` is a parameter in `sys`.
"""
function isparameter end

"""
    parameterindex(sys, sym)

Return the index of the given parameter `sym` in `sys`, or `nothing` otherwise.
"""
function parameterindex end

"""
    isindependent_variable(sys, sym)

Check whether the given `sym` is an independent variable in `sys`.
"""
function isindependent_variable end

"""
    isobserved(sys, sym)

Check whether the given `sym` is an observed value in `sys`.
"""
function isobserved end

"""
    observed(sys, sym)

Return the observed function of the given `sym` in `sys`. The returned function should
accept a timeseries if `sys` has an independent variable, and return the observed 
values for the given `sym`.
"""
function observed end

"""
    istimedependent(sys)

Check if `sys` has time as (one of) its independent variables.
"""
function istimedependent end

"""
    constant_structure(sys)

Check if `sys` has a constant structure. Constant structure systems do not change the
number of variables or parameters over time.
"""
function constant_structure end

end
