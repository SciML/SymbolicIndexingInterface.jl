using SymbolicIndexingInterface
using AllocCheck
using Test

@testset "AllocCheck - Zero Allocation Getters/Setters" begin
    # Create test data
    sys = SymbolCache([:x, :y, :z], [:a, :b, :c, :d], [:t])
    p = [1.0, 2.0, 3.0, 4.0]
    u = [10.0, 20.0, 30.0]
    t = 0.5
    ps = ProblemState(; u = u, p = p, t = t)

    # Test scalar parameter getter - should not allocate
    @testset "Scalar getp" begin
        getter = getp(sys, :a)
        # Warm up
        getter(p)
        getter(ps)

        @check_allocs test_scalar_getp_p(getter, p) = getter(p)
        @test test_scalar_getp_p(getter, p) == p[1]

        @check_allocs test_scalar_getp_ps(getter, ps) = getter(ps)
        @test test_scalar_getp_ps(getter, ps) == p[1]
    end

    # Test scalar state getter - should not allocate
    @testset "Scalar getsym" begin
        getter = getsym(sys, :x)
        # Warm up
        getter(u)
        getter(ps)

        @check_allocs test_scalar_getsym_u(getter, u) = getter(u)
        @test test_scalar_getsym_u(getter, u) == u[1]

        @check_allocs test_scalar_getsym_ps(getter, ps) = getter(ps)
        @test test_scalar_getsym_ps(getter, ps) == u[1]
    end

    # Test tuple parameter getter - should not allocate
    @testset "Tuple getp" begin
        getter = getp(sys, (:a, :b, :c))
        # Warm up
        getter(ps)

        @check_allocs test_tuple_getp(getter, ps) = getter(ps)
        @test test_tuple_getp(getter, ps) == (p[1], p[2], p[3])
    end

    # Test tuple state getter - should not allocate
    @testset "Tuple getsym" begin
        getter = getsym(sys, (:x, :y, :z))
        # Warm up
        getter(ps)

        @check_allocs test_tuple_getsym(getter, ps) = getter(ps)
        @test test_tuple_getsym(getter, ps) == (u[1], u[2], u[3])
    end

    # Test scalar parameter setter - should not allocate
    @testset "Scalar setp" begin
        setter = setp(sys, :a)
        p_copy = copy(p)
        # Warm up
        setter(p_copy, 5.0)

        @check_allocs test_scalar_setp(setter, p_copy, val) = setter(p_copy, val)
        test_scalar_setp(setter, p_copy, 6.0)
        @test p_copy[1] == 6.0
    end

    # Test scalar state setter - should not allocate
    @testset "Scalar setsym" begin
        setter = setsym(sys, :x)
        u_copy = copy(u)
        # Warm up
        setter(u_copy, 5.0)

        @check_allocs test_scalar_setsym(setter, u_copy, val) = setter(u_copy, val)
        test_scalar_setsym(setter, u_copy, 6.0)
        @test u_copy[1] == 6.0
    end

    # Test in-place array getter - should not allocate
    @testset "In-place getp" begin
        getter = getp(sys, [:a, :b, :c])
        buffer = zeros(3)
        # Warm up
        getter(buffer, ps)

        @check_allocs test_inplace_getp(getter, buffer, ps) = getter(buffer, ps)
        test_inplace_getp(getter, buffer, ps)
        @test buffer == p[1:3]
    end

    # Test observed function evaluation - should not allocate after construction
    @testset "Observed getsym" begin
        # Use a simple expression
        getter = getsym(sys, :(x + y))
        # Warm up - RGF compilation
        getter(ps)
        getter(ps)

        @check_allocs test_observed_getsym(getter, ps) = getter(ps)
        @test test_observed_getsym(getter, ps) == u[1] + u[2]
    end

    # Test index lookups - should not allocate
    @testset "Index lookups" begin
        @check_allocs test_variable_index(sys, sym) = variable_index(sys, sym)
        @test test_variable_index(sys, :x) == 1

        @check_allocs test_parameter_index(sys, sym) = parameter_index(sys, sym)
        @test test_parameter_index(sys, :a) == 1

        @check_allocs test_is_variable(sys, sym) = is_variable(sys, sym)
        @test test_is_variable(sys, :x) == true

        @check_allocs test_is_parameter(sys, sym) = is_parameter(sys, sym)
        @test test_is_parameter(sys, :a) == true
    end

    # Test value provider interface functions
    @testset "Value provider interface" begin
        @check_allocs test_parameter_values(p) = parameter_values(p)
        @test test_parameter_values(p) == p

        @check_allocs test_state_values(u) = state_values(u)
        @test test_state_values(u) == u

        @check_allocs test_current_time_vec(t_vec) = current_time(t_vec)
        t_vec = [0.0, 0.5, 1.0]
        @test test_current_time_vec(t_vec) == t_vec
    end
end

@testset "AllocCheck - Multiple setter" begin
    sys = SymbolCache([:x, :y, :z], [:a, :b, :c, :d], [:t])
    p = [1.0, 2.0, 3.0, 4.0]

    # Test tuple setter
    setter = setp(sys, (:a, :b))
    p_copy = copy(p)
    # Warm up
    setter(p_copy, (5.0, 6.0))

    @check_allocs test_tuple_setp(setter, p_copy, val) = setter(p_copy, val)
    test_tuple_setp(setter, p_copy, (7.0, 8.0))
    @test p_copy[1] == 7.0
    @test p_copy[2] == 8.0
end
