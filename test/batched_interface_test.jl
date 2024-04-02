using SymbolicIndexingInterface

syss = [
    SymbolCache([:x, :y, :z], [:a, :b, :c], :t),
    SymbolCache([:z, :w, :v], [:c, :e, :f]),
    SymbolCache([:w, :x, :u], [:e, :a, :f])
]
syms = [
    [:x, :z, :b, :c],
    [:z, :w, :c, :f],
    [:w, :x, :e, :a]
]
probs = [
    ProblemState(; u = [1.0, 2.0, 3.0], p = [0.1, 0.2, 0.3]),
    ProblemState(; u = [4.0, 5.0, 6.0], p = [0.4, 0.5, 0.6]),
    ProblemState(; u = [7.0, 8.0, 9.0], p = [0.7, 0.8, 0.9])
]

@test_throws ErrorException BatchedInterface((syss[1], [:x, 3]))
@test_throws ErrorException BatchedInterface((syss[1], [:(x + y)]))
@test_throws ErrorException BatchedInterface((syss[1], [:t]))

bi = BatchedInterface(zip(syss, syms)...)
@test variable_symbols(bi) == [:x, :z, :b, :c, :w, :f, :e, :a]
@test variable_index.((bi,), [:a, :b, :c, :e, :f, :x, :y, :z, :w, :v, :u]) ==
      [8, 3, 4, 7, 6, 1, nothing, 2, 5, nothing, nothing]
@test is_variable.((bi,), [:a, :b, :c, :e, :f, :x, :y, :z, :w, :v, :u]) ==
      Bool[1, 1, 1, 1, 1, 1, 0, 1, 1, 0, 0]
@test associated_systems(bi) == [1, 1, 1, 1, 2, 2, 3, 3]

getter = getu(bi)
@test (@inferred getter(probs...)) == [1.0, 3.0, 0.2, 0.3, 5.0, 0.6, 0.7, 0.8]
buf = zeros(8)
@inferred getter(buf, probs...)
@test buf == [1.0, 3.0, 0.2, 0.3, 5.0, 0.6, 0.7, 0.8]

setter! = setu(bi)
buf .*= 100
setter!(probs..., buf)

@test state_values(probs[1]) == [100.0, 2.0, 300.0]
# :a isn't updated here because it wasn't part of the symbols associated with syss[1] (syms[1])
@test parameter_values(probs[1]) == [0.1, 20.0, 30.0]
@test state_values(probs[2]) == [300.0, 500.0, 6.0]
# Similarly for :e
@test parameter_values(probs[2]) == [30.0, 0.5, 60.0]
@test state_values(probs[3]) == [500.0, 100.0, 9.0]
# Similarly for :f
@test parameter_values(probs[3]) == [70.0, 80.0, 0.9]
