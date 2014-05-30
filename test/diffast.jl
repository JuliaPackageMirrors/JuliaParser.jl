#!/usr/bin/julia

import JuliaParser.Parser

using Base.Test

if length(ARGS) != 1 
    error("need to specify filepath: ./diffast.jl [filepath]")
elseif !ispath(ARGS[1])
    error("need to specify valid filepath, got: $(ARGS[1])")
end

include("ast.jl")

const src = IOBuffer()

# wrap source in toplevel block
write(src, "begin\n")
write(src, open(readall, ARGS[1]))
write(src, "\nend")

const jlsrc = bytestring(src)

tmp1 = tempname()
tmp2 = tempname()

ast = let 
    local ast1::Expr
    open("$tmp1", "w+") do io
        ast1 = Parser.parse(jlsrc) |> without_linenums
        Meta.show_sexpr(io, ast1)
    end

    local ast2::Expr
    open("$tmp2", "w+") do io
        ast2 = parse(jlsrc) |> without_linenums
        Meta.show_sexpr(io, ast2)
    end

    if ast1 == ast2
        print_with_color(:green, "OK\n")
    else
        print_with_color(:red, "FAILED\n")
    end
    
    ast1
end

eval(Main, ast)

run(`gvimdiff $tmp1 $tmp2`)