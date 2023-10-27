module SymbolicIndexingInterfaceSymbolicUtilsExt

using SymbolicIndexingInterface
@static if isdefined(Base, :get_extension)
    using SymbolicUtils
else
    using ..SymbolicUtils
end

function SymbolicIndexingInterface.symbolic_type(::Type{<:SymbolicUtils.BasicSymbolic})
    ScalarSymbolic()
end

end
