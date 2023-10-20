module SymbolicIndexingInterfaceSymbolicsExt

using SymbolicIndexingInterface, Symbolics

SymbolicIndexingInterface.issymbolic(::Type{<:Symbolics.Num}) = Symbolic()

end
