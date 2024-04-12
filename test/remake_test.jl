using SymbolicIndexingInterface
using StaticArrays

sys = SymbolCache([:x, :y, :z], [:a, :b, :c], :t)

for (buf, newbuf, newvals) in [
    # standard operation
    ([1.0, 2.0, 3.0], [2.0, 3.0, 4.0], Dict(:x => 2.0, :y => 3.0, :z => 4.0)),
    # buffer type "demotion"
    ([1.0, 2.0, 3.0], [2, 2, 3], Dict(:x => 2)),
    # buffer type promotion
    ([1, 2, 3], [2.0, 2.0, 3.0], Dict(:x => 2.0)),
    # value type promotion
    ([1, 2, 3], [2.0, 3.0, 4.0], Dict(:x => 2, :y => 3.0, :z => 4.0)),
    # standard operation
    ([1.0, 2.0, 3.0], [2.0, 3.0, 4.0], Dict(:a => 2.0, :b => 3.0, :c => 4.0)),
    # buffer type "demotion"
    ([1.0, 2.0, 3.0], [2, 2, 3], Dict(:a => 2)),
    # buffer type promotion
    ([1, 2, 3], [2.0, 2.0, 3.0], Dict(:a => 2.0)),
    # value type promotion
    ([1, 2, 3], [2, 3.0, 4.0], Dict(:a => 2, :b => 3.0, :c => 4.0))
]
    for arrType in [Vector, SVector{3}, MVector{3}, SizedVector{3}]
        buf = arrType(buf)
        newbuf = arrType(newbuf)
        _newbuf = remake_buffer(sys, buf, newvals)

        @test _newbuf != buf # should not alias
        @test newbuf == _newbuf # test values
        @test typeof(newbuf) == typeof(_newbuf) # ensure appropriate type
    end
end

# Tuples not allowed for state
for (buf, newbuf, newvals) in [
    # standard operation
    ((1.0, 2.0, 3.0), (2.0, 3.0, 4.0), Dict(:a => 2.0, :b => 3.0, :c => 4.0)),
    # buffer type "demotion"
    ((1.0, 2.0, 3.0), (2, 3, 4), Dict(:a => 2, :b => 3, :c => 4)),
    # buffer type promotion
    ((1, 2, 3), (2.0, 3.0, 4.0), Dict(:a => 2.0, :b => 3.0, :c => 4.0)),
    # value type promotion
    ((1, 2, 3), (2, 3.0, 4.0), Dict(:a => 2, :b => 3.0, :c => 4.0))
]
    _newbuf = remake_buffer(sys, buf, newvals)
    @test newbuf == _newbuf # test values
    @test typeof(newbuf) == typeof(_newbuf) # ensure appropriate type
end
