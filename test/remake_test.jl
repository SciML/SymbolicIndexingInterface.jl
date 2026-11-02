using SymbolicIndexingInterface
using StaticArrays

sys = SymbolCache([:x, :y, :z], [:a, :b, :c], :t)

for (buf, newbuf, idxs, vals) in [
        # standard operation
        ([1.0, 2.0, 3.0], [2.0, 3.0, 4.0], [:x, :y, :z], [2.0, 3.0, 4.0]),
        # buffer type "demotion"
        ([1.0, 2.0, 3.0], [2, 2, 3], [:x], [2]),
        # buffer type promotion
        ([1, 2, 3], [2.0, 2.0, 3.0], [:x], [2.0]),
        # value type promotion
        ([1, 2, 3], [2.0, 3.0, 4.0], [:x, :y, :z], Real[2, 3.0, 4.0]),
        # standard operation
        ([1.0, 2.0, 3.0], [2.0, 3.0, 4.0], [:a, :b, :c], [2.0, 3.0, 4.0]),
        # buffer type "demotion"
        ([1.0, 2.0, 3.0], [2, 2, 3], [:a], [2]),
        # buffer type promotion
        ([1, 2, 3], [2.0, 2.0, 3.0], [:a], [2.0]),
        # value type promotion
        ([1, 2, 3], [2, 3.0, 4.0], [:a, :b, :c], Real[2, 3.0, 4.0]),
        # skip non-parameters
        ([1, 2, 3], [2.0, 3.0, 3.0], [:a, :b, :(a + b)], [2.0, 3.0, 5.0]),
    ]
    @test_deprecated remake_buffer(sys, buf, Dict(idxs .=> vals))
    for varmap in [Dict(idxs .=> vals), Dict{Any, Any}(idxs .=> vals)]
        _newbuf = remake_buffer(sys, buf, keys(varmap), values(varmap))
        @test _newbuf != buf
        @test newbuf == _newbuf
        @test typeof(newbuf) == typeof(_newbuf)
    end
    for arrType in [Vector, SVector{3}, MVector{3}, SizedVector{3}]
        buf = arrType(buf)
        newbuf = arrType(newbuf)
        _newbuf = remake_buffer(sys, buf, idxs, vals)

        @test _newbuf != buf # should not alias
        @test newbuf == _newbuf # test values
        @test typeof(newbuf) == typeof(_newbuf) # ensure appropriate type
    end
end

for (buf, newbuf, idxs, vals) in [
        # standard operation
        ((1.0, 2.0, 3.0), (2.0, 3.0, 4.0), [:a, :b, :c], [2.0, 3.0, 4.0]),
        # buffer type "demotion"
        ((1.0, 2.0, 3.0), (2, 3, 4), [:a, :b, :c], [2, 3, 4]),
        # buffer type promotion
        ((1, 2, 3), (2.0, 3.0, 4.0), [:a, :b, :c], [2.0, 3.0, 4.0]),
        # value type promotion
        ((1, 2, 3), (2, 3.0, 4.0), [:a, :b, :c], Real[2, 3.0, 4.0]),
        # standard operation
        ((1.0, 2.0, 3.0), (2.0, 3.0, 4.0), [:x, :y, :z], [2.0, 3.0, 4.0]),
        # buffer type "demotion"
        ((1.0, 2.0, 3.0), (2, 3, 4), [:x, :y, :z], [2, 3, 4]),
        # buffer type promotion
        ((1, 2, 3), (2.0, 3.0, 4.0), [:x, :y, :z], [2.0, 3.0, 4.0]),
        # value type promotion
        ((1, 2, 3), (2, 3.0, 4.0), [:x, :y, :z], Real[2, 3.0, 4.0]),
        # skip non-variables
        ([1, 2, 3], [2.0, 3.0, 3.0], [:x, :y, :(x + y)], [2.0, 3.0, 5.0]),
    ]
    @test_deprecated remake_buffer(sys, buf, Dict(idxs .=> vals))
    for varmap in [Dict(idxs .=> vals), Dict{Any, Any}(idxs .=> vals)]
        _newbuf = remake_buffer(sys, buf, keys(varmap), values(varmap))
        @test newbuf == _newbuf
        @test typeof(newbuf) == typeof(_newbuf)
    end
    _newbuf = remake_buffer(sys, buf, idxs, vals)
    @test newbuf == _newbuf # test values
    @test typeof(newbuf) == typeof(_newbuf) # ensure appropriate type
end

@test isnothing(remake_buffer(sys, nothing, [], []))

@testset "`remake_buffer` with `Dict`" begin
    sys = nothing
    buf = Dict("a" => 1, "b" => 2)
    buf2 = remake_buffer(sys, buf, collect(keys(buf)), collect(values(buf)))
    @test isequal(buf, buf2)
    buf2 = remake_buffer(sys, buf, keys(buf), values(buf))
    @test isequal(buf, buf2)
end

struct UnsupportedRemakeBuffer
    v::Vector{Float64}
end

struct DictOnlyRemakeBuffer
    v::Vector{Float64}
end

struct NarrowDictOnlyRemakeBuffer
    v::Vector{Float64}
end

function _dict_only_remake(sys, oldbuffer, vals::Dict)
    newv = copy(oldbuffer.v)
    for (k, val) in vals
        i = variable_index(sys, k)
        i === nothing || (newv[i] = val)
    end
    return typeof(oldbuffer)(newv)
end

function SymbolicIndexingInterface.remake_buffer(
        sys, oldbuffer::DictOnlyRemakeBuffer, vals::Dict
    )
    return _dict_only_remake(sys, oldbuffer, vals)
end

function SymbolicIndexingInterface.remake_buffer(
        sys, oldbuffer::NarrowDictOnlyRemakeBuffer, vals::Dict{Symbol, Float64}
    )
    return _dict_only_remake(sys, oldbuffer, vals)
end

@testset "`remake_buffer` unsupported buffer types" begin
    sys = SymbolCache([:x, :y, :z], [:a, :b, :c], :t)
    nt_err = @test_throws ArgumentError remake_buffer(
        sys, (x = 1.0, y = 2.0, z = 3.0), [:x], [9.0]
    )
    @test occursin("NamedTuple", sprint(showerror, nt_err.value))
    @test occursin("remake_buffer", sprint(showerror, nt_err.value))

    custom_err = @test_throws ArgumentError remake_buffer(
        sys, UnsupportedRemakeBuffer([1.0, 2.0, 3.0]), [:x], [9.0]
    )
    @test occursin("UnsupportedRemakeBuffer", sprint(showerror, custom_err.value))
    @test occursin("remake_buffer", sprint(showerror, custom_err.value))
end

struct NestedInnerRemakeBuffer
    v::Vector{Float64}
end

struct NestedOuterRemakeBuffer
    a::NestedInnerRemakeBuffer
    v::Vector{Float64}
end

function SymbolicIndexingInterface.remake_buffer(
        sys, oldbuffer::NestedInnerRemakeBuffer, vals::Dict
    )
    return _dict_only_remake(sys, oldbuffer, vals)
end

function SymbolicIndexingInterface.remake_buffer(
        sys, oldbuffer::NestedOuterRemakeBuffer, vals::Dict
    )
    inner = remake_buffer(sys, oldbuffer.a, collect(keys(vals)), collect(values(vals)))
    newv = copy(oldbuffer.v)
    for (k, val) in vals
        i = variable_index(sys, k)
        i === nothing || (newv[i] = val)
    end
    return NestedOuterRemakeBuffer(inner, newv)
end

struct OneAtATimeRemakeBuffer
    v::Vector{Float64}
end

function SymbolicIndexingInterface.remake_buffer(
        sys, oldbuffer::OneAtATimeRemakeBuffer, vals::Dict
    )
    if length(vals) == 1
        return _dict_only_remake(sys, oldbuffer, vals)
    end
    k1 = first(keys(vals))
    buf = remake_buffer(sys, oldbuffer, [k1], [vals[k1]])
    rest_ks = [k for k in keys(vals) if k !== k1]
    rest_vs = [vals[k] for k in rest_ks]
    return remake_buffer(sys, buf, rest_ks, rest_vs)
end

struct IsbitsRemakeBuffer
    x::Float64
    y::Float64
    z::Float64
end

function SymbolicIndexingInterface.remake_buffer(
        sys, oldbuffer::IsbitsRemakeBuffer, vals::Dict
    )
    if length(vals) == 1
        k, v = only(pairs(vals))
        x, y, z = oldbuffer.x, oldbuffer.y, oldbuffer.z
        if k === :x || k === 1
            x = v
        elseif k === :y || k === 2
            y = v
        elseif k === :z || k === 3
            z = v
        end
        return IsbitsRemakeBuffer(x, y, z)
    end
    k1 = first(keys(vals))
    buf = remake_buffer(sys, oldbuffer, [k1], [vals[k1]])
    rest_ks = [k for k in keys(vals) if k !== k1]
    rest_vs = [vals[k] for k in rest_ks]
    return remake_buffer(sys, buf, rest_ks, rest_vs)
end

@testset "`remake_buffer` Dict-only implementer" begin
    sys = SymbolCache([:x, :y, :z], [:a, :b, :c], :t)
    buf = DictOnlyRemakeBuffer([1.0, 2.0, 3.0])
    newbuf = remake_buffer(sys, buf, [:y], [7.0])
    @test newbuf isa DictOnlyRemakeBuffer
    @test newbuf.v == [1.0, 7.0, 3.0]

    narrow = NarrowDictOnlyRemakeBuffer([1.0, 2.0, 3.0])
    newnarrow = remake_buffer(sys, narrow, [:y], [7.0])
    @test newnarrow isa NarrowDictOnlyRemakeBuffer
    @test newnarrow.v == [1.0, 7.0, 3.0]

    nested = NestedOuterRemakeBuffer(
        NestedInnerRemakeBuffer([1.0, 2.0, 3.0]), [1.0, 2.0, 3.0]
    )
    newnested = remake_buffer(sys, nested, [:y], [7.0])
    @test newnested isa NestedOuterRemakeBuffer
    @test newnested.a.v == [1.0, 7.0, 3.0]
    @test newnested.v == [1.0, 7.0, 3.0]

    one = remake_buffer(
        sys, OneAtATimeRemakeBuffer([1.0, 2.0, 3.0]), [:x, :y], [9.0, 8.0]
    )
    @test one isa OneAtATimeRemakeBuffer
    @test one.v == [9.0, 8.0, 3.0]

    isbits_changed = remake_buffer(
        sys, IsbitsRemakeBuffer(1.0, 2.0, 3.0), [:x, :y], [9.0, 8.0]
    )
    @test isbits_changed == IsbitsRemakeBuffer(9.0, 8.0, 3.0)
    isbits_equal_peel = remake_buffer(
        sys, IsbitsRemakeBuffer(1.0, 2.0, 3.0), [:x, :y], [1.0, 8.0]
    )
    @test isbits_equal_peel == IsbitsRemakeBuffer(1.0, 8.0, 3.0)
end
