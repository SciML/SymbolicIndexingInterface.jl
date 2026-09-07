@setup_workload begin
    indp = SymbolCache([:x, :y], [:a, :b], :t)
    valp = ProblemState(; u = [1.0, 2.0], p = [3.0, 4.0], t = 0.5)

    @compile_workload begin
        variable_symbols(indp)
        state_values(valp)
        parameter_values(valp)
    end
end
