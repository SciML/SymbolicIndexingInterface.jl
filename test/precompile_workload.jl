using SymbolicIndexingInterface
using Test

indp = SymbolCache([:x, :y], [:a, :b], :t)
valp = ProblemState(; u = [1.0, 2.0], p = [3.0, 4.0], t = 0.5)

@test getsym(indp, :x)(valp) == 1.0
@test getsym(indp, :(x + a + t))(valp) == 4.5
@test getp(indp, [:a, :b])(valp) == [3.0, 4.0]

state_setter = setsym(indp, [:x, :y])
state_setter(valp, [5.0, 6.0])
@test state_values(valp) == [5.0, 6.0]

parameter_setter = setp(indp, [:a, :b])
parameter_setter(valp, [7.0, 8.0])
@test parameter_values(valp) == [7.0, 8.0]

batch = BatchedInterface((indp, [:x, :a]), (indp, [:y, :b]))
@test variable_symbols(batch) == [:x, :a, :y, :b]
@test getsym(batch)(valp, valp) == [5.0, 7.0, 6.0, 8.0]
