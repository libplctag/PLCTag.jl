module PLCTag
	include("c.jl")
	
	export PLC, PLCRef, PLCBinding
	
	
	Base.@kwdef struct PLC
		cpu::String
		protocol::String
		gateway::String
		path::String
		debug::Int = 5  # TODO: for production, this should probably be 0 or 1
	end
	
	
	struct PLCRef{T}
		tag::Ref{Int32}
		count::Int
		
		function PLCRef{T}(plc::PLC, tagName::String, count::Int = 1) where {T}
			isprimitivetype(T) || error("Unable to create a PLCRef for anything other than primitive types")
			
			path = plcpath(plc, tagName, sizeof(T), count)
			
			tag = PLCTag.C.plc_tag_create(path, 1000)  # 1000 is create time-out
			tag <= 0 && error("Unable to create tag `$(tagName)` of type `$(T)` and count $(count): $(unsafe_string(PLCTag.C.plc_tag_decode_error(tag)))")
			
			result = new{T}(Ref{Int32}(tag), count)
			finalizer(t -> PLCTag.C.plc_tag_destroy(t[]), result.tag)
			return result
		end
	end
	
	
	Base.length(ref::PLCRef) = ref.count
	Base.size(ref::PLCRef) = (ref.count,)
	Base.eltype(ref::PLCRef{T}) where {T} = T
	Base.iterate(ref::PLCRef, state = 1) = state > length(ref) ? nothing : (ref[state], state+1)
	
	function Base.read(ref::PLCRef)
		code = PLCTag.C.plc_tag_read(ref.tag[], 0)
		code in (PLCTag.C.PLCTAG_STATUS_OK, PLCTag.C.PLCTAG_STATUS_PENDING) || error("Unable to read tag: $(unsafe_string(PLCTag.C.plc_tag_decode_error(code)))")
	end
	function Base.fetch(ref::PLCRef, ind::Int = 1)
		timedwait(() -> PLCTag.C.plc_tag_status(ref.tag[]) == PLCTag.C.PLCTAG_STATUS_OK, 1.0, pollint = 0.01) === :ok || error("Failed to complete tag read: $(unsafe_string(PLCTag.C.plc_tag_decode_error(PLCTag.C.plc_tag_status(ref.tag[]))))")
		return convert(eltype(ref), plcget(eltype(ref), ref.tag[], ind))
	end
	
	function Base.write(ref::PLCRef, val, ind::Int = 1)
		plcset(eltype(ref), ref.tag[], ind, convert(eltype(ref), val))
		code = PLCTag.C.plc_tag_write(ref.tag[], 0)
		code in (PLCTag.C.PLCTAG_STATUS_OK, PLCTag.C.PLCTAG_STATUS_PENDING) || error("Unable to write tag: $(unsafe_string(PLCTag.C.plc_tag_decode_error(code)))")
	end
	function Base.flush(ref::PLCRef)
		timedwait(() -> PLCTag.C.plc_tag_status(ref.tag[]) == PLCTag.C.PLCTAG_STATUS_OK, 1.0, pollint = 0.01) === :ok || error("Failed to complete tag write: $(unsafe_string(PLCTag.C.plc_tag_decode_error(PLCTag.C.plc_tag_status(ref.tag[]))))")
	end
	
	function Base.getindex(ref::PLCRef, ind::Int = 1)
		read(ref)
		return fetch(ref, ind)
	end
	
	function Base.setindex!(ref::PLCRef, val, ind::Int = 1)
		write(ref, val, ind)
		flush(ref)
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
	
	
	const PLCPrimitives = Union{
		Bool,
		Int8, UInt8, Int16, UInt16,
		Int32, UInt32, Int64, UInt64,
		Float32, Float64
	}
	
	for T in (
		:Bool,
		:Int8, :UInt8, :Int16, :UInt16,
		:Int32, :UInt32, :Int64, :UInt64,
		:Float32, :Float64,
	)
		if T === :Bool
			# NOTE: using Int8 (aka SINT on the PLC) to store a Bool
			@eval plcget(::Type{Bool}, tag::Int32, ind::Int)            = plcget(Int8, tag, ind) != 0
			@eval plcset(::Type{Bool}, tag::Int32, ind::Int, val::Bool) = plcset(Int8, tag, ind, convert(Int8, val))
		else
			@eval plcget(::Type{$(T)}, tag::Int32, ind::Int)            = PLCTag.C.$(Symbol("plc_tag_get_", lowercase(String(T))))(tag, ind-1)
			@eval plcset(::Type{$(T)}, tag::Int32, ind::Int, val::$(T)) = PLCTag.C.$(Symbol("plc_tag_set_", lowercase(String(T))))(tag, ind-1, val)
		end
		
		@eval Base.$(T)(plc::PLC, tagName::String) = PLCRef{$(T)}(plc, tagName)[]
	end
	
	function Base.Vector{T}(plc::PLC, tagName::String, count::Int) where {T<:PLCPrimitives}
		ref = PLCRef{T}(plc, tagName, count)
		return T[ref[i] for i in 1:length(ref)]
	end
	
	function Base.String(plc::PLC, tagName::String)
		len = PLCRef{Int32}(plc, "$(tagName).LEN")[]
		data = PLCRef{UInt8}(plc, "$(tagName).DATA", len)
		return String(data)
	end
end
