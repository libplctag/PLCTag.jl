using BinDeps

BinDeps.@setup

version = "2.0.22"
plctag = library_dependency("libplctag")

provides(
	Sources,
	URI("https://github.com/kyle-github/libplctag/archive/v$(version).tar.gz"),
	plctag,
	unpacked_dir = "libplctag-$(version)",
)

srcdir = joinpath(BinDeps.srcdir(plctag), "libplctag-$(version)")
blddir = joinpath(srcdir, "build")
provides(
	BuildProcess,
	@build_steps(begin
		GetSources(plctag)
		CreateDirectory(blddir)
		@build_steps(begin
			ChangeDirectory(blddir)
			FileRule(
				joinpath(BinDeps.libdir(plctag), "libplctag.so"),
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
