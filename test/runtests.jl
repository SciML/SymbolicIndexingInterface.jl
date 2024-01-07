using SymbolicIndexingInterface
using SafeTestsets
using Test

@safetestset "Quality Assurance" @time include("qa.jl")
@safetestset "Interface test" @time include("example_test.jl")
@safetestset "Trait test" @time include("trait_test.jl")
@safetestset "SymbolCache test" @time include("symbol_cache_test.jl")
@safetestset "Fallback test" @time include("fallback_test.jl")
@safetestset "Parameter indexing test" @time include("parameter_indexing_test.jl")
@safetestset "State indexing test" @time include("state_indexing_test.jl")
