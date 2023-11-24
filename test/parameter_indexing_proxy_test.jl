using SymbolicIndexingInterface
using Symbolics

struct FakeProblem{S,P}
    sys::S
    p::P
end

SymbolicIndexingInterface.symbolic_container(fp::FakeProblem) = fp.sys
SymbolicIndexingInterface.parameter_values(fp::FakeProblem) = fp.p

@variables a[1:2] b
sys = SymbolCache([:x, :y, :z], [a[1], a[2], b], [:t])

for p in ([1.0, 2.0, 3.0], (1.0, 2.0, 3.0), [1.0 2.0 3.0])
    fp = FakeProblem(sys, p)
    pip = ParameterIndexingProxy(fp)
    # numeric indexing still works
    for i in eachindex(p)
        @test pip[i] == p[i]
    end
    # index with individual symbols
    for (i, sym) in enumerate(parameter_symbols(fp))
        @test pip[sym] == p[i]
    end
    # index with array of symbols
    @test pip[parameter_symbols(fp)] == vec(collect(p))
    # index with tuple of symbols
    @test pip[Tuple(parameter_symbols(fp))] == Tuple(p)
    # index with symbolic array
    @test pip[a] == collect(p)[1:2]
end