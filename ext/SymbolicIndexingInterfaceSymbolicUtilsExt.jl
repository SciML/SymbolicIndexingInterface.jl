module SymbolicIndexingInterfaceSymbolicUtilsExt

using SymbolicIndexingInterface, SymbolicUtils

SymbolicIndexingInterface.issymbolic(::Type{<:SymbolicUtils.BasicSymbolic}) = Symbolic()

end
