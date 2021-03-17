module PLCTag
	module libplctag
		using CBinding
		
		let
			incdir = joinpath(dirname(@__DIR__), "deps/usr/include")
			libdir = joinpath(dirname(@__DIR__), "deps/usr/lib")
			
			c`-I$(incdir) -fparse-all-comments -L$(libdir) -lplctag`
		end
		
		const c"int8_t"  = Int8
		const c"int16_t" = Int16
		const c"int32_t" = Int32
		const c"int64_t" = Int64
		const c"uint8_t"  = UInt8
		const c"uint16_t" = UInt16
		const c"uint32_t" = UInt32
		const c"uint64_t" = UInt64
		
		c"""
			#include <libplctag.h>
		"""ji
	end
	
	
	using CBinding
	using .libplctag
	
	export PLC, PLCRef, PLCBinding
	
	
	Base.@kwdef struct PLC
		cpu::String
		protocol::String
		gateway::String
		path::String
		debug::Int = 1
	end
	
	
	struct PLCRef{T}
		tag::Ref{Int32}
		count::Int
		
		function PLCRef{T}(plc::PLC, tagName::String, count::Int = 1; timeout::Int = 1000) where {T}
			isprimitivetype(T) || error("Unable to create a PLCRef for anything other than primitive types")
			
			path = plcpath(plc, tagName, sizeof(T), count)
			
			tag = plc_tag_create(path, timeout)
			tag <= 0 && error("Unable to create tag `$(tagName)` of type `$(T)` and count $(count): $(unsafe_string(plc_tag_decode_error(tag)))")
			
			result = new{T}(Ref{Int32}(tag), count)
			finalizer(t -> plc_tag_destroy(t[]), result.tag)
			return result
		end
	end
	
	
	Base.length(ref::PLCRef) = ref.count
	Base.size(ref::PLCRef) = (ref.count,)
	Base.eltype(ref::PLCRef{T}) where {T} = T
	Base.iterate(ref::PLCRef, state = 1) = state > length(ref) ? nothing : (ref[state], state+1)
	
	function Base.read(ref::PLCRef)
		code = plc_tag_read(ref.tag[], 0)
		code in (c"PLCTAG_STATUS_OK", c"PLCTAG_STATUS_PENDING") || error("Unable to read tag: $(unsafe_string(plc_tag_decode_error(code)))")
	end
	function Base.fetch(ref::PLCRef, ind::Int = 1)
		timedwait(() -> plc_tag_status(ref.tag[]) == c"PLCTAG_STATUS_OK", 1.0, pollint = 0.001) === :ok || error("Failed to complete tag read: $(unsafe_string(plc_tag_decode_error(plc_tag_status(ref.tag[]))))")
		return convert(eltype(ref), plcget(eltype(ref), ref.tag[], ind))
	end
	
	function Base.write(ref::PLCRef, val, ind::Int = 1)
		plcset(eltype(ref), ref.tag[], ind, convert(eltype(ref), val))
		code = plc_tag_write(ref.tag[], 0)
		code in (c"PLCTAG_STATUS_OK", c"PLCTAG_STATUS_PENDING") || error("Unable to write tag: $(unsafe_string(plc_tag_decode_error(code)))")
	end
	function Base.flush(ref::PLCRef)
		timedwait(() -> plc_tag_status(ref.tag[]) == c"PLCTAG_STATUS_OK", 1.0, pollint = 0.001) === :ok || error("Failed to complete tag write: $(unsafe_string(plc_tag_decode_error(plc_tag_status(ref.tag[]))))")
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
			@eval plcget(::Type{$(T)}, tag::Int32, ind::Int)            = $(Symbol("plc_tag_get_", lowercase(String(T))))(tag, ind-1)
			@eval plcset(::Type{$(T)}, tag::Int32, ind::Int, val::$(T)) = $(Symbol("plc_tag_set_", lowercase(String(T))))(tag, ind-1, val)
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
