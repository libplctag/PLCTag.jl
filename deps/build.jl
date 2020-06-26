using BinDeps
using CMakeWrapper
using CBindingGen

BinDeps.@setup

version = get(ENV, "LIBPLCTAG_VERSION",  "2.1.6")
plctag = library_dependency("libplctag")

rm(BinDeps.srcdir(plctag); force = true, recursive = true)
rm(BinDeps.usrdir(plctag); force = true, recursive = true)

provides(
	Sources,
	URI("https://github.com/libplctag/libplctag/archive/v$(version).tar.gz"),
	plctag,
	unpacked_dir = "libplctag-$(version)",
)

srcdir = joinpath(BinDeps.srcdir(plctag), "libplctag-$(version)")
blddir = joinpath(srcdir, "build")
lib = joinpath(BinDeps.libdir(plctag), Sys.isapple() ? "libplctag.dylib" : "libplctag.so")
provides(
	BuildProcess,
	@build_steps(begin
		GetSources(plctag)
		CMakeBuild(
			srcdir = srcdir,
			builddir = blddir,
			prefix = BinDeps.usrdir(plctag),
			installed_libpath = [lib],
		)
	end),
	plctag,
)

BinDeps.@install Dict(:plctag => :_plctag)



incdir = joinpath(BinDeps.usrdir(plctag), "include")
cvts = convert_header("libplctag.h", args = ["-I", incdir, "-fparse-all-comments"]) do cursor
	header = CodeLocation(cursor).file
	name   = string(cursor)
	
	# only wrap the libplctag headers
	startswith(header, "$(incdir)/") || return false
	
	return true
end

open(joinpath(@__DIR__, "libplctag.jl"), "w+") do io
	generate(io, lib => cvts)
end


open(joinpath(@__DIR__, "ab_server.jl"), "w+") do io
	println(io, "const AB_SERVER_BIN = $(repr(joinpath(blddir, "bin_dist", "ab_server")))")
end

