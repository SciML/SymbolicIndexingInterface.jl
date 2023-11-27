var documenterSearchIndex = {"docs":
[{"location":"api/#Interface-Functions","page":"API","title":"Interface Functions","text":"","category":"section"},{"location":"api/","page":"API","title":"API","text":"Default methods cast all symbols to Symbol before comparing.","category":"page"},{"location":"api/","page":"API","title":"API","text":"independent_variables\nis_indep_sym\nstates\nstate_sym_to_index\nis_state_sym\nparameters\nparam_sym_to_index\nis_param_sym","category":"page"},{"location":"api/#SymbolicIndexingInterface.independent_variables","page":"API","title":"SymbolicIndexingInterface.independent_variables","text":"Get an iterable over the independent variables for the given system. Default to an empty vector.\n\n\n\n\n\n","category":"function"},{"location":"api/#SymbolicIndexingInterface.is_indep_sym","page":"API","title":"SymbolicIndexingInterface.is_indep_sym","text":"Check if the given sym is an independent variable in the given system. Default to checking if the given sym exists in the iterable returned by independent_variables.\n\n\n\n\n\n","category":"function"},{"location":"api/#SymbolicIndexingInterface.states","page":"API","title":"SymbolicIndexingInterface.states","text":"Get an iterable over the states for the given system. Default to an empty vector.\n\n\n\n\n\n","category":"function"},{"location":"api/#SymbolicIndexingInterface.state_sym_to_index","page":"API","title":"SymbolicIndexingInterface.state_sym_to_index","text":"Find the index of the given sym in the given system. Default to the index of the first symbol in the iterable returned by states which matches the given sym. Return nothing if the given sym does not match.\n\n\n\n\n\n","category":"function"},{"location":"api/#SymbolicIndexingInterface.is_state_sym","page":"API","title":"SymbolicIndexingInterface.is_state_sym","text":"Check if the given sym is a state variable in the given system. Default to checking if the value returned by state_sym_to_index is not nothing.\n\n\n\n\n\n","category":"function"},{"location":"api/#SymbolicIndexingInterface.parameters","page":"API","title":"SymbolicIndexingInterface.parameters","text":"Get an iterable over the parameters variables for the given system. Default to an empty vector.\n\n\n\n\n\n","category":"function"},{"location":"api/#SymbolicIndexingInterface.param_sym_to_index","page":"API","title":"SymbolicIndexingInterface.param_sym_to_index","text":"Find the index of the given sym in the given system. Default to the index of the first symbol in the iterable retruned by parameters which matches the given sym. Return nothing if the given sym does not match.\n\n\n\n\n\n","category":"function"},{"location":"api/#SymbolicIndexingInterface.is_param_sym","page":"API","title":"SymbolicIndexingInterface.is_param_sym","text":"Check if the given sym is a parameter variable in the given system. Default to checking if the value returned by param_sym_to_index is not nothing.\n\n\n\n\n\n","category":"function"},{"location":"api/#Concrete-Types","page":"API","title":"Concrete Types","text":"","category":"section"},{"location":"api/","page":"API","title":"API","text":"SymbolCache","category":"page"},{"location":"api/#SymbolicIndexingInterface.SymbolCache","page":"API","title":"SymbolicIndexingInterface.SymbolCache","text":"SymbolCache(syms, indepsym, paramsyms)\n\nA container that simply stores a vector of all syms, indepsym and paramsyms.\n\n\n\n\n\n","category":"type"},{"location":"#SymbolicIndexingInterface.jl:-Arrays-of-Arrays-and-Even-Deeper","page":"Home","title":"SymbolicIndexingInterface.jl: Arrays of Arrays and Even Deeper","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"SymbolicIndexingInterface.jl is a set of interface functions for handling containers of symbolic variables. It also contains one such container: SymbolCache.","category":"page"},{"location":"#Installation","page":"Home","title":"Installation","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"To install SymbolicIndexingInterface.jl, use the Julia package manager:","category":"page"},{"location":"","page":"Home","title":"Home","text":"using Pkg\nPkg.add(\"SymbolicIndexingInterface\")","category":"page"},{"location":"#Contributing","page":"Home","title":"Contributing","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"Please refer to the SciML ColPrac: Contributor's Guide on Collaborative Practices for Community Packages for guidance on PRs, issues, and other matters relating to contributing to SciML.\nThere are a few community forums:\nthe #diffeq-bridged channel in the Julia Slack\nJuliaDiffEq on Gitter\non the Julia Discourse forums\nsee also SciML Community page","category":"page"},{"location":"#Reproducibility","page":"Home","title":"Reproducibility","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"<details><summary>The documentation of this SciML package was built using these direct dependencies,</summary>","category":"page"},{"location":"","page":"Home","title":"Home","text":"using Pkg # hide\nPkg.status() # hide","category":"page"},{"location":"","page":"Home","title":"Home","text":"</details>","category":"page"},{"location":"","page":"Home","title":"Home","text":"<details><summary>and using this machine and Julia version.</summary>","category":"page"},{"location":"","page":"Home","title":"Home","text":"using InteractiveUtils # hide\nversioninfo() # hide","category":"page"},{"location":"","page":"Home","title":"Home","text":"</details>","category":"page"},{"location":"","page":"Home","title":"Home","text":"<details><summary>A more complete overview of all dependencies and their versions is also provided.</summary>","category":"page"},{"location":"","page":"Home","title":"Home","text":"using Pkg # hide\nPkg.status(;mode = PKGMODE_MANIFEST) # hide","category":"page"},{"location":"","page":"Home","title":"Home","text":"</details>","category":"page"},{"location":"","page":"Home","title":"Home","text":"You can also download the \n<a href=\"","category":"page"},{"location":"","page":"Home","title":"Home","text":"using TOML\nversion = TOML.parse(read(\"../../Project.toml\",String))[\"version\"]\nname = TOML.parse(read(\"../../Project.toml\",String))[\"name\"]\nlink = \"https://github.com/SciML/\"*name*\".jl/tree/gh-pages/v\"*version*\"/assets/Manifest.toml\"","category":"page"},{"location":"","page":"Home","title":"Home","text":"\">manifest</a> file and the\n<a href=\"","category":"page"},{"location":"","page":"Home","title":"Home","text":"using TOML\nversion = TOML.parse(read(\"../../Project.toml\",String))[\"version\"]\nname = TOML.parse(read(\"../../Project.toml\",String))[\"name\"]\nlink = \"https://github.com/SciML/\"*name*\".jl/tree/gh-pages/v\"*version*\"/assets/Project.toml\"","category":"page"},{"location":"","page":"Home","title":"Home","text":"\">project</a> file.","category":"page"}]
}