module SymbolicIndexingInterface

using Requires

export ScalarSymbolic, ArraySymbolic, NotSymbolic, symbolic_type, hasname, getname
include("trait.jl")

export is_variable, variable_index, variable_symbols, is_parameter, parameter_index,
    parameter_symbols, is_independent_variable, independent_variable_symbols, is_observed,
    observed, is_time_dependent, constant_structure, symbolic_container
include("interface.jl")

export SymbolCache
include("symbol_cache.jl")

export parameter_values, getp, setp
include("parameter_indexing.jl")

@static if !isdefined(Base, :get_extension)
    function __init__()
        @require SymbolicUtils="d1185830-fcd6-423d-90d6-eec64667417b" include("../ext/SymbolicIndexingInterfaceSymbolicUtilsExt.jl")
    end
end

end
