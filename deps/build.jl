using BinDeps
using CMakeWrapper

BinDeps.@setup

version = get(ENV, "LIBPLCTAG_VERSION",  "2.3.5")

plctag = library_dependency("libplctag", aliases = ["plctag"])
if Sys.iswindows()
	bindir = joinpath(BinDeps.depsdir(plctag), plctag.name)
	lib = joinpath(bindir, "Release", "plctag.dll")
	
	rm(bindir; force = true, recursive = true)
	
	provides(
		Binaries,
		URI("https://github.com/libplctag/libplctag/releases/download/v$(version)/libplctag_$(version)_windows_x86.zip"),
		plctag,
		installed_libpath = lib,
		unpacked_dir = ".",
	)
else
	srcdir = joinpath(BinDeps.srcdir(plctag), "libplctag-$(version)")
	blddir = joinpath(srcdir, "build")
	lib = joinpath(BinDeps.libdir(plctag), Sys.isapple() ? "libplctag.dylib" : "libplctag.so")
	
	rm(BinDeps.srcdir(plctag); force = true, recursive = true)
	rm(BinDeps.usrdir(plctag); force = true, recursive = true)
	
	provides(
		Sources,
		URI("https://github.com/libplctag/libplctag/archive/v$(version).tar.gz"),
		plctag,
		unpacked_dir = srcdir,
	)
	
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
	
	open(joinpath(@__DIR__, "ab_server.jl"), "w+") do io
		println(io, "const AB_SERVER_BIN = $(repr(joinpath(blddir, "bin_dist", "ab_server")))")
	end
end

BinDeps.@install Dict(:plctag => :_plctag)

