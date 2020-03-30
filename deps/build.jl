using BinDeps, CBindingGen

BinDeps.@setup

version = "2.0.35"
plctag = library_dependency("libplctag")

rm(BinDeps.usrdir(plctag); force = true, recursive = true)

provides(
	Sources,
	URI("https://github.com/kyle-github/libplctag/archive/v$(version).tar.gz"),
	plctag,
	unpacked_dir = "libplctag-$(version)",
)

srcdir = joinpath(BinDeps.srcdir(plctag), "libplctag-$(version)")
blddir = joinpath(srcdir, "build")
lib = joinpath(BinDeps.libdir(plctag), "libplctag.so")
provides(
	BuildProcess,
	@build_steps(begin
		GetSources(plctag)
		CreateDirectory(blddir)
		@build_steps(begin
			ChangeDirectory(blddir)
			FileRule(
				lib,
				@build_steps(begin
					`cmake -DCMAKE_INSTALL_PREFIX="$(BinDeps.usrdir(plctag))" $(srcdir)`
					`make`
					`make install`
				end),
			)
		end)
	end),
	plctag,
)

BinDeps.@install Dict(:plctag => :_plctag)



incdir = joinpath(dirname(dirname(lib)), "include")
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



