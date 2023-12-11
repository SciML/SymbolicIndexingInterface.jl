module SymbolicIndexingInterface

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

end
