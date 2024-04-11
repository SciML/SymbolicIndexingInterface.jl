using Symbolics
using SymbolicIndexingInterface

@variables x[1:2] y z

syss = [
    SymbolCache([x..., y]),
    SymbolCache([x[1], y, z])
]
syms = [
    [x, y],
    [x[1], y]
]
probs = [
    ProblemState(; u = [1.0, 2.0, 3.0]),
    ProblemState(; u = [4.0, 5.0, 6.0])
]

bi = BatchedInterface(zip(syss, syms)...)

@test all(isequal.(variable_symbols(bi), [x..., y]))
@test variable_index.((bi,), [x..., y, z]) == [1, 2, 3, nothing]
@test is_variable.((bi,), [x..., y, z]) == Bool[1, 1, 1, 0]
@test associated_systems(bi) == [1, 1, 1]

getter = getu(bi)
@test (@inferred getter(probs...)) == [1.0, 2.0, 3.0]
buf = zeros(3)
@inferred getter(buf, probs...)
@test buf == [1.0, 2.0, 3.0]

setter! = setu(bi)
buf .*= 10
setter!(probs..., buf)

@test state_values(probs[1]) == [10.0, 20.0, 30.0]
@test state_values(probs[2]) == [10.0, 30.0, 6.0]

buf ./= 10

setter!(probs[1], 1, buf)
@test state_values(probs[1]) == [1.0, 2.0, 3.0]
