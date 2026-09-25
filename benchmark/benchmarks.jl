using SymbolicIndexingInterface, BenchmarkTools

const SUITE = BenchmarkGroup()

sys = SymbolCache(
    [:x, :y, :z], [:a, :b], :t;
    defaults = Dict(:x => 1, :y => :(2b), :b => :(2a + x))
)
sys_plain = SymbolCache([:x, :y, :z], [:a, :b], :t)

u = ones(3)
p = 2ones(2)
t = 3.0

# =============================================================================
# SymbolCache
# =============================================================================

SUITE["symbol_cache"] = BenchmarkGroup()
SUITE["symbol_cache"]["construct"] = @benchmarkable SymbolCache(
    [:x, :y, :z], [:a, :b], :t
)
SUITE["symbol_cache"]["construct_defaults"] = @benchmarkable SymbolCache(
    [:x, :y, :z], [:a, :b], :t;
    defaults = Dict(:x => 1, :y => :(2b), :b => :(2a + x))
)
SUITE["symbol_cache"]["variable_symbols"] = @benchmarkable variable_symbols($sys)
SUITE["symbol_cache"]["variable_index"] = @benchmarkable variable_index($sys, :y)
SUITE["symbol_cache"]["symbolic_evaluate"] = @benchmarkable symbolic_evaluate(
    :(x + y), merge(default_values($sys), Dict(:a => 2))
)

# =============================================================================
# observed / parameter_observed function generation and evaluation
# =============================================================================

SUITE["observed"] = BenchmarkGroup()

SUITE["observed"]["create"] = @benchmarkable observed($sys_plain, :(x + a + t))
SUITE["observed"]["create_vector"] = @benchmarkable observed(
    $sys_plain, [:(x + a), :(a + t)]
)

obsfn = observed(sys_plain, :(x + a + t))
obsfn_vec = observed(sys_plain, [:(x + a), :(a + t)])
pobsfn = parameter_observed(sys_plain, :(a + b + t))

SUITE["observed"]["eval"] = @benchmarkable $obsfn($u, $p, $t)
SUITE["observed"]["eval_vector"] = @benchmarkable $obsfn_vec($u, $p, $t)
SUITE["observed"]["parameter_eval"] = @benchmarkable $pobsfn($p, $t)

# =============================================================================
# remake_buffer
# =============================================================================

SUITE["remake_buffer"] = BenchmarkGroup()

buf = [1.0, 2.0, 3.0]
SUITE["remake_buffer"]["vector"] = @benchmarkable remake_buffer(
    $sys_plain, $buf, [:x, :y], [2.0, 3.0]
)
SUITE["remake_buffer"]["params"] = @benchmarkable remake_buffer(
    $sys_plain, $buf, [:a, :b], [2.0, 3.0]
)
