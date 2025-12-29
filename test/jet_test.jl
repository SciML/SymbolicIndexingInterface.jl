using SymbolicIndexingInterface
using JET
using Test

@testset "JET static analysis" begin
    sc = SymbolCache([:x, :y, :z], [:a, :b, :c], :t)

    struct TestProblem
        u::Vector{Float64}
        p::Vector{Float64}
        t::Float64
    end

    SymbolicIndexingInterface.symbolic_container(sp::TestProblem) = sc
    SymbolicIndexingInterface.state_values(sp::TestProblem) = sp.u
    SymbolicIndexingInterface.parameter_values(sp::TestProblem) = sp.p
    SymbolicIndexingInterface.current_time(sp::TestProblem) = sp.t
    SymbolicIndexingInterface.is_time_dependent(::TestProblem) = true

    prob = TestProblem([1.0, 2.0, 3.0], [4.0, 5.0, 6.0], 0.0)

    @testset "Interface functions" begin
        rep = JET.report_call(is_variable, (typeof(sc), Symbol))
        @test length(JET.get_reports(rep)) == 0

        rep = JET.report_call(is_parameter, (typeof(sc), Symbol))
        @test length(JET.get_reports(rep)) == 0

        rep = JET.report_call(variable_index, (typeof(sc), Symbol))
        @test length(JET.get_reports(rep)) == 0

        rep = JET.report_call(parameter_index, (typeof(sc), Symbol))
        @test length(JET.get_reports(rep)) == 0

        rep = JET.report_call(is_observed, (typeof(sc), Symbol))
        @test length(JET.get_reports(rep)) == 0

        rep = JET.report_call(symbolic_type, (Symbol,))
        @test length(JET.get_reports(rep)) == 0

        rep = JET.report_call(variable_symbols, (typeof(sc),))
        @test length(JET.get_reports(rep)) == 0

        rep = JET.report_call(parameter_symbols, (typeof(sc),))
        @test length(JET.get_reports(rep)) == 0
    end

    @testset "Getter/setter construction" begin
        rep = JET.report_call(getp, (typeof(sc), Symbol))
        @test length(JET.get_reports(rep)) == 0

        rep = JET.report_call(setp, (typeof(sc), Symbol))
        @test length(JET.get_reports(rep)) == 0
    end

    @testset "Getter/setter execution" begin
        getter_a = getp(sc, :a)
        rep = JET.report_call(getter_a, (TestProblem,))
        @test length(JET.get_reports(rep)) == 0

        getter_x = getsym(sc, :x)
        rep = JET.report_call(getter_x, (TestProblem,))
        @test length(JET.get_reports(rep)) == 0
    end

    @testset "Type optimization" begin
        @test_opt target_modules = (SymbolicIndexingInterface,) is_variable(sc, :x)
        @test_opt target_modules = (SymbolicIndexingInterface,) is_parameter(sc, :a)
        @test_opt target_modules = (SymbolicIndexingInterface,) symbolic_type(:x)
        @test_opt target_modules = (SymbolicIndexingInterface,) variable_symbols(sc)
        @test_opt target_modules = (SymbolicIndexingInterface,) parameter_symbols(sc)
    end

    @testset "Getter execution type optimization" begin
        getter_a = getp(sc, :a)
        getter_x = getsym(sc, :x)

        @test_opt target_modules = (SymbolicIndexingInterface,) getter_a(prob)
        @test_opt target_modules = (SymbolicIndexingInterface,) getter_x(prob)
    end
end
