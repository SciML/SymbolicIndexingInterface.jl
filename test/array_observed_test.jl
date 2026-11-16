using SymbolicIndexingInterface, Test

struct ArrayObservedSymbol end
struct ArrayObservedProvider
    generated::Base.RefValue{Int}
end

SymbolicIndexingInterface.symbolic_type(::Type{ArrayObservedSymbol}) = ArraySymbolic()
SymbolicIndexingInterface.is_variable(::ArrayObservedProvider, ::ArrayObservedSymbol) = false
SymbolicIndexingInterface.is_parameter(::ArrayObservedProvider, ::ArrayObservedSymbol) = false
SymbolicIndexingInterface.is_independent_variable(::ArrayObservedProvider, ::ArrayObservedSymbol) = false
SymbolicIndexingInterface.is_observed(::ArrayObservedProvider, ::ArrayObservedSymbol) = true
SymbolicIndexingInterface.is_time_dependent(::ArrayObservedProvider) = false
function SymbolicIndexingInterface.parameter_observed(sys::ArrayObservedProvider, ::ArrayObservedSymbol)
    sys.generated[] += 1
    return p -> reshape(p, 2, 2)
end
function SymbolicIndexingInterface.observed(sys::ArrayObservedProvider, ::ArrayObservedSymbol)
    sys.generated[] += 1
    return (u, p) -> reshape(u + p, 2, 2)
end

@testset "Array-valued observed getters" begin
    sys = ArrayObservedProvider(Ref(0))
    sym = ArrayObservedSymbol()
    values = [1.0, 2.0, 3.0, 4.0]
    getter = getp(sys, sym)
    @test sys.generated[] == 1
    @test getter(values) == reshape(values, 2, 2)
    stategetter = getsym(sys, sym)
    @test sys.generated[] == 2
    point = ProblemState(; u = values, p = values)
    @test stategetter(point) == reshape(2values, 2, 2)
end

struct TimedArrayObservedProvider end
SymbolicIndexingInterface.is_variable(::TimedArrayObservedProvider, ::ArrayObservedSymbol) = false
SymbolicIndexingInterface.is_parameter(::TimedArrayObservedProvider, ::ArrayObservedSymbol) = false
SymbolicIndexingInterface.is_independent_variable(::TimedArrayObservedProvider, ::ArrayObservedSymbol) = false
SymbolicIndexingInterface.is_observed(::TimedArrayObservedProvider, ::ArrayObservedSymbol) = true
SymbolicIndexingInterface.is_time_dependent(::TimedArrayObservedProvider) = true
SymbolicIndexingInterface.get_all_timeseries_indexes(::TimedArrayObservedProvider, ::ArrayObservedSymbol) = Set{Any}()
SymbolicIndexingInterface.parameter_observed(::TimedArrayObservedProvider, ::ArrayObservedSymbol) =
    (p, t) -> reshape(t .* p, 2, 2)

@testset "Time-dependent array-valued parameter observations" begin
    sys = TimedArrayObservedProvider()
    sym = ArrayObservedSymbol()
    values = [1.0, 2.0, 3.0, 4.0]
    point = ProblemState(; p = values, t = 2.0)
    @test getp(sys, sym)(point) == reshape(2values, 2, 2)
    @test getsym(sys, sym)(point) == reshape(2values, 2, 2)
end
