using Documenter, SymbolicIndexingInterface

cp("./docs/Manifest.toml", "./docs/src/assets/Manifest.toml", force = true)
cp("./docs/Project.toml", "./docs/src/assets/Project.toml", force = true)

include("pages.jl")

makedocs(sitename = "SymbolicIndexingInterface.jl",
         authors = "Chris Rackauckas",
         modules = [SymbolicIndexingInterface],
         clean = true, doctest = false, linkcheck = true,
         warnonly = [:missing_docs],
         format = Documenter.HTML(
                                  assets = ["assets/favicon.ico"],
                                  canonical = "https://docs.sciml.ai/SymbolicIndexingInterface/stable/"),
         pages = pages)

deploydocs(repo = "github.com/SciML/SymbolicIndexingInterface.jl.git";
           push_preview = true)
