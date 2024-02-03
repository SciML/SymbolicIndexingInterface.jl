using SymbolicIndexingInterface
using Test

struct FakeIntegrator{S, P}
    sys::S
    p::P
end

SymbolicIndexingInterface.symbolic_container(fp::FakeIntegrator) = fp.sys
SymbolicIndexingInterface.parameter_values(fp::FakeIntegrator) = fp.p

sys = SymbolCache([:x, :y, :z], [:a, :b, :c], [:t])
p = [1.0, 2.0, 3.0]
fi = FakeIntegrator(sys, copy(p))
new_p = [4.0, 5.0, 6.0]
for (sym, oldval, newval, check_inference) in [
    (:a, p[1], new_p[1], true),
    (1, p[1], new_p[1], true),
    ([:a, :b], p[1:2], new_p[1:2], true),
    (1:2, p[1:2], new_p[1:2], true),
    ((1, 2), Tuple(p[1:2]), Tuple(new_p[1:2]), true),
    ([:a, [:b, :c]], [p[1], p[2:3]], [new_p[1], new_p[2:3]], false),
    ([:a, (:b, :c)], [p[1], (p[2], p[3])], [new_p[1], (new_p[2], new_p[3])], false),
    ((:a, [:b, :c]), (p[1], p[2:3]), (new_p[1], new_p[2:3]), true),
    ((:a, (:b, :c)), (p[1], (p[2], p[3])), (new_p[1], (new_p[2], new_p[3])), true),
    ([1, [:b, :c]], [p[1], p[2:3]], [new_p[1], new_p[2:3]], false),
    ([1, (:b, :c)], [p[1], (p[2], p[3])], [new_p[1], (new_p[2], new_p[3])], false),
    ((1, [:b, :c]), (p[1], p[2:3]), (new_p[1], new_p[2:3]), true),
    ((1, (:b, :c)), (p[1], (p[2], p[3])), (new_p[1], (new_p[2], new_p[3])), true)
]
    get = getp(sys, sym)
    set! = setp(sys, sym)
    if check_inference
        @inferred get(fi)
    end
    @test get(fi) == oldval
    if check_inference
        @inferred set!(fi, newval)
    else
        set!(fi, newval)
    end
    @test get(fi) == newval
    set!(fi, oldval)
    @test get(fi) == oldval

    if check_inference
        @inferred get(p)
    end
    @test get(p) == oldval
    if check_inference
        @inferred set!(p, newval)
    else
        set!(p, newval)
    end
    @test get(p) == newval
    set!(p, oldval)
    @test get(p) == oldval
end
