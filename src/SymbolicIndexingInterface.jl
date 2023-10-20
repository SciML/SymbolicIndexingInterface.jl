module SymbolicIndexingInterface

export isvariable, variableindex, isparameter, parameterindex, isindependent_variable,
    isobserved, observed, istimedependent, constant_structure

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
