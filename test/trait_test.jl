using SymbolicIndexingInterface
using Test

@test all(symbolic_type.([Int, Float64, String, Bool, UInt, Complex{Float64}]) .==
          (NotSymbolic(),))
@test symbolic_type(Symbol) == ScalarSymbolic()
