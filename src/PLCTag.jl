module PLCTag
	include("c.jl")
	
	export PLC, PLCRef
	
	
	const DATA_TIMEOUT = 1000
	
	
	Base.@kwdef struct PLC
		cpu::String
		protocol::String
		gateway::String
		path::String
		debug::Int = 5
	end
	
	
	struct PLCRef{T}
		tag::Ref{Int32}
		count::Int
		
		function PLCRef{T}(plc::PLC, tagName::String, count::Int = 1) where {T}
			isprimitivetype(T) || error("Unable to create a PLCRef for anything other than primitive types")
			
			path = plcpath(plc, tagName, sizeof(T), count)
			
			tag = C.plc_tag_create(path, DATA_TIMEOUT)
			tag <= 0 && error("Unable to create tag `$(tagName)` of type `$(T)` and count $(count)")
			
			result = new{T}(Ref{Int32}(tag), count)
			finalizer(t -> C.plc_tag_destroy(t[]), result.tag)
			return result
		end
	end
	
	
	Base.length(ref::PLCRef) = ref.count
	Base.size(ref::PLCRef) = (ref.count,)
	Base.eltype(ref::PLCRef{T}) where {T} = T
	Base.iterate(ref::PLCRef, state = 1) = state > length(ref) ? nothing : (ref[state], state+1)
	
	function Base.getindex(ref::PLCRef, ind::Int = 1)
		1 <= ind <= length(ref) || error("Index $(ind) is out of range for PLCRef of count $(ref.count)")
		
		code = C.plc_tag_read(ref.tag[], DATA_TIMEOUT)
		code == C.PLCTAG_STATUS_OK || error("ERROR: Unable to read the data! Got error code $(code): $(unsafe_string(C.plc_tag_decode_error(code)))")
		
		val = plcget(eltype(ref), ref.tag[], ind-1)
		return convert(eltype(ref), val)
	end
	
	function Base.setindex!(ref::PLCRef, val, ind::Int = 1)
		1 <= ind <= length(ref) || error("Index $(ind) is out of range for PLCRef of count $(ref.count)")
		
		code = plcset(eltype(ref), ref.tag[], ind-1, convert(eltype(ref), val))
		code == C.PLCTAG_STATUS_OK || error("ERROR: Unable to write the data! Got error code $(code): $(unsafe_string(C.plc_tag_decode_error(code)))")
		
		code = C.plc_tag_write(ref.tag[], DATA_TIMEOUT)
		code == C.PLCTAG_STATUS_OK || error("ERROR: Unable to write the data! Got error code $(code): $(unsafe_string(C.plc_tag_decode_error(code)))")
	end
	
	
	plcpath(plc::PLC, tagName::String, size::Int, count::Int) = join(map(((k, v),) -> "$(k)=$(v)", (
		:cpu => plc.cpu,
		:protocol => plc.protocol,
		:gateway => plc.gateway,
		:path => plc.path,
		:debug => plc.debug,
		:elem_size => size,
		:elem_count => count,
		:name => tagName,
	)), '&')
	
	# TODO: create Bool versions as well
	for T in (
		:Int8, :UInt8, :Int16, :UInt16,
		:Int32, :UInt32, :Int64, :UInt64,
		:Float32, :Float64,
	)
		@eval plcget(::Type{$(T)}, args...; kwargs...) = C.$(Symbol("plc_tag_get_", lowercase(String(T))))(args...; kwargs...)
		@eval plcset(::Type{$(T)}, args...; kwargs...) = C.$(Symbol("plc_tag_set_", lowercase(String(T))))(args...; kwargs...)
		
		@eval Base.$(T)(plc::PLC, tagName::String) = PLCRef{$(T)}(plc, tagName)[]
		@eval function Base.Vector{$(T)}(plc::PLC, tagName::String, count::Int)
			ref = PLCRef{$(T)}(plc, tagName, count)
			return $(T)[ref[i] for i in 1:length(ref)]
		end
	end
	
	
	function Base.String(plc::PLC, tagName::String)
		len = PLCRef{Int32}(plc, "$(tagName).LEN")
		data = PLCRef{UInt8}(plc, "$(tagName).DATA", len[])
		return String(data)
	end
end
