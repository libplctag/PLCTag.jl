

# defines AB_SERVER_BIN
include(joinpath(dirname(dirname(pathof(PLCTag))), "deps", "ab_server.jl"))

const TAG_TYPES = Dict(
	:SINT  => (Int8,    :int8),
	:INT   => (Int16,   :int16),
	:DINT  => (Int32,   :int32),
	:LINT  => (Int64,   :int64),
	:USINT => (UInt8,   :uint8),
	:UINT  => (UInt16,  :uint16),
	:UDINT => (UInt32,  :uint32),
	:ULINT => (UInt64,  :uint64),
	:REAL  => (Float32, :float32),
	:LREAL => (Float64, :float64),
)

const TAGS = [
	# (:SINT,  1),  # WARNING: using SINT results in read/write errors from server
	(:INT,   1),
	(:DINT,  1),
	(:LINT,  1),
	(:REAL,  1),
	(:LREAL, 1),
	# (:SINT,  4),  # WARNING: arrays seem problematic too
	# (:INT,   4),
	# (:DINT,  4),
	# (:LINT,  4),
	# (:REAL,  4),
	# (:LREAL, 4),
]


@testset "PLCTag" begin
	server = nothing
	try
		rng = MersenneTwister(123456)
		
		ip = get(ENV, "AB_SERVER_IP", "127.0.0.1")
		if ip == "127.0.0.1"
			server = open(Cmd([AB_SERVER_BIN, "--plc=ControlLogix", "--path=1,0", map(((t, c),) -> "--tag=tag$(t)$(c):$(t)[$(c)]", TAGS)...]))
			timedwait(() -> try ; close(connect(44818)) ; true ; catch ; false ; end, 3.0, pollint = 0.001) === :ok || error("Failed to start libplctag test server")
		end
		
		
		vals = []
		@testset "Low-level API" begin
			@test unsafe_string(LibPLCTag.plc_tag_decode_error(LibPLCTag.PLCTAG_STATUS_OK)) == "PLCTAG_STATUS_OK"
			
			tags = map(TAGS) do (t, c)
				(x, y) = TAG_TYPES[t]
				push!(vals, rand(rng, x, c))
				
				tag = LibPLCTag.plc_tag_create("protocol=ab-eip&gateway=$(ip)&path=1,0&cpu=compactlogix&elem_size=$(sizeof(x))&elem_count=$(c)&name=tag$(t)$(c)&debug=0", 1000)
				@test tag > 0
				@test LibPLCTag.plc_tag_status(tag) == LibPLCTag.PLCTAG_STATUS_OK
				@test LibPLCTag.plc_tag_get_size(tag) == sizeof(x)*c
				@test LibPLCTag.plc_tag_get_int_attribute(tag, "size", -1) == sizeof(x)*c
				@test LibPLCTag.plc_tag_get_int_attribute(tag, "elem_size", -1) == sizeof(x)
				@test LibPLCTag.plc_tag_get_int_attribute(tag, "elem_count", -1) == c
				return (tag, c, x, y)
			end
			
			@testset "Sync Usage" begin
				for (ind, (tag, c, x, y)) in enumerate(tags)
					vals[ind] = rand(rng, x, c)
					for i in eachindex(vals[ind])
						@test getproperty(LibPLCTag, Symbol(:plc_tag_set_, y))(tag, i-1, vals[ind][i]) == LibPLCTag.PLCTAG_STATUS_OK
					end
					@test LibPLCTag.plc_tag_write(tag, 1000) == LibPLCTag.PLCTAG_STATUS_OK
					
					@test LibPLCTag.plc_tag_read(tag, 1000) == LibPLCTag.PLCTAG_STATUS_OK
					for i in eachindex(vals[ind])
						@test getproperty(LibPLCTag, Symbol(:plc_tag_get_, y))(tag, i-1) == vals[ind][i]
					end
				end
			end
			
			@testset "Async Usage" begin
				for (ind, (tag, c, x, y)) in enumerate(tags)
					vals[ind] = rand(rng, x, c)
					for i in eachindex(vals[ind])
						@test getproperty(LibPLCTag, Symbol(:plc_tag_set_, y))(tag, i-1, vals[ind][i]) == LibPLCTag.PLCTAG_STATUS_OK
					end
					@test LibPLCTag.plc_tag_write(tag, 0) in (LibPLCTag.PLCTAG_STATUS_OK, LibPLCTag.PLCTAG_STATUS_PENDING)
					@test timedwait(() -> LibPLCTag.plc_tag_status(tag) == LibPLCTag.PLCTAG_STATUS_OK, 1.0, pollint = 0.001) === :ok
				end
				
				# WARNING: truly async is unsupported by test server?
				# for (ind, (tag, c, x, y)) in enumerate(tags)
				# 	@test timedwait(() -> LibPLCTag.plc_tag_status(tag) == LibPLCTag.PLCTAG_STATUS_OK, 1.0, pollint = 0.001) === :ok
				# end
				
				# for (ind, (tag, c, x, y)) in enumerate(tags)
				# 	@test LibPLCTag.plc_tag_read(tag, 0) in (LibPLCTag.PLCTAG_STATUS_OK, LibPLCTag.PLCTAG_STATUS_PENDING)
				# end
				
				for (ind, (tag, c, x, y)) in enumerate(tags)
					@test LibPLCTag.plc_tag_read(tag, 0) in (LibPLCTag.PLCTAG_STATUS_OK, LibPLCTag.PLCTAG_STATUS_PENDING)
					@test timedwait(() -> LibPLCTag.plc_tag_status(tag) == LibPLCTag.PLCTAG_STATUS_OK, 1.0, pollint = 0.001) === :ok
					for i in eachindex(vals[ind])
						@test getproperty(LibPLCTag, Symbol(:plc_tag_get_, y))(tag, i-1) == vals[ind][i]
					end
				end
			end
			
			for (tag, c, x, y) in tags
				tag > 0 && @test LibPLCTag.plc_tag_destroy(tag) == LibPLCTag.PLCTAG_STATUS_OK
			end
		end
		
		
		@testset "High-level API" begin
			plc = PLC(
				protocol = "ab-eip",
				gateway = "127.0.0.1",
				path = "1,0",
				cpu = "compactlogix",
				debug = 0,
			)
			
			tags = map(TAGS) do (t, c)
				(x, y) = TAG_TYPES[t]
				tag = PLCRef{x}(plc, "tag$(t)$(c)", c)
				@test length(tag) == c
				return (tag, c, x, y)
			end
			
			@testset "Sync Usage" begin
				for (ind, (tag, c, x, y)) in enumerate(tags)
					vals[ind] = rand(rng, x, c)
					
					for i in eachindex(vals[ind])
						tag[i] = vals[ind][i]
						@test tag[i] == vals[ind][i]
					end
				end
			end
			
			@testset "Async Usage" begin
				for (ind, (tag, c, x, y)) in enumerate(tags)
					vals[ind] = rand(rng, x, c)
					
					for i in eachindex(vals[ind])
						write(tag, vals[ind][i], i)
					end
					flush(tag)
				end
				
				# WARNING: truly async is unsupported by test server?
				# for (ind, (tag, c, x, y)) in enumerate(tags)
				# 	flush(tag)
				# end
				
				# for (ind, (tag, c, x, y)) in enumerate(tags)
				# 	read(tag)
				# end
				
				for (ind, (tag, c, x, y)) in enumerate(tags)
					read(tag)
					for i in eachindex(vals[ind])
						@test fetch(tag, i) == vals[ind][i]
					end
				end
			end
		end
		
		
	finally
		isnothing(server) || (kill(server); wait(server))
	end
end

