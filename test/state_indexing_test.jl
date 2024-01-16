using SymbolicIndexingInterface

struct FakeIntegrator{S, U, P, T}
    sys::S
    u::U
    p::P
    t::T
end

SymbolicIndexingInterface.symbolic_container(fp::FakeIntegrator) = fp.sys
SymbolicIndexingInterface.state_values(fp::FakeIntegrator) = fp.u
SymbolicIndexingInterface.parameter_values(fp::FakeIntegrator) = fp.p
SymbolicIndexingInterface.current_time(fp::FakeIntegrator) = fp.t

sys = SymbolCache([:x, :y, :z], [:a, :b, :c], [:t])
u = [1.0, 2.0, 3.0]
p = [11.0, 12.0, 13.0]
t = 0.5
fi = FakeIntegrator(sys, copy(u), copy(p), t)
# checking inference for non-concretely typed arrays will always fail
for (sym, val, newval, check_inference) in [
    (:x, u[1], 4.0, true)
    (:y, u[2], 4.0, true)
    (:z, u[3], 4.0, true)
    (1, u[1], 4.0, true)
    ([:x, :y], u[1:2], 4ones(2), true)
    ([1, 2], u[1:2], 4ones(2), true)
    ((:z, :y), (u[3], u[2]), (4.0, 5.0), true)
    ((3, 2), (u[3], u[2]), (4.0, 5.0), true)
    ([:x, [:y, :z]], [u[1], u[2:3]], [4.0, [5.0, 6.0]], false)
    ([:x, 2:3], [u[1], u[2:3]], [4.0, [5.0, 6.0]], false)
    ([:x, (:y, :z)], [u[1], (u[2], u[3])], [4.0, (5.0, 6.0)], false)
    ([:x, Tuple(2:3)], [u[1], (u[2], u[3])], [4.0, (5.0, 6.0)], false)
    ([:x, [:y], (:z,)], [u[1], [u[2]], (u[3],)], [4.0, [5.0], (6.0,)], false)
    ([:x, [:y], (3,)], [u[1], [u[2]], (u[3],)], [4.0, [5.0], (6.0,)], false)
    ((:x, [:y, :z]), (u[1], u[2:3]), (4.0, [5.0, 6.0]), true)
    ((:x, (:y, :z)), (u[1], (u[2], u[3])), (4.0, (5.0, 6.0)), true)
    ((1, (:y, :z)), (u[1], (u[2], u[3])), (4.0, (5.0, 6.0)), true)
    ((:x, [:y], (:z,)), (u[1], [u[2]], (u[3],)), (4.0, [5.0], (6.0,)), true)
]
    get = getu(sys, sym)
    set! = setu(sys, sym)
    if check_inference
        @inferred get(fi)
    end
    @test get(fi) == val
    if check_inference
        @inferred set!(fi, newval)
    else
        set!(fi, newval)
    end
    @test get(fi) == newval
    set!(fi, val)
    @test get(fi) == val

    if check_inference
        @inferred get(u)
    end
    @test get(u) == val
    if check_inference
        @inferred set!(u, newval)
    else
        set!(u, newval)
    end
    @test get(u) == newval
    set!(u, val)
    @test get(u) == val
end

for (sym, oldval, newval, check_inference) in [
    (:a, p[1], 4.0, true)
    (:b, p[2], 5.0, true)
    (:c, p[3], 6.0, true)
    ([:a, :b], p[1:2], [4.0, 5.0], true)
    ((:c, :b), (p[3], p[2]), (6.0, 5.0), true)
    ([:x, :a], [u[1], p[1]], [4.0, 5.0], false)
    ((:y, :b), (u[2], p[2]), (5.0, 6.0), true)
]
    get = getu(fi, sym)
    set! = setu(fi, sym)
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
end

for (sym, val, check_inference) in [
    (:t, t, true),
    ([:x, :a, :t], [u[1], p[1], t], false),
    ((:x, :a, :t), (u[1], p[1], t), true),
]
    get = getu(fi, sym)
    if check_inference
        @inferred get(fi)
    end
    @test get(fi) == val
end

struct FakeSolution{S, U, P, T}
    sys::S
    u::U
    p::P
    t::T
end

SymbolicIndexingInterface.is_timeseries(::Type{<:FakeSolution}) = Timeseries()
SymbolicIndexingInterface.symbolic_container(fp::FakeSolution) = fp.sys
SymbolicIndexingInterface.state_values(fp::FakeSolution) = fp.u
SymbolicIndexingInterface.parameter_values(fp::FakeSolution) = fp.p
SymbolicIndexingInterface.current_time(fp::FakeSolution) = fp.t

sys = SymbolCache([:x, :y, :z], [:a, :b, :c], [:t])
u = [[1.0, 2.0, 3.0], [4.0, 5.0, 6.0]]
t = [1.5, 2.0]
sol = FakeSolution(sys, u, p, t)

xvals = getindex.(sol.u, 1)
yvals = getindex.(sol.u, 2)
zvals = getindex.(sol.u, 3)

for (sym, ans, check_inference) in [
    (:x, xvals, true)
    (:y, yvals, true)
    (:z, zvals, true)
    (1, xvals, true)
    ([:x, :y], vcat.(xvals, yvals), true)
    (1:2, vcat.(xvals, yvals), true)
    ([:x, 2], vcat.(xvals, yvals), false)
    ((:z, :y), tuple.(zvals, yvals), true)
    ((3, 2), tuple.(zvals, yvals), true)
    ([:x, [:y, :z]], vcat.(xvals, [[x] for x in vcat.(yvals, zvals)]), false)
    ([:x, (:y, :z)], vcat.(xvals, tuple.(yvals, zvals)), false)
    ([1, (:y, :z)], vcat.(xvals, tuple.(yvals, zvals)), false)
    ([:x, [:y, :z], (:x, :z)], vcat.(xvals, [[x] for x in vcat.(yvals, zvals)], tuple.(xvals, zvals)), false)
    ([:x, [:y, 3], (1, :z)], vcat.(xvals, [[x] for x in vcat.(yvals, zvals)], tuple.(xvals, zvals)), false)
    ((:x, [:y, :z]), tuple.(xvals, vcat.(yvals, zvals)), true)
    ((:x, (:y, :z)), tuple.(xvals, tuple.(yvals, zvals)), true)
    ((:x, [:y, :z], (:z, :y)), tuple.(xvals, vcat.(yvals, zvals), tuple.(zvals, yvals)), true)
    ([:x, :a], vcat.(xvals, p[1]), false)
    ((:y, :b), tuple.(yvals, p[2]), true)
    (:t, t, true)
    ([:x, :a, :t], vcat.(xvals, p[1], t), false)
    ((:x, :a, :t), tuple.(xvals, p[1], t), true)
]
    get = getu(sys, sym)
    if check_inference
        @inferred get(sol)
    end
    @test get(sol) == ans
    for i in eachindex(u)
        if check_inference
            @inferred get(sol, i)
        end
        @test get(sol, i) == ans[i]
    end
end

for (sym, val) in [
    (:a, p[1])
    (:b, p[2])
    (:c, p[3])
    ([:a, :b], p[1:2])
    ((:c, :b), (p[3], p[2]))
]
    get = getu(fi, sym)
    @inferred get(fi)
    @test get(fi) == val
end
