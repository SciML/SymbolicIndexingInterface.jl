sc = SymbolCache([:x, :y, :z], [:a, :b], [:t])

@test all(is_variable.((sc,), [:x, :y, :z]))
@test all(.!is_variable.((sc,), [:a, :b, :t, :q]))
@test variable_index.((sc,), [:x, :y, :z, :a]) == [1, 2, 3, nothing]
@test all(is_parameter.((sc,), [:a, :b]))
@test all(.!is_parameter.((sc,), [:x, :y, :z, :t, :q]))
@test parameter_index.((sc,), [:a, :b, :x]) == [1, 2, nothing]
@test is_independent_variable(sc, :t)
@test all(.!is_independent_variable.((sc,), [:x, :y, :z, :a, :b, :q]))
@test all(.!is_observed.((sc,), [:x, :y, :z, :a, :b, :t, :q]))
@test is_time_dependent(sc)
@test constant_structure(sc)
@test variable_symbols(sc) == [:x, :y, :z]
@test parameter_symbols(sc) == [:a, :b]
@test independent_variable_symbols(sc) == [:t]

sc = SymbolCache([:x, :y], [:a, :b])
@test !is_time_dependent(sc)
# make sure the constructor works
@test_nowarn SymbolCache([:x, :y])

sc = SymbolCache()
@test all(.!is_variable.((sc,), [:x, :y, :a, :b, :t]))
@test all(variable_index.((sc,), [:x, :y, :a, :b, :t]) .== nothing)
@test variable_symbols(sc) == []
@test all(.!is_parameter.((sc,), [:x, :y, :a, :b, :t]))
@test all(parameter_index.((sc,), [:x, :y, :a, :b, :t]) .== nothing)
@test parameter_symbols(sc) == []
@test all(.!is_independent_variable.((sc,), [:x, :y, :a, :b, :t]))
@test independent_variable_symbols(sc) == []
@test !is_time_dependent(sc)

sc = SymbolCache(nothing, nothing, :t)
@test all(.!is_independent_variable.((sc,), [:x, :y, :a, :b]))
@test is_independent_variable(sc, :t)
@test independent_variable_symbols(sc) == [:t]
@test is_time_dependent(sc)

sc2 = copy(sc)
@test sc.variables == sc2.variables
@test sc.parameters == sc2.parameters
@test sc.independent_variables == sc2.independent_variables
