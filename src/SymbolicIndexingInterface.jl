module SymbolicIndexingInterface

using RuntimeGeneratedFunctions
import StaticArraysCore: MArray, similar_type
import ArrayInterface
using Accessors: @reset

RuntimeGeneratedFunctions.init(@__MODULE__)

export ScalarSymbolic, ArraySymbolic, NotSymbolic, symbolic_type, hasname, getname,
       Timeseries, NotTimeseries, is_timeseries
include("trait.jl")

export is_variable, variable_index, variable_symbols, is_parameter, parameter_index,
       parameter_symbols, is_independent_variable, independent_variable_symbols,
       is_observed,
       observed, is_time_dependent, constant_structure, symbolic_container,
       all_variable_symbols,
       all_symbols, solvedvariables, allvariables, default_values, symbolic_evaluate
include("interface.jl")

export SymbolCache
include("symbol_cache.jl")

export parameter_values, set_parameter!, finalize_parameters_hook!,
       parameter_values_at_time, parameter_values_at_state_time, parameter_timeseries,
       state_values, set_state!, current_time
include("value_provider_interface.jl")

export getp, setp
include("parameter_indexing.jl")

export getu, setu
include("state_indexing.jl")

export BatchedInterface, associated_systems
include("batched_interface.jl")

export ProblemState
include("problem_state.jl")

export ParameterIndexingProxy
include("parameter_indexing_proxy.jl")

export remake_buffer
include("remake.jl")
end
