"""
    struct ProblemState
    function ProblemState(; u = nothing, p = nothing, t = nothing)

A struct which can be used as an argument to the function returned by [`getu`](@ref) or
[`setu`](@ref). It stores the state vector, parameter object and current time, and
forwards calls to [`state_values`](@ref), [`parameter_values`](@ref),
[`current_time`](@ref), [`set_state!`](@ref), [`set_parameter!`](@ref) to the contained
objects.
"""
struct ProblemState{U, P, T}
    u::U
    p::P
    t::T
end

ProblemState(; u = nothing, p = nothing, t = nothing) = ProblemState(u, p, t)

state_values(ps::ProblemState) = ps.u
parameter_values(ps::ProblemState) = ps.p
current_time(ps::ProblemState) = ps.t
set_state!(ps::ProblemState, val, idx) = set_state!(ps.u, val, idx)
set_parameter!(ps::ProblemState, val, idx) = set_parameter!(ps.p, val, idx)
