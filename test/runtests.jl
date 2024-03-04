using SymbolicIndexingInterface
using SafeTestsets
using Test

@time @safetestset "Quality Assurance" include("qa.jl")
@time @safetestset "Interface test" include("example_test.jl")
@time @safetestset "Trait test" include("trait_test.jl")
@time @safetestset "SymbolCache test" include("symbol_cache_test.jl")
@time @safetestset "Fallback test" include("fallback_test.jl")
@time @safetestset "Parameter indexing test" include("parameter_indexing_test.jl")
@time @safetestset "State indexing test" include("state_indexing_test.jl")
