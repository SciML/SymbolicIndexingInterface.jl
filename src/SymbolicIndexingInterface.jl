module SymbolicIndexingInterface

export Symbolic, NotSymbolic
include("trait.jl")

export issymbolic, isvariable, variableindex, isparameter, parameterindex,
    isindependent_variable, isobserved, observed, istimedependent, constant_structure
include("interface.jl")


end
