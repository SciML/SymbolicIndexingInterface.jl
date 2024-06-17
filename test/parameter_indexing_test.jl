using SymbolicIndexingInterface
using SymbolicIndexingInterface: IndexerTimeseries, IndexerNotTimeseries, IndexerBoth,
                                 is_indexer_timeseries, indexer_timeseries_index,
                                 ParameterTimeseriesValueIndexMismatchError,
                                 MixedParameterTimeseriesIndexError
using Test

arr = [1.0, 2.0, 3.0]
@test parameter_values(arr) == arr
@test current_time(arr) == arr
tp = (1.0, 2.0, 3.0)
@test parameter_values(tp) == tp

struct FakeIntegrator{S, P}
    sys::S
    p::P
    t::Float64
    counter::Ref{Int}
end

function Base.getproperty(fi::FakeIntegrator, s::Symbol)
    s === :ps ? ParameterIndexingProxy(fi) : getfield(fi, s)
end
SymbolicIndexingInterface.symbolic_container(fp::FakeIntegrator) = fp.sys
SymbolicIndexingInterface.parameter_values(fp::FakeIntegrator) = fp.p
SymbolicIndexingInterface.current_time(fp::FakeIntegrator) = fp.t
function SymbolicIndexingInterface.finalize_parameters_hook!(fi::FakeIntegrator, p)
    fi.counter[] += 1
end

for sys in [
    SymbolCache([:x, :y, :z], [:a, :b, :c, :d], [:t]),
    SymbolCache([:x, :y, :z],
        [:a, :b, :c, :d],
        [:t],
        timeseries_parameters = Dict(
            :b => ParameterTimeseriesIndex(1, 1), :c => ParameterTimeseriesIndex(2, 1)))
]
    has_ts = sys.timeseries_parameters !== nothing
    for pType in [Vector, Tuple]
        p = [1.0, 2.0, 3.0, 4.0]
        fi = FakeIntegrator(sys, pType(copy(p)), 9.0, Ref(0))
        new_p = [4.0, 5.0, 6.0, 7.0]
        for (sym, oldval, newval, check_inference) in [
            (:a, p[1], new_p[1], true),
            (1, p[1], new_p[1], true),
            ([:a, :b], p[1:2], new_p[1:2], !has_ts),
            (1:2, p[1:2], new_p[1:2], true),
            ((1, 2), Tuple(p[1:2]), Tuple(new_p[1:2]), true),
            ([:a, [:b, :c]], [p[1], p[2:3]], [new_p[1], new_p[2:3]], false),
            ([:a, (:b, :c)], [p[1], (p[2], p[3])], [new_p[1], (new_p[2], new_p[3])], false),
            ((:a, [:b, :c]), (p[1], p[2:3]), (new_p[1], new_p[2:3]), true),
            ((:a, (:b, :c)), (p[1], (p[2], p[3])), (new_p[1], (new_p[2], new_p[3])), true),
            ([1, [:b, :c]], [p[1], p[2:3]], [new_p[1], new_p[2:3]], false),
            ([1, (:b, :c)], [p[1], (p[2], p[3])], [new_p[1], (new_p[2], new_p[3])], false),
            ((1, [:b, :c]), (p[1], p[2:3]), (new_p[1], new_p[2:3]), true),
            ((1, (:b, :c)), (p[1], (p[2], p[3])), (new_p[1], (new_p[2], new_p[3])), true),
            ([:a, :b], p[1:2], 42, true)
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

            @test all(get(fi) .== newval)
            set!(fi, oldval)
            @test get(fi) == oldval
            @test fi.counter[] == 2

            fi.ps[sym] = newval
            @test all(get(fi) .== newval)
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
            @test all(get(p) .== newval)
            set!(p, oldval)
            @test get(p) == oldval
            @test fi.counter[] == 4
            fi.counter[] = 0
        end

        for (sym, val) in [
            ([:a, :b, :c, :d], p),
            ([:c, :a], p[[3, 1]]),
            ((:b, :a), Tuple(p[[2, 1]])),
            ((1, :c), Tuple(p[[1, 3]])),
            (:(a + b + t), p[1] + p[2] + fi.t),
            ([:(a + b + t), :c], [p[1] + p[2] + fi.t, p[3]]),
            ((:(a + b + t), :c), (p[1] + p[2] + fi.t, p[3]))
        ]
            get = getp(sys, sym)
            @inferred get(fi)
            @test get(fi) == val
            if sym isa Union{Array, Tuple}
                buffer = zeros(length(sym))
                @inferred get(buffer, fi)
                @test buffer == collect(val)
            end
        end

        getter = getp(sys, [])
        @test getter(fi) == []
        getter = getp(sys, ())
        @test getter(fi) == ()
    end
end

let
    sc = SymbolCache(nothing, nothing, :t)
    fi = FakeIntegrator(sc, nothing, 0.0, Ref(0))
    getter = getp(sc, [])
    @test getter(fi) == []
    getter = getp(sc, ())
    @test getter(fi) == ()
end

struct MyDiffEqArray
    t::Vector{Float64}
    u::Vector{Vector{Float64}}
end
SymbolicIndexingInterface.current_time(mda::MyDiffEqArray) = mda.t
SymbolicIndexingInterface.state_values(mda::MyDiffEqArray) = mda.u
SymbolicIndexingInterface.is_timeseries(::Type{MyDiffEqArray}) = Timeseries()

struct MyParameterObject
    p::Vector{Float64}
    disc_idxs::Vector{Vector{Int}}
end

SymbolicIndexingInterface.parameter_values(mpo::MyParameterObject) = mpo.p
function SymbolicIndexingInterface.with_updated_parameter_timeseries_values(
        mpo::MyParameterObject, args::Pair...)
    for (ts_idx, val) in args
        mpo.p[mpo.disc_idxs[ts_idx]] = val
    end
    return mpo
end

Base.getindex(mpo::MyParameterObject, i) = mpo.p[i]

# check throws if setp dimensions do not match
sys = SymbolCache([:x, :y, :z], [:a, :b, :c, :d], [:t])
fi = FakeIntegrator(sys, [1.0, 2.0, 3.0], 0.0, Ref(0))
@test_throws DimensionMismatch setp(fi, 1:2)(fi, [-1.0, -2.0, -3.0])
@test_throws DimensionMismatch setp(fi, 1:3)(fi, [-1.0, -2.0])

struct FakeSolution
    sys::SymbolCache
    u::Vector{Vector{Float64}}
    t::Vector{Float64}
    p::MyParameterObject
    p_ts::ParameterTimeseriesCollection{Vector{MyDiffEqArray}, MyParameterObject}
end

function Base.getproperty(fs::FakeSolution, s::Symbol)
    s === :ps ? ParameterIndexingProxy(fs) : getfield(fs, s)
end
SymbolicIndexingInterface.state_values(fs::FakeSolution) = fs.u
SymbolicIndexingInterface.current_time(fs::FakeSolution) = fs.t
SymbolicIndexingInterface.symbolic_container(fs::FakeSolution) = fs.sys
SymbolicIndexingInterface.parameter_values(fs::FakeSolution) = fs.p
SymbolicIndexingInterface.parameter_values(fs::FakeSolution, i) = fs.p[i]
SymbolicIndexingInterface.get_parameter_timeseries_collection(fs::FakeSolution) = fs.p_ts
SymbolicIndexingInterface.is_timeseries(::Type{FakeSolution}) = Timeseries()
SymbolicIndexingInterface.is_parameter_timeseries(::Type{FakeSolution}) = Timeseries()
sys = SymbolCache([:x, :y, :z],
    [:a, :b, :c, :d],
    :t;
    timeseries_parameters = Dict(
        :b => ParameterTimeseriesIndex(1, 1), :c => ParameterTimeseriesIndex(2, 1)))
b_timeseries = MyDiffEqArray(collect(0:0.1:0.9), [[2.5i] for i in 1:10])
c_timeseries = MyDiffEqArray(collect(0:0.25:0.9), [[3.5i] for i in 1:4])
p = MyParameterObject(
    [20.0, b_timeseries.u[end][1], c_timeseries.u[end][1], 30.0], [[2], [3]])
fs = FakeSolution(
    sys,
    [i * ones(3) for i in 1:5],
    [0.2i for i in 1:5],
    p,
    ParameterTimeseriesCollection([b_timeseries, c_timeseries], deepcopy(p))
)
aval = fs.p[1]
bval = getindex.(b_timeseries.u)
cval = getindex.(c_timeseries.u)
dval = fs.p[4]
bidx = timeseries_parameter_index(sys, :b)
cidx = timeseries_parameter_index(sys, :c)

for (sym, indexer_trait, timeseries_index, val, buffer, check_inference) in [
    (:a, IndexerNotTimeseries, 0, aval, nothing, true),
    (1, IndexerNotTimeseries, 0, aval, nothing, true),
    ([:a, :d], IndexerNotTimeseries, 0, [aval, dval], zeros(2), true),
    ((:a, :d), IndexerNotTimeseries, 0, (aval, dval), zeros(2), true),
    ([1, 4], IndexerNotTimeseries, 0, [aval, dval], zeros(2), true),
    ((1, 4), IndexerNotTimeseries, 0, (aval, dval), zeros(2), true),
    ([:a, 4], IndexerNotTimeseries, 0, [aval, dval], zeros(2), true),
    ((:a, 4), IndexerNotTimeseries, 0, (aval, dval), zeros(2), true),
    (:b, IndexerBoth, 1, bval, zeros(length(bval)), true),
    (bidx, IndexerTimeseries, 1, bval, zeros(length(bval)), true),
    ([:a, :b], IndexerNotTimeseries, 0, [aval, bval[end]], zeros(2), true),
    ((:a, :b), IndexerNotTimeseries, 0, (aval, bval[end]), zeros(2), true),
    ([1, :b], IndexerNotTimeseries, 0, [aval, bval[end]], zeros(2), true),
    ((1, :b), IndexerNotTimeseries, 0, (aval, bval[end]), zeros(2), true),
    ([:b, :b], IndexerBoth, 1, vcat.(bval, bval), map(_ -> zeros(2), bval), true),
    ((:b, :b), IndexerBoth, 1, tuple.(bval, bval), map(_ -> zeros(2), bval), true),
    ([bidx, :b], IndexerTimeseries, 1, vcat.(bval, bval), map(_ -> zeros(2), bval), true),
    ((bidx, :b), IndexerTimeseries, 1, tuple.(bval, bval), map(_ -> zeros(2), bval), true),
    ([bidx, bidx], IndexerTimeseries, 1, vcat.(bval, bval), map(_ -> zeros(2), bval), true),
    ((bidx, bidx), IndexerTimeseries, 1,
        tuple.(bval, bval), map(_ -> zeros(2), bval), true),
    (:(a + b), IndexerBoth, 1, bval .+ aval, zeros(length(bval)), true),
    ([:(a + b), :a], IndexerBoth, 1, vcat.(bval .+ aval, aval),
        map(_ -> zeros(2), bval), true),
    ((:(a + b), :a), IndexerBoth, 1, tuple.(bval .+ aval, aval),
        map(_ -> zeros(2), bval), true),
    ([:(a + b), :b], IndexerBoth, 1, vcat.(bval .+ aval, bval),
        map(_ -> zeros(2), bval), true),
    ((:(a + b), :b), IndexerBoth, 1, tuple.(bval .+ aval, bval),
        map(_ -> zeros(2), bval), true),
    ([:(a + b), :c], IndexerNotTimeseries, 0,
        [aval + bval[end], cval[end]], zeros(2), true),
    ((:(a + b), :c), IndexerNotTimeseries, 0,
        (aval + bval[end], cval[end]), zeros(2), true)
]
    getter = getp(sys, sym)
    @test is_indexer_timeseries(getter) isa indexer_trait
    if indexer_trait <: Union{IndexerTimeseries, IndexerBoth}
        @test indexer_timeseries_index(getter) == timeseries_index
    end
    test_inplace = buffer !== nothing
    test_non_timeseries = indexer_trait !== IndexerTimeseries
    if test_inplace && test_non_timeseries
        non_timeseries_val = indexer_trait == IndexerNotTimeseries ? val : val[end]
        non_timeseries_buffer = indexer_trait == IndexerNotTimeseries ? deepcopy(buffer) :
                                deepcopy(buffer[end])
        test_non_timeseries_inplace = non_timeseries_buffer isa AbstractArray
    end
    isobs = sym isa Union{AbstractArray, Tuple} ? any(Base.Fix1(is_observed, sys), sym) :
            is_observed(sys, sym)
    if check_inference
        @inferred getter(fs)
        if test_inplace
            @inferred getter(deepcopy(buffer), fs)
        end
        if test_non_timeseries && !isobs
            @inferred getter(parameter_values(fs))
            if test_inplace && test_non_timeseries_inplace && test_non_timeseries_inplace
                @inferred getter(deepcopy(non_timeseries_buffer), parameter_values(fs))
            end
        end
    end
    @test getter(fs) == val
    if test_inplace
        tmp = deepcopy(buffer)
        getter(tmp, fs)
        if val isa Tuple
            target = collect(val)
        elseif eltype(val) <: Tuple
            target = collect.(val)
        else
            target = val
        end
        @test tmp == target
    end
    if test_non_timeseries && !isobs
        non_timeseries_val = indexer_trait == IndexerNotTimeseries ? val : val[end]
        @test getter(parameter_values(fs)) == non_timeseries_val
        if test_inplace && test_non_timeseries && test_non_timeseries_inplace
            getter(non_timeseries_buffer, parameter_values(fs))
            if non_timeseries_val isa Tuple
                target = collect(non_timeseries_val)
            else
                target = non_timeseries_val
            end
            @test non_timeseries_buffer == target
        end
    elseif !isobs
        @test_throws ParameterTimeseriesValueIndexMismatchError{NotTimeseries} getter(parameter_values(fs))
        if test_inplace
            @test_throws ParameterTimeseriesValueIndexMismatchError{NotTimeseries} getter(
                [], parameter_values(fs))
        end
    end
    for subidx in [
        1, CartesianIndex(1), :, rand(Bool, length(val)), rand(eachindex(val), 3), 1:2]
        if indexer_trait <: IndexerNotTimeseries
            @test_throws ParameterTimeseriesValueIndexMismatchError{Timeseries} getter(
                fs, subidx)
            if test_inplace
                @test_throws ParameterTimeseriesValueIndexMismatchError{Timeseries} getter(
                    [], fs, subidx)
            end
        else
            if check_inference
                @inferred getter(fs, subidx)
                if test_inplace && buffer[subidx] isa AbstractArray
                    @inferred getter(deepcopy(buffer[subidx]), fs, subidx)
                end
            end
            @test getter(fs, subidx) == val[subidx]
            if test_inplace && buffer[subidx] isa AbstractArray
                tmp = deepcopy(buffer[subidx])
                getter(tmp, fs, subidx)
                if val[subidx] isa Tuple
                    target = collect(val[subidx])
                elseif eltype(val) <: Tuple
                    target = collect.(val[subidx])
                else
                    target = val[subidx]
                end
                @test tmp == target
            end
        end
    end
end

for sym in [[:a, bidx], (:a, bidx), [1, bidx], (1, bidx),
    [bidx, :c], (bidx, :c), [bidx, cidx], (bidx, cidx)]
    @test_throws ArgumentError getp(sys, sym)
end

for (sym, val) in [
    ([:b, :c], [bval[end], cval[end]]),
    ((:b, :c), (bval[end], cval[end]))
]
    getter = getp(sys, sym)
    @test is_indexer_timeseries(getter) == IndexerNotTimeseries()
    @test_throws MixedParameterTimeseriesIndexError getter(fs)
    @test getter(parameter_values(fs)) == val
end

bval_state = [b_timeseries.u[searchsortedlast(b_timeseries.t, t)][] for t in fs.t]
cval_state = [c_timeseries.u[searchsortedlast(c_timeseries.t, t)][] for t in fs.t]
xval = getindex.(fs.u, 1)

for (sym, val_is_timeseries, val, check_inference) in [
    (:a, false, aval, true),
    ([:a, :d], false, [aval, dval], true),
    ((:a, :d), false, (aval, dval), true),
    (:b, true, bval_state, true),
    ([:a, :b], true, vcat.(aval, bval_state), false),
    ((:a, :b), true, tuple.(aval, bval_state), true),
    ([:b, :c], true, vcat.(bval_state, cval_state), true),
    ((:b, :c), true, tuple.(bval_state, cval_state), true),
    ([:a, :b, :c], true, vcat.(aval, bval_state, cval_state), false),
    ((:a, :b, :c), true, tuple.(aval, bval_state, cval_state), true),
    ([:x, :b], true, vcat.(xval, bval_state), false),
    ((:x, :b), true, tuple.(xval, bval_state), true),
    ([:x, :b, :c], true, vcat.(xval, bval_state, cval_state), false),
    ((:x, :b, :c), true, tuple.(xval, bval_state, cval_state), true),
    ([:a, :b, :x], true, vcat.(aval, bval_state, xval), false),
    ((:a, :b, :x), true, tuple.(aval, bval_state, xval), true),
    (:(2b), true, 2 .* bval_state, true),
    ([:x, :(2b), :(3c)], true, vcat.(xval, 2 .* bval_state, 3 .* cval_state), true),
    ((:x, :(2b), :(3c)), true, tuple.(xval, 2 .* bval_state, 3 .* cval_state), true)
]
    getter = getu(sys, sym)
    if check_inference
        @inferred getter(fs)
    end
    @test getter(fs) == val

    for subidx in [
        1, CartesianIndex(2), :, rand(Bool, length(fs.t)), rand(eachindex(fs.t), 3), 1:2]
        if check_inference
            @inferred getter(fs, subidx)
        end
        target = if val_is_timeseries
            val[subidx]
        else
            if fs.t[subidx] isa AbstractArray
                len = length(fs.t[subidx])
                fill(val, len)
            else
                val
            end
        end
        @test getter(fs, subidx) == target
    end
end

@test_throws ErrorException getp(sys, :not_a_param)

let fs = fs, sys = sys
    getter = getp(sys, [])
    @test getter(fs) == []
    getter = getp(sys, ())
    @test getter(fs) == ()
end

struct FakeNoTimeSolution
    sys::SymbolCache
    u::Vector{Float64}
    p::Vector{Float64}
end

SymbolicIndexingInterface.state_values(fs::FakeNoTimeSolution) = fs.u
SymbolicIndexingInterface.symbolic_container(fs::FakeNoTimeSolution) = fs.sys
SymbolicIndexingInterface.parameter_values(fs::FakeNoTimeSolution) = fs.p
SymbolicIndexingInterface.parameter_values(fs::FakeNoTimeSolution, i) = fs.p[i]

sys = SymbolCache([:x, :y, :z], [:a, :b, :c])
u = [1.0, 2.0, 3.0]
p = [10.0, 20.0, 30.0]
fs = FakeNoTimeSolution(sys, u, p)

for (sym, val, check_inference) in [
    (:a, p[1], true),
    ([:a, :b], p[1:2], true),
    ((:c, :b), (p[3], p[2]), true),
    (:(a + b), p[1] + p[2], true),
    ([:(a + b), :c], [p[1] + p[2], p[3]], true),
    ((:(a + b), :c), (p[1] + p[2], p[3]), true)
]
    getter = getp(sys, sym)
    if check_inference
        @inferred getter(fs)
    end
    @test getter(fs) == val

    if sym isa Union{Array, Tuple}
        buffer = zeros(length(sym))
        @inferred getter(buffer, fs)
        @test buffer == collect(val)
    end
end
