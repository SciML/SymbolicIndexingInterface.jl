using SymbolicIndexingInterface
using Test

struct FakeIntegrator{S, P}
    sys::S
    p::P
    counter::Ref{Int}
end

function Base.getproperty(fi::FakeIntegrator, s::Symbol)
    s === :ps ? ParameterIndexingProxy(fi) : getfield(fi, s)
end
SymbolicIndexingInterface.symbolic_container(fp::FakeIntegrator) = fp.sys
SymbolicIndexingInterface.parameter_values(fp::FakeIntegrator) = fp.p
function SymbolicIndexingInterface.finalize_parameters_hook!(fi::FakeIntegrator, p)
    fi.counter[] += 1
end

sys = SymbolCache([:x, :y, :z], [:a, :b, :c], [:t])
for pType in [Vector, Tuple]
    p = [1.0, 2.0, 3.0]
    fi = FakeIntegrator(sys, pType(copy(p)), Ref(0))
    new_p = [4.0, 5.0, 6.0]
    @test parameter_timeseries(fi) == [0]
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
        @test get(fi) == fi.ps[sym]
        @test get(fi) == oldval

        if pType === Tuple
            @test_throws MethodError set!(fi, newval)
            continue
        end

        @test fi.counter[] == 0
        if check_inference
            @inferred set!(fi, newval)
        else
            set!(fi, newval)
        end
        @test fi.counter[] == 1

        @test get(fi) == newval
        set!(fi, oldval)
        @test get(fi) == oldval
        @test fi.counter[] == 2

        fi.ps[sym] = newval
        @test get(fi) == newval
        @test fi.counter[] == 3
        fi.ps[sym] = oldval
        @test get(fi) == oldval
        @test fi.counter[] == 4

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
        @test fi.counter[] == 4
        fi.counter[] = 0
    end

    for (sym, val) in [
        ([:a, :b, :c], p),
        ([:c, :a], p[[3, 1]]),
        ((:b, :a), p[[2, 1]]),
        ((1, :c), p[[1, 3]])
    ]
        buffer = zeros(length(sym))
        get = getp(sys, sym)
        @inferred get(buffer, fi)
        @test buffer == val
    end
end

struct FakeSolution
    sys::SymbolCache
    u::Vector{Vector{Float64}}
    t::Vector{Float64}
    p::Vector{Vector{Float64}}
    pt::Vector{Float64}
end

function Base.getproperty(fs::FakeSolution, s::Symbol)
    s === :ps ? ParameterIndexingProxy(fs) : getfield(fs, s)
end
SymbolicIndexingInterface.state_values(fs::FakeSolution) = fs.u
SymbolicIndexingInterface.current_time(fs::FakeSolution) = fs.t
SymbolicIndexingInterface.symbolic_container(fs::FakeSolution) = fs.sys
SymbolicIndexingInterface.parameter_values(fs::FakeSolution) = fs.p[end]
SymbolicIndexingInterface.parameter_values(fs::FakeSolution, i) = fs.p[end][i]
function SymbolicIndexingInterface.parameter_values_at_time(fs::FakeSolution, t)
    fs.p[t]
end
function SymbolicIndexingInterface.parameter_values_at_state_time(fs::FakeSolution, t)
    ptind = searchsortedfirst(fs.pt, fs.t[t]; lt = <=)
    fs.p[ptind - 1]
end
SymbolicIndexingInterface.parameter_timeseries(fs::FakeSolution) = fs.pt
SymbolicIndexingInterface.is_timeseries(::Type{FakeSolution}) = Timeseries()
SymbolicIndexingInterface.is_parameter_timeseries(::Type{FakeSolution}) = Timeseries()
sys = SymbolCache([:x, :y, :z], [:a, :b, :c], :t)
fs = FakeSolution(
    sys,
    [i * ones(3) for i in 1:5],
    [0.2i for i in 1:5],
    [2i * ones(3) for i in 1:10],
    [0.1i for i in 1:10]
)
ps = fs.p
p = fs.p[end]
avals = getindex.(ps, 1)
bvals = getindex.(ps, 2)
cvals = getindex.(ps, 3)
@test parameter_timeseries(fs) == fs.pt
for (sym, val, arrval, check_inference) in [
    (:a, p[1], avals, true),
    (1, p[1], avals, true),
    ([:a, :b], p[1:2], vcat.(avals, bvals), true),
    (1:2, p[1:2], vcat.(avals, bvals), true),
    ((1, 2), Tuple(p[1:2]), tuple.(avals, bvals), true),
    ([:a, [:b, :c]], [p[1], p[2:3]],
        [[i, [j, k]] for (i, j, k) in zip(avals, bvals, cvals)], false),
    ([:a, (:b, :c)], [p[1], (p[2], p[3])], vcat.(avals, tuple.(bvals, cvals)), false),
    ((:a, [:b, :c]), (p[1], p[2:3]), tuple.(avals, vcat.(bvals, cvals)), true),
    ((:a, (:b, :c)), (p[1], (p[2], p[3])), tuple.(avals, tuple.(bvals, cvals)), true),
    ([1, [:b, :c]], [p[1], p[2:3]],
        [[i, [j, k]] for (i, j, k) in zip(avals, bvals, cvals)], false),
    ([1, (:b, :c)], [p[1], (p[2], p[3])], vcat.(avals, tuple.(bvals, cvals)), false),
    ((1, [:b, :c]), (p[1], p[2:3]), tuple.(avals, vcat.(bvals, cvals)), true),
    ((1, (:b, :c)), (p[1], (p[2], p[3])), tuple.(avals, tuple.(bvals, cvals)), true)
]
    get = getp(sys, sym)
    if check_inference
        @inferred get(fs)
    end
    @test get(fs) == fs.ps[sym]
    @test get(fs) == val

    for sub_inds in [
        :, 3:5, rand(Bool, length(ps)), rand(eachindex(ps)), rand(CartesianIndices(ps))]
        if check_inference
            @inferred get(fs, sub_inds)
        end
        @test get(fs, sub_inds) == fs.ps[sym, sub_inds]
        @test get(fs, sub_inds) == arrval[sub_inds]
    end
end

ps = fs.p[2:2:end]
avals = getindex.(ps, 1)
bvals = getindex.(ps, 2)
cvals = getindex.(ps, 3)
for (sym, val, arrval) in [
    (:a, p[1], avals),
    ((:b, :c), p[2:3], tuple.(bvals, cvals)),
    ([:c, :a], p[[3, 1]], vcat.(cvals, avals))
]
    get = getu(sys, sym)
    @inferred get(fs)
    @test get(fs) == arrval
    for i in eachindex(ps)
        @test get(fs, i) == arrval[i]
    end
end
