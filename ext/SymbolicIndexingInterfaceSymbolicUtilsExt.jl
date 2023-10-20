module SymbolicIndexingInterfaceSymbolicUtilsExt

using SymbolicIndexingInterface
@static if isdefined(Base, :get_extension)
    using SymbolicUtils
else
    using ..SymbolicUtils
end

SymbolicIndexingInterface.issymbolic(::Type{<:SymbolicUtils.BasicSymbolic}) = Symbolic()

end
