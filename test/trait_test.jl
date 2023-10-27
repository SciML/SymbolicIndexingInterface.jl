using SymbolicUtils
using Symbolics
using SymbolicIndexingInterface
using Test

@test all(symbolic_type.([Int, Float64, String, Bool, UInt, Complex{Float64}]) .==
          (NotSymbolic(),))
@test all(symbolic_type.([Symbol, SymbolicUtils.BasicSymbolic, Symbolics.Num]) .==
          (ScalarSymbolic(),))
@test symbolic_type(Symbolics.Arr) == ArraySymbolic()
@variables x
@test symbolic_type(x) == ScalarSymbolic()
@variables y[1:3]
@test symbolic_type(y) == ArraySymbolic()
@test all(symbolic_type.(collect(y)) .== (ScalarSymbolic(),))
