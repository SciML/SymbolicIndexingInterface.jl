using SymbolicIndexingInterface, Test

@test independent_variables(nothing) == []
@test states(nothing) == []
@test parameters(nothing) == []
@test observed(nothing) == []
@test !is_indep_sym(nothing, :a)
@test !is_state_sym(nothing, :a)
@test !is_param_sym(nothing, :a)
@test !is_observed_sym(nothing, :a)
@test isnothing(state_sym_to_index(nothing, :a))
@test isnothing(param_sym_to_index(nothing, :a))
@test get_state_dependencies(nothing) == []
