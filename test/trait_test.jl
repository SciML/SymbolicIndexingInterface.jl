using SymbolicUtils
using Symbolics
using SymbolicIndexingInterface
using Test

@test all(issymbolic.([Int, Float64, String, Bool, UInt, Complex{Float64}]) .==
          (NotSymbolic(),))
@test all(issymbolic.([Symbol, SymbolicUtils.BasicSymbolic, Symbolics.Num]) .==
          (Symbolic(),))
@variables x
@test issymbolic(x) == Symbolic()
@variables y[1:3]
@test issymbolic(y) == NotSymbolic()
@test all(issymbolic.(collect(y)) .== (Symbolic(),))
