module SymbolicIndexingInterface

export ScalarSymbolic, ArraySymbolic, NotSymbolic, symbolic_type, hasname, getname
include("trait.jl")

export is_variable, variable_index, variable_symbols, is_parameter, parameter_index,
       parameter_symbols, is_independent_variable, independent_variable_symbols,
       is_observed,
       observed, is_time_dependent, constant_structure, symbolic_container,
       all_variable_symbols,
       all_symbols, solvedvariables, allvariables
include("interface.jl")

export SymbolCache
include("symbol_cache.jl")

export parameter_values, set_parameter!, getp, setp
include("parameter_indexing.jl")

export Timeseries,
       NotTimeseries, is_timeseries, state_values, set_state!, current_time, getu, setu
include("state_indexing.jl")

export ParameterIndexingProxy
include("parameter_indexing_proxy.jl")
end
