using SymbolicIndexingInterface
using Test

@time begin @time @testset begin include("symbolcache.jl") end end
@time begin @time @testset begin include("default_function_test.jl") end end