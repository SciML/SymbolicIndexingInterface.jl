using ModelingToolkit
using ModelingToolkit: t_nounits as t
using SymbolicIndexingInterface

@variables x(t)[1:2] y(t)
@named sys = ODESystem(Equation[], t, [x, y], [])
sys = complete(sys)

@test isequal(name_to_symbolic(sys, :x), x)
@test isequal(name_to_symbolic(sys, :y), y)
