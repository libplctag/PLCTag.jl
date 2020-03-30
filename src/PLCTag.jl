module PLCTag
	baremodule LibPLCTag
		using CBinding: @macros
		@macros
		
		const int8_t  = @CBinding().Int8
		const int16_t = @CBinding().Int16
		const int32_t = @CBinding().Int32
		const int64_t = @CBinding().Int64
		const uint8_t  = @CBinding().UInt8
		const uint16_t = @CBinding().UInt16
		const uint32_t = @CBinding().UInt32
		const uint64_t = @CBinding().UInt64
		
		const PLCTAG_STATUS_PENDING      = (1)
		const PLCTAG_STATUS_OK           = (0)
		const PLCTAG_ERR_ABORT           = (-1)
		const PLCTAG_ERR_BAD_CONFIG      = (-2)
		const PLCTAG_ERR_BAD_CONNECTION  = (-3)
		const PLCTAG_ERR_BAD_DATA        = (-4)
		const PLCTAG_ERR_BAD_DEVICE      = (-5)
		const PLCTAG_ERR_BAD_GATEWAY     = (-6)
		const PLCTAG_ERR_BAD_PARAM       = (-7)
		const PLCTAG_ERR_BAD_REPLY       = (-8)
		const PLCTAG_ERR_BAD_STATUS      = (-9)
		const PLCTAG_ERR_CLOSE           = (-10)
		const PLCTAG_ERR_CREATE          = (-11)
		const PLCTAG_ERR_DUPLICATE       = (-12)
		const PLCTAG_ERR_ENCODE          = (-13)
		const PLCTAG_ERR_MUTEX_DESTROY   = (-14)
		const PLCTAG_ERR_MUTEX_INIT      = (-15)
		const PLCTAG_ERR_MUTEX_LOCK      = (-16)
		const PLCTAG_ERR_MUTEX_UNLOCK    = (-17)
		const PLCTAG_ERR_NOT_ALLOWED     = (-18)
		const PLCTAG_ERR_NOT_FOUND       = (-19)
		const PLCTAG_ERR_NOT_IMPLEMENTED = (-20)
		const PLCTAG_ERR_NO_DATA         = (-21)
		const PLCTAG_ERR_NO_MATCH        = (-22)
		const PLCTAG_ERR_NO_MEM          = (-23)
		const PLCTAG_ERR_NO_RESOURCES    = (-24)
		const PLCTAG_ERR_NULL_PTR        = (-25)
		const PLCTAG_ERR_OPEN            = (-26)
		const PLCTAG_ERR_OUT_OF_BOUNDS   = (-27)
		const PLCTAG_ERR_READ            = (-28)
		const PLCTAG_ERR_REMOTE_ERR      = (-29)
		const PLCTAG_ERR_THREAD_CREATE   = (-30)
		const PLCTAG_ERR_THREAD_JOIN     = (-31)
		const PLCTAG_ERR_TIMEOUT         = (-32)
		const PLCTAG_ERR_TOO_LARGE       = (-33)
		const PLCTAG_ERR_TOO_SMALL       = (-34)
		const PLCTAG_ERR_UNSUPPORTED     = (-35)
		const PLCTAG_ERR_WINSOCK         = (-36)
		const PLCTAG_ERR_WRITE           = (-37)
		const PLCTAG_ERR_PARTIAL         = (-38)
		const PLCTAG_ERR_BUSY            = (-39)
		
		@include(@CBinding().joinpath(@CBinding().dirname(@CBinding().@__DIR__), "deps", "libplctag.jl"))
	end
	
	
	export LibPLCTag, PLC, PLCRef, PLCBinding
	
	
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
			
			tag = PLCTag.LibPLCTag.plc_tag_create(path, timeout)
			tag <= 0 && error("Unable to create tag `$(tagName)` of type `$(T)` and count $(count): $(unsafe_string(PLCTag.LibPLCTag.plc_tag_decode_error(tag)))")
			
			result = new{T}(Ref{Int32}(tag), count)
			finalizer(t -> PLCTag.LibPLCTag.plc_tag_destroy(t[]), result.tag)
			return result
		end
	end
	
	
	Base.length(ref::PLCRef) = ref.count
	Base.size(ref::PLCRef) = (ref.count,)
	Base.eltype(ref::PLCRef{T}) where {T} = T
	Base.iterate(ref::PLCRef, state = 1) = state > length(ref) ? nothing : (ref[state], state+1)
	
	function Base.read(ref::PLCRef)
		code = PLCTag.LibPLCTag.plc_tag_read(ref.tag[], 0)
		code in (PLCTag.LibPLCTag.PLCTAG_STATUS_OK, PLCTag.LibPLCTag.PLCTAG_STATUS_PENDING) || error("Unable to read tag: $(unsafe_string(PLCTag.LibPLCTag.plc_tag_decode_error(code)))")
	end
	function Base.fetch(ref::PLCRef, ind::Int = 1)
		timedwait(() -> PLCTag.LibPLCTag.plc_tag_status(ref.tag[]) == PLCTag.LibPLCTag.PLCTAG_STATUS_OK, 1.0, pollint = 0.001) === :ok || error("Failed to complete tag read: $(unsafe_string(PLCTag.LibPLCTag.plc_tag_decode_error(PLCTag.LibPLCTag.plc_tag_status(ref.tag[]))))")
		return convert(eltype(ref), plcget(eltype(ref), ref.tag[], ind))
	end
	
	function Base.write(ref::PLCRef, val, ind::Int = 1)
		plcset(eltype(ref), ref.tag[], ind, convert(eltype(ref), val))
		code = PLCTag.LibPLCTag.plc_tag_write(ref.tag[], 0)
		code in (PLCTag.LibPLCTag.PLCTAG_STATUS_OK, PLCTag.LibPLCTag.PLCTAG_STATUS_PENDING) || error("Unable to write tag: $(unsafe_string(PLCTag.LibPLCTag.plc_tag_decode_error(code)))")
	end
	function Base.flush(ref::PLCRef)
		timedwait(() -> PLCTag.LibPLCTag.plc_tag_status(ref.tag[]) == PLCTag.LibPLCTag.PLCTAG_STATUS_OK, 1.0, pollint = 0.001) === :ok || error("Failed to complete tag write: $(unsafe_string(PLCTag.LibPLCTag.plc_tag_decode_error(PLCTag.LibPLCTag.plc_tag_status(ref.tag[]))))")
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
			@eval plcget(::Type{$(T)}, tag::Int32, ind::Int)            = PLCTag.LibPLCTag.$(Symbol("plc_tag_get_", lowercase(String(T))))(tag, ind-1)
			@eval plcset(::Type{$(T)}, tag::Int32, ind::Int, val::$(T)) = PLCTag.LibPLCTag.$(Symbol("plc_tag_set_", lowercase(String(T))))(tag, ind-1, val)
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
