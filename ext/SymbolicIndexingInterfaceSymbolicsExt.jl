module SymbolicIndexingInterfaceSymbolicsExt

using SymbolicIndexingInterface

@static if isdefined(Base, :get_extension)
    using Symbolics
else
    using ..Symbolics
end

SymbolicIndexingInterface.issymbolic(::Type{<:Symbolics.Num}) = Symbolic()

end
