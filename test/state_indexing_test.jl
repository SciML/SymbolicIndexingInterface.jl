using SymbolicIndexingInterface

struct FakeIntegrator{S,U}
    sys::S
    u::U
end

SymbolicIndexingInterface.symbolic_container(fp::FakeIntegrator) = fp.sys
SymbolicIndexingInterface.state_values(fp::FakeIntegrator) = fp.u

sys = SymbolCache([:x, :y, :z], [:a, :b], [:t])
u = [1.0, 2.0, 3.0]
fi = FakeIntegrator(sys, copy(u))
for (i, sym) in [(1, :x), (2, :y), (3, :z), ([1, 2], [:x, :y]), ((3, 2), (:z, :y))]
    get = getu(sys, sym)
    set! = setu(sys, sym)
    true_value = i isa Tuple ? getindex.((u,), i) : u[i]
    @test get(fi) == true_value
    set!(fi, 0.5 .* i)
    @test get(fi) == 0.5 .* i
    set!(fi, true_value)
end
