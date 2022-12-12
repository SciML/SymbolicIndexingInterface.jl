"""
$(TYPEDSIGNATURES)

Get the set of independent variables for the given system.
"""
function independent_variables end

"""
$(TYPEDSIGNATURES)

Check if the given sym is an independent variable in the given system. Defaults
to `false` if not implemented for the given system/container type.
"""
function is_indep_sym end

"""
$(TYPEDSIGNATURES)

Get the set of states for the given system.
"""
function states end

"""
$(TYPEDSIGNATURES)

Find the index of the given sym in the given system.
"""
function state_sym_to_index end

"""
$(TYPEDSIGNATURES)

Check if the given sym is a state variable in the given system. Defaults
to `false` if not implemented for the given system/container type.
"""
function is_state_sym end

"""
$(TYPEDSIGNATURES)

Get the set of parameters variables for the given system.
"""
function parameters end

"""
$(TYPEDSIGNATURES)

Find the index of the given sym in the given system.
"""
function param_sym_to_index end

"""
$(TYPEDSIGNATURES)

Check if the given sym is a parameter variable in the given system. Defaults
to `false` if not implemented for the given system/container type.
"""
function is_param_sym end
