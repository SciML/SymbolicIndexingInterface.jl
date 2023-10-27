module SymbolicIndexingInterfaceSymbolicsExt

using SymbolicIndexingInterface

@static if isdefined(Base, :get_extension)
    using Symbolics
else
    using ..Symbolics
end

SymbolicIndexingInterface.symbolic_type(::Type{<:Symbolics.Num}) = ScalarSymbolic()
SymbolicIndexingInterface.symbolic_type(::Type{<:Symbolics.Arr}) = ArraySymbolic()

end
