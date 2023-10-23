struct SymbolCache
    static::Bool
    vars::Vector{Symbol}
    params::Vector{Symbol}
    indepvar::Union{Symbol, Nothing}
end

SymbolicIndexingInterface.is_variable(sys::SymbolCache, sym) = sym in sys.vars
function SymbolicIndexingInterface.variable_index(sys::SymbolCache, sym, t = nothing)
    if !has_static_variable(sys) && t === nothing
        error("timestep must be present")
    end
    findfirst(isequal(sym), sys.vars)
end
SymbolicIndexingInterface.is_parameter(sys::SymbolCache, sym) = sym in sys.params
function SymbolicIndexingInterface.parameter_index(sys::SymbolCache, sym)
    findfirst(isequal(sym), sys.params)
end
function SymbolicIndexingInterface.is_independent_variable(sys::SymbolCache, sym)
    sys.indepvar !== nothing && isequal(sym, sys.indepvar)
end
function SymbolicIndexingInterface.is_observed(sys::SymbolCache, sym)
    is_variable(sys, sym) || is_parameter(sys, sym) || is_independent_variable(sys, sym)
end
function SymbolicIndexingInterface.observed(sys::SymbolCache,
    sym,
    symbolic_states = nothing)
    if !has_static_variable(sys) && symbolic_states === nothing
        error("Symbolic states must be present")
    end
    if has_static_variable(sys)
        symbolic_states = sys.vars
    end
    idx = findfirst(isequal(sym), symbolic_states)
    if idx !== nothing
        return is_time_dependent(sys) ? (u, p, t) -> [u[idx] * i for i in t] :
               (u, p) -> [u[idx] * i for i in 1:5]
    end
    idx = parameter_index(sys, sym)
    if idx !== nothing
        return is_time_dependent(sys) ? (u, p, t) -> p[idx] : (u, p) -> p[idx]
    end
    if is_independent_variable(sys, sym)
        return is_time_dependent(sys) ? (u, p, t) -> t : (u, p) -> 1:5
    end
end
SymbolicIndexingInterface.is_time_dependent(sys::SymbolCache) = isequal(sys.indepvar, :t)
SymbolicIndexingInterface.constant_structure(sys::SymbolCache) = true
SymbolicIndexingInterface.has_static_variable(sys::SymbolCache) = sys.static

sys = SymbolCache(true, [:x, :y, :z], [:a, :b, :c], :t)

@test all(is_variable.((sys,), [:x, :y, :z]))
@test all(.!is_variable.((sys,), [:a, :b, :c, :t, :p, :q, :r]))
@test all(variable_index.((sys,), [:x, :z, :y]) .== [1, 3, 2])
@test all(variable_index.((sys,), [:a, :b, :c, :t, :p, :q, :r]) .=== nothing)
@test all(is_parameter.((sys,), [:a, :b, :c]))
@test all(.!is_parameter.((sys,), [:x, :y, :z, :t, :p, :q, :r]))
@test all(parameter_index.((sys,), [:c, :a, :b]) .== [3, 1, 2])
@test all(parameter_index.((sys,), [:x, :y, :z, :t, :p, :q, :r]) .=== nothing)
@test is_independent_variable(sys, :t)
@test all(.!is_independent_variable.((sys,), [:x, :y, :z, :a, :b, :c, :p, :q, :r]))
@test all(is_observed.((sys,), [:x, :y, :z, :a, :b, :c, :t]))
@test all(observed(sys, :x)(1:3, 4:6, 1:4) .== [1, 2, 3, 4])
@test all(observed(sys, :y)(1:4, 4:6, 1:4) .== [2, 4, 6, 8])
@test all(observed(sys, :z)(1:4, 4:6, 1:4) .== [3, 6, 9, 12])
@test observed(sys, :a)(1:3, 4:6, 1:4) == 4
@test observed(sys, :b)(1:3, 4:6, 1:4) == 5
@test observed(sys, :c)(1:3, 4:6, 1:4) == 6
@test observed(sys, :t)(1:3, 4:6, 1:4) == 1:4
@test is_time_dependent(sys)
@test constant_structure(sys)
@test has_static_variable(sys)

sys = SymbolCache(true, [:x, :y, :z], [:a, :b, :c], nothing)

@test !is_time_dependent(sys)
@test all(observed(sys, :x)(1:3, 4:6) .== [1, 2, 3, 4, 5])
@test all(observed(sys, :y)(1:3, 4:6) .== [2, 4, 6, 8, 10])
@test all(observed(sys, :z)(1:3, 4:6) .== [3, 6, 9, 12, 15])
@test observed(sys, :a)(1:3, 4:6) == 4
@test observed(sys, :b)(1:3, 4:6) == 5
@test observed(sys, :c)(1:3, 4:6) == 6
@test constant_structure(sys)

sys = SymbolCache(false, [:x, :y, :z], [:a, :b, :c], :t)
@test !has_static_variable(sys)
for variable in [:x, :y, :z, :a, :b, :c, :t]
    @test_throws ErrorException variable_index(sys, variable)
    @test_throws ErrorException observed(sys, variable)
end
@test all(variable_index.((sys,), [:z, :y, :x], 1) .== [3, 2, 1])
@test all(variable_index.((sys,), [:a, :b, :c, :t], 1) .== nothing)
variable_order = [:x, :y, :z]
@test all(observed(sys, :x, variable_order)(1:3, 4:6, 1:4) .== [1, 2, 3, 4])
@test all(observed(sys, :y, variable_order)(1:4, 4:6, 1:4) .== [2, 4, 6, 8])
@test all(observed(sys, :z, variable_order)(1:4, 4:6, 1:4) .== [3, 6, 9, 12])
@test observed(sys, :a, variable_order)(1:3, 4:6, 1:4) == 4
@test observed(sys, :b, variable_order)(1:3, 4:6, 1:4) == 5
@test observed(sys, :c, variable_order)(1:3, 4:6, 1:4) == 6
@test observed(sys, :t, variable_order)(1:3, 4:6, 1:4) == 1:4
