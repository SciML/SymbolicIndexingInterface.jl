using SymbolicIndexingInterface
using SymbolicIndexingInterface: IndexerOnlyTimeseries, IndexerNotTimeseries, IndexerBoth,
                                 IndexerMixedTimeseries,
                                 is_indexer_timeseries, indexer_timeseries_index,
                                 ParameterTimeseriesValueIndexMismatchError,
                                 MixedParameterTimeseriesIndexError
using Test
import ..CheckboundsCountedArray
import ..maybe_CheckboundsCountedArray as maybe_CCA
import ..test_no_boundschecks

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
function test_no_boundschecks(fi::FakeIntegrator)
    test_no_boundschecks(fi.p)
end

@testset "FakeIntegrator: inbounds = $inbounds" for inbounds in [false, true]
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
            _p = pType(copy(p))
            if pType == Vector
                _p = maybe_CCA(_p, inbounds)
            end
            fi = FakeIntegrator(sys, _p, 9.0, Ref(0))
            new_p = [4.0, 5.0, 6.0, 7.0]
            for (sym, oldval, newval, check_inference) in [
                (:a, p[1], new_p[1], true),
                (1, p[1], new_p[1], true),
                ([:a, :b], p[1:2], new_p[1:2], !has_ts),
                (1:2, p[1:2], new_p[1:2], true),
                ((1, 2), Tuple(p[1:2]), Tuple(new_p[1:2]), true),
                ([:a, [:b, :c]], [p[1], p[2:3]], [new_p[1], new_p[2:3]], false),
                ([:a, (:b, :c)], [p[1], (p[2], p[3])],
                    [new_p[1], (new_p[2], new_p[3])], false),
                ((:a, [:b, :c]), (p[1], p[2:3]), (new_p[1], new_p[2:3]), true),
                ((:a, (:b, :c)), (p[1], (p[2], p[3])),
                    (new_p[1], (new_p[2], new_p[3])), true),
                ([1, [:b, :c]], [p[1], p[2:3]], [new_p[1], new_p[2:3]], false),
                ([1, (:b, :c)], [p[1], (p[2], p[3])],
                    [new_p[1], (new_p[2], new_p[3])], false),
                ((1, [:b, :c]), (p[1], p[2:3]), (new_p[1], new_p[2:3]), true),
                ((1, (:b, :c)), (p[1], (p[2], p[3])),
                    (new_p[1], (new_p[2], new_p[3])), true)]
                get = getp(sys, sym; inbounds)
                set! = setp(sys, sym; inbounds)
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

                if inbounds
                    test_no_boundschecks(fi)
                end
            end

            for (sym, val, check_inference) in [
                ([:a, :b, :c, :d], p, true),
                ([:c, :a], p[[3, 1]], !has_ts),
                ((:b, :a), Tuple(p[[2, 1]]), true),
                ((1, :c), Tuple(p[[1, 3]]), true),
                (:(a + b + t), p[1] + p[2] + fi.t, true),
                ([:(a + b + t), :c], [p[1] + p[2] + fi.t, p[3]], true),
                ((:(a + b + t), :c), (p[1] + p[2] + fi.t, p[3]), true)
            ]
                get = getp(sys, sym; inbounds)
                if check_inference
                    @inferred get(fi)
                end
                @test get(fi) == val
                if sym isa Union{Array, Tuple}
                    buffer = zeros(length(sym))
                    if check_inference
                        @inferred get(buffer, fi)
                    else
                        get(buffer, fi)
                    end
                    @test buffer == collect(val)
                end

                if inbounds
                    test_no_boundschecks(fi)
                end
            end

            for (sym, val, check_inference) in [
                (:(a + b), p[1] + p[2], true),
                ([:(a + b), :(a * b)], [p[1] + p[2], p[1] * p[2]], true),
                ((:(a + b), :(a * b)), (p[1] + p[2], p[1] * p[2]), true),
                ([:(a + c), :(a + b)], [p[1] + p[3], p[1] + p[2]], true)
            ]
                get = getp(sys, sym; inbounds)
                if check_inference
                    @inferred get(parameter_values(fi))
                end
                @test get(parameter_values(fi)) == val
                if sym isa Union{Array, Tuple}
                    buffer = zeros(length(sym))
                    if check_inference
                        @inferred get(buffer, parameter_values(fi))
                    else
                        get(buffer, parameter_values(fi))
                    end
                    @test buffer == collect(val)
                end

                if inbounds
                    test_no_boundschecks(fi)
                end
            end

            for sym in [
                :(a + t),
                [:(a + t), :(a * b)],
                (:(a + t), :(a * b))
            ]
                get = getp(sys, sym; inbounds)
                @test_throws MethodError get(parameter_values(fi))
                if sym isa Union{Array, Tuple}
                    @test_throws MethodError get(zeros(length(sym)), parameter_values(fi))
                end
                if inbounds
                    test_no_boundschecks(fi)
                end
            end

            getter = getp(sys, []; inbounds)
            @test getter(fi) == []
            getter = getp(sys, (); inbounds)
            @test getter(fi) == ()

            if inbounds
                test_no_boundschecks(fi)
            end

            for (sym, val) in [
                (:a, 1.0f1),
                (1, 1.0f1),
                ([:a, :b], [1.0f1, 2.0f1]),
                ((:b, :c), (2.0f1, 3.0f1))
            ]
                setter = setp_oop(fi, sym; inbounds)
                newp = setter(fi, val)
                getter = getp(sys, sym; inbounds)
                @test getter(newp) == val

                if inbounds
                    test_no_boundschecks(fi)
                end
            end
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
end

struct MyDiffEqArray{
    T <: AbstractVector{Float64}, U <: AbstractVector{<:AbstractVector{Float64}}}
    t::T
    u::U
end

SymbolicIndexingInterface.current_time(mda::MyDiffEqArray) = mda.t
SymbolicIndexingInterface.state_values(mda::MyDiffEqArray) = mda.u
SymbolicIndexingInterface.is_timeseries(::Type{<:MyDiffEqArray}) = Timeseries()

function test_no_boundschecks(mda::MyDiffEqArray)
    test_no_boundschecks(mda.t)
    test_no_boundschecks(mda.u)
    if mda.u isa CheckboundsCountedArray
        for buf in mda.u.array
            test_no_boundschecks(buf)
        end
    end
end

struct MyParameterObject{P, D}
    p::P
    disc_idxs::D
end

SymbolicIndexingInterface.parameter_values(mpo::MyParameterObject) = mpo.p
function SymbolicIndexingInterface.with_updated_parameter_timeseries_values(
        ::SymbolCache, mpo::MyParameterObject, args::Pair...)
    for (ts_idx, val) in args
        mpo.p[mpo.disc_idxs[ts_idx]] = val
    end
    return mpo
end

function test_no_boundschecks(mpo::MyParameterObject)
    test_no_boundschecks(mpo.p)
    test_no_boundschecks(mpo.disc_idxs)
    if mpo.disc_idxs isa CheckboundsCountedArray
        for buf in mpo.disc_idxs.array
            test_no_boundschecks(buf)
        end
    end
end

Base.getindex(mpo::MyParameterObject, i) = mpo.p[i]

struct FakeSolution{U, T, P <: MyParameterObject, PT <: ParameterTimeseriesCollection}
    sys::SymbolCache
    u::U
    t::T
    p::P
    p_ts::PT
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
SymbolicIndexingInterface.is_timeseries(::Type{<:FakeSolution}) = Timeseries()
SymbolicIndexingInterface.is_parameter_timeseries(::Type{<:FakeSolution}) = Timeseries()

function test_no_boundschecks(fs::FakeSolution)
    test_no_boundschecks(fs.u)
    if fs.u isa CheckboundsCountedArray
        for buf in fs.u.array
            test_no_boundschecks(buf)
        end
    end
    test_no_boundschecks(fs.t)
    test_no_boundschecks(fs.p)
    test_no_boundschecks(fs.p_ts)
end

sys = SymbolCache([:x, :y, :z],
    [:a, :b, :c, :d],
    :t;
    timeseries_parameters = Dict(
        :b => ParameterTimeseriesIndex(1, 1), :c => ParameterTimeseriesIndex(2, 1)))

@testset "FakeSolution: inbounds = $inbounds" for inbounds in [false, true]
    b_timeseries = MyDiffEqArray(maybe_CCA(collect(0:0.1:0.9), inbounds),
        maybe_CCA([maybe_CCA([2.5i], inbounds) for i in 1:10], inbounds))
    c_timeseries = MyDiffEqArray(maybe_CCA(collect(0:0.25:0.9), inbounds),
        maybe_CCA([maybe_CCA([3.5i], inbounds) for i in 1:4], inbounds))
    p = MyParameterObject(
        maybe_CCA([20.0, b_timeseries.u[end][1], c_timeseries.u[end][1], 30.0], inbounds), maybe_CCA(
            [maybe_CCA([2], inbounds), maybe_CCA([3], inbounds)], inbounds))
    fs = FakeSolution(
        sys,
        maybe_CCA([maybe_CCA(i * ones(3), inbounds) for i in 1:5], inbounds),
        maybe_CCA([0.2i for i in 1:5], inbounds),
        p,
        ParameterTimeseriesCollection(
            maybe_CCA([b_timeseries, c_timeseries], inbounds), deepcopy(p))
    )
    aval = @inbounds fs.p[1]
    bval = @inbounds getindex.(b_timeseries.u)
    cval = @inbounds getindex.(c_timeseries.u)
    dval = @inbounds fs.p[4]
    bidx = timeseries_parameter_index(sys, :b)
    cidx = timeseries_parameter_index(sys, :c)
    # IndexerNotTimeseries
    for (sym, val, buffer, check_inference) in [
        (:a, aval, nothing, true),
        (1, aval, nothing, true),
        ([:a, :d], [aval, dval], zeros(2), true),
        ((:a, :d), (aval, dval), zeros(2), true),
        ([1, 4], [aval, dval], zeros(2), true),
        ((1, 4), (aval, dval), zeros(2), true),
        ([:a, 4], [aval, dval], zeros(2), true),
        ((:a, 4), (aval, dval), zeros(2), true),
        (:(a + d), aval + dval, nothing, true),
        ([:(a + d), :(a * d)], [aval + dval, aval * dval], zeros(2), true),
        ((:(a + d), :(a * d)), (aval + dval, aval * dval), zeros(2), true)
    ]
        getter = getp(fs, sym; inbounds)
        @test is_indexer_timeseries(getter) isa IndexerNotTimeseries
        test_inplace = buffer !== nothing
        is_observed = sym isa Expr ||
                      sym isa Union{AbstractArray, Tuple} && any(x -> x isa Expr, sym)
        if check_inference
            @inferred getter(fs)
            if !is_observed
                @inferred getter(parameter_values(fs))
            end
            if test_inplace
                @inferred getter(deepcopy(buffer), fs)
                if !is_observed
                    @inferred getter(deepcopy(buffer), parameter_values(fs))
                end
            end
        end
        @test getter(fs) == val
        if !is_observed
            @test getter(parameter_values(fs)) == val
        end
        if test_inplace
            target = collect(val)
            valps = is_observed ? (fs,) : (fs, parameter_values(fs))
            for valp in valps
                tmp = deepcopy(buffer)
                getter(tmp, valp)
                @test tmp == target
            end
        end
        for subidx in [1, CartesianIndex(1), :, rand(Bool, 4), rand(1:4, 3), 1:2]
            @test getter(fs, subidx) == val
            if test_inplace
                tmp = deepcopy(buffer)
                getter(tmp, fs, subidx)
                @test tmp == collect(val)
            end
        end
        if inbounds
            test_no_boundschecks(fs)
        end
    end

    # IndexerBoth
    for (sym, timeseries_index, val, buffer, check_inference) in [
        (:b, 1, bval, zeros(length(bval)), true),
        ([:a, :b], 1, vcat.(aval, bval), map(_ -> zeros(2), bval), false),
        ((:a, :b), 1, tuple.(aval, bval), map(_ -> zeros(2), bval), true),
        ([1, :b], 1, vcat.(aval, bval), map(_ -> zeros(2), bval), false),
        ((1, :b), 1, tuple.(aval, bval), map(_ -> zeros(2), bval), true),
        ([:b, :b], 1, vcat.(bval, bval), map(_ -> zeros(2), bval), true),
        ((:b, :b), 1, tuple.(bval, bval), map(_ -> zeros(2), bval), true),
        (:(a + b), 1, bval .+ aval, zeros(length(bval)), true),
        ([:(a + b), :a], 1, vcat.(bval .+ aval, aval), map(_ -> zeros(2), bval), true),
        ((:(a + b), :a), 1, tuple.(bval .+ aval, aval), map(_ -> zeros(2), bval), true),
        ([:(a + b), :b], 1, vcat.(bval .+ aval, bval), map(_ -> zeros(2), bval), true),
        ((:(a + b), :b), 1, tuple.(bval .+ aval, bval), map(_ -> zeros(2), bval), true)
    ]
        getter = getp(sys, sym; inbounds)
        @test is_indexer_timeseries(getter) isa IndexerBoth
        @test indexer_timeseries_index(getter) == timeseries_index
        isobs = sym isa Union{AbstractArray, Tuple} ?
                any(Base.Fix1(is_observed, sys), sym) :
                is_observed(sys, sym)

        if check_inference
            @inferred getter(fs)
            @inferred getter(deepcopy(buffer), fs)
            if !isobs
                @inferred getter(parameter_values(fs))
                if !(eltype(val) <: Number)
                    @inferred getter(deepcopy(buffer[1]), parameter_values(fs))
                end
            end
        end

        @test getter(fs) == val
        if eltype(val) <: Number
            target = val
        else
            target = collect.(val)
        end
        tmp = deepcopy(buffer)
        getter(tmp, fs)
        @test tmp == target

        if !isobs
            @test getter(parameter_values(fs)) == val[end]
            if !(eltype(val) <: Number)
                target = collect(val[end])
                tmp = deepcopy(buffer)[end]
                getter(tmp, parameter_values(fs))
                @test tmp == target
            end
        end
        if inbounds
            test_no_boundschecks(fs)
        end
        for subidx in [
            1, CartesianIndex(1), :, rand(Bool, length(val)), rand(eachindex(val), 3), 1:2]
            if check_inference
                @inferred getter(fs, subidx)
                if !isa(val[subidx], Number)
                    @inferred getter(deepcopy(buffer[subidx]), fs, subidx)
                end
            end
            @test getter(fs, subidx) == val[subidx]
            tmp = deepcopy(buffer[subidx])
            if val[subidx] isa Number
                continue
            end
            target = val[subidx]
            if eltype(target) <: Number
                target = collect(target)
            else
                target = collect.(target)
            end
            getter(tmp, fs, subidx)
            @test tmp == target

            if inbounds
                test_no_boundschecks(fs)
            end
        end
    end

    # IndexerOnlyTimeseries
    for (sym, timeseries_index, val, buffer, check_inference) in [
        (bidx, 1, bval, zeros(length(bval)), true),
        ([bidx, :b], 1, vcat.(bval, bval), map(_ -> zeros(2), bval), true),
        ((bidx, :b), 1, tuple.(bval, bval), map(_ -> zeros(2), bval), true),
        ([bidx, bidx], 1, vcat.(bval, bval), map(_ -> zeros(2), bval), true),
        ((bidx, bidx), 1, tuple.(bval, bval), map(_ -> zeros(2), bval), true)
    ]
        getter = getp(sys, sym; inbounds)
        @test is_indexer_timeseries(getter) isa IndexerOnlyTimeseries
        @test indexer_timeseries_index(getter) == timeseries_index

        isscalar = eltype(val) <: Number

        if check_inference
            @inferred getter(fs)
            @inferred getter(deepcopy(buffer), fs)
        end

        @test getter(fs) == val
        target = if isscalar
            val
        else
            collect.(val)
        end
        tmp = deepcopy(buffer)
        getter(tmp, fs)
        @test tmp == target

        @test_throws ParameterTimeseriesValueIndexMismatchError{NotTimeseries} getter(parameter_values(fs))
        @test_throws ParameterTimeseriesValueIndexMismatchError{NotTimeseries} getter(
            [], parameter_values(fs))

        if inbounds
            test_no_boundschecks(fs)
        end
        for subidx in [
            1, CartesianIndex(1), :, rand(Bool, length(val)), rand(eachindex(val), 3), 1:2]
            if check_inference
                @inferred getter(fs, subidx)
                if !isa(val[subidx], Number)
                    @inferred getter(deepcopy(buffer[subidx]), fs, subidx)
                end
            end
            @test getter(fs, subidx) == val[subidx]
            if val[subidx] isa Number
                continue
            end
            tmp = deepcopy(buffer[subidx])
            target = val[subidx]
            if eltype(target) <: Number
                target = collect(target)
            else
                target = collect.(target)
            end
            getter(tmp, fs, subidx)
            @test tmp == target
            if inbounds
                test_no_boundschecks(fs)
            end
        end
    end

    # IndexerMixedTimeseries
    for sym in [
        [:a, :b, :c],
        (:a, :b, :c),
        :(b + c),
        [:(a + b), :c],
        (:(a + b), :c)
    ]
        getter = getp(sys, sym; inbounds)
        @test_throws MixedParameterTimeseriesIndexError getter(fs)
        @test_throws MixedParameterTimeseriesIndexError getter([], fs)
        for subidx in [1, CartesianIndex(1), :, rand(Bool, 4), rand(1:4, 3), 1:2]
            @test_throws MixedParameterTimeseriesIndexError getter(fs, subidx)
            @test_throws MixedParameterTimeseriesIndexError getter([], fs, subidx)
        end
        if inbounds
            test_no_boundschecks(fs)
        end
    end

    for sym in [[:a, bidx], (:a, bidx), [1, bidx], (1, bidx)]
        @test_throws ArgumentError getp(sys, sym; inbounds)
    end

    for (sym, val) in [([:b, :c], [bval[end], cval[end]])
                       ((:b, :c), (bval[end], cval[end]))]
        getter = getp(sys, sym; inbounds)
        @test is_indexer_timeseries(getter) == IndexerMixedTimeseries()
        @test_throws MixedParameterTimeseriesIndexError getter(fs)
        @test getter(parameter_values(fs)) == val
        if inbounds
            test_no_boundschecks(fs)
        end
    end

    xval = @inbounds getindex.(fs.u, 1)

    for (sym, val_is_timeseries, val, check_inference) in [
        (:a, false, aval, true),
        ([:a, :d], false, [aval, dval], true),
        ((:a, :d), false, (aval, dval), true),
        (:b, true, bval, true),
        ([:a, :b], true, vcat.(aval, bval), false),
        ((:a, :b), true, tuple.(aval, bval), true),
        ([:a, :x], true, vcat.(aval, xval), false),
        ((:a, :x), true, tuple.(aval, xval), true),
        (:(2b), true, 2 .* bval, true),
        ([:a, :(2b)], true, vcat.(aval, 2 .* bval), true),
        ((:a, :(2b)), true, tuple.(aval, 2 .* bval), true)
    ]
        getter = getsym(sys, sym; inbounds)
        if check_inference
            @inferred getter(fs)
        end
        @test getter(fs) == val

        reference = val_is_timeseries ? val : xval
        for subidx in [
            1, CartesianIndex(2), :, rand(Bool, length(reference)),
            rand(eachindex(reference), 3), 1:2]
            if check_inference
                @inferred getter(fs, subidx)
            end
            target = if val_is_timeseries
                val[subidx]
            else
                val
            end
            @test getter(fs, subidx) == target
        end
        if inbounds
            test_no_boundschecks(fs)
        end
    end

    temp_state = @inbounds ProblemState(; u = fs.u[1],
        p = with_updated_parameter_timeseries_values(
            sys, parameter_values(fs), 1 => fs.p_ts[1, 1], 2 => fs.p_ts[2, 1]),
        t = fs.t[1])
    _xval = @inbounds temp_state.u[1]
    _bval = @inbounds bval[1]
    _cval = @inbounds cval[1]
    for (sym, val, check_inference) in [
        ([:x, :b], [_xval, _bval], false),
        ((:x, :c), (_xval, _cval), true),
        (:(x + b), _xval + _bval, true),
        ([:(2b), :(3x)], [2_bval, 3_xval], true),
        ((:(2b), :(3x)), (2_bval, 3_xval), true)
    ]
        getter = getsym(sys, sym; inbounds)
        @test_throws MixedParameterTimeseriesIndexError getter(fs)
        for subidx in [1, CartesianIndex(2), :, rand(Bool, 4), rand(1:4, 3), 1:2]
            @test_throws MixedParameterTimeseriesIndexError getter(fs, subidx)
        end
        if check_inference
            @inferred getter(temp_state)
        end
        @test getter(temp_state) == val
        if inbounds
            test_no_boundschecks(temp_state)
        end
    end

    for sym in [
        :err,
        [:err, :b],
        (:err, :b)
    ]
        @test_throws ErrorException getp(sys, sym)
    end

    let fs = fs, sys = sys
        getter = getp(sys, [])
        @test getter(fs) == []
        getter = getp(sys, ())
        @test getter(fs) == ()
        if inbounds
            test_no_boundschecks(fs)
        end
    end
end

struct FakeNoTimeSolution{U <: AbstractVector{Float64}, P <: AbstractVector{Float64}}
    sys::SymbolCache
    u::U
    p::P
end

SymbolicIndexingInterface.state_values(fs::FakeNoTimeSolution) = fs.u
SymbolicIndexingInterface.symbolic_container(fs::FakeNoTimeSolution) = fs.sys
SymbolicIndexingInterface.parameter_values(fs::FakeNoTimeSolution) = fs.p
SymbolicIndexingInterface.parameter_values(fs::FakeNoTimeSolution, i) = fs.p[i]

function test_no_boundschecks(fs::FakeNoTimeSolution)
    test_no_boundschecks(fs.u)
    test_no_boundschecks(fs.p)
end

@testset "FakeNoTimeSolution: inbounds = $inbounds" for inbounds in [false, true]
    sys = SymbolCache([:x, :y, :z], [:a, :b, :c])
    u = [1.0, 2.0, 3.0]
    p = [10.0, 20.0, 30.0]
    fs = FakeNoTimeSolution(sys, maybe_CCA(u, inbounds), maybe_CCA(p, inbounds))

    for (sym, val, check_inference) in [
        (:a, p[1], true),
        ([:a, :b], p[1:2], true),
        ((:c, :b), (p[3], p[2]), true),
        (:(a + b), p[1] + p[2], true),
        ([:(a + b), :c], [p[1] + p[2], p[3]], true),
        ((:(a + b), :c), (p[1] + p[2], p[3]), true)
    ]
        getter = getp(sys, sym; inbounds)
        if check_inference
            @inferred getter(fs)
        end
        @test getter(fs) == val

        if sym isa Union{Array, Tuple}
            buffer = zeros(length(sym))
            @inferred getter(buffer, fs)
            @test buffer == collect(val)
        end
        if inbounds
            test_no_boundschecks(fs)
        end
    end
end
