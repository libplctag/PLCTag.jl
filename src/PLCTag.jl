module PLCTag
	module C
		using CBinding
		
		const PLCTAG_STATUS_PENDING       = 1
		const PLCTAG_STATUS_OK            = 0
		const PLCTAG_ERR_ABORT            = -1
		const PLCTAG_ERR_BAD_CONFIG       = -2
		const PLCTAG_ERR_BAD_CONNECTION   = -3
		const PLCTAG_ERR_BAD_DATA         = -4
		const PLCTAG_ERR_BAD_DEVICE       = -5
		const PLCTAG_ERR_BAD_GATEWAY      = -6
		const PLCTAG_ERR_BAD_PARAM        = -7
		const PLCTAG_ERR_BAD_REPLY        = -8
		const PLCTAG_ERR_BAD_STATUS       = -9
		const PLCTAG_ERR_CLOSE            = -10
		const PLCTAG_ERR_CREATE           = -11
		const PLCTAG_ERR_DUPLICATE        = -12
		const PLCTAG_ERR_ENCODE           = -13
		const PLCTAG_ERR_MUTEX_DESTROY    = -14
		const PLCTAG_ERR_MUTEX_INIT       = -15
		const PLCTAG_ERR_MUTEX_LOCK       = -16
		const PLCTAG_ERR_MUTEX_UNLOCK     = -17
		const PLCTAG_ERR_NOT_ALLOWED      = -18
		const PLCTAG_ERR_NOT_FOUND        = -19
		const PLCTAG_ERR_NOT_IMPLEMENTED  = -20
		const PLCTAG_ERR_NO_DATA          = -21
		const PLCTAG_ERR_NO_MATCH         = -22
		const PLCTAG_ERR_NO_MEM           = -23
		const PLCTAG_ERR_NO_RESOURCES     = -24
		const PLCTAG_ERR_NULL_PTR         = -25
		const PLCTAG_ERR_OPEN             = -26
		const PLCTAG_ERR_OUT_OF_BOUNDS    = -27
		const PLCTAG_ERR_READ             = -28
		const PLCTAG_ERR_REMOTE_ERR       = -29
		const PLCTAG_ERR_THREAD_CREATE    = -30
		const PLCTAG_ERR_THREAD_JOIN      = -31
		const PLCTAG_ERR_TIMEOUT          = -32
		const PLCTAG_ERR_TOO_LARGE        = -33
		const PLCTAG_ERR_TOO_SMALL        = -34
		const PLCTAG_ERR_UNSUPPORTED      = -35
		const PLCTAG_ERR_WINSOCK          = -36
		const PLCTAG_ERR_WRITE            = -37
		const PLCTAG_ERR_PARTIAL          = -38
		
		function __init__()
			library = Clibrary(joinpath(dirname(@__DIR__), "deps/usr/lib/libplctag.so"))
			
			global plc_tag_decode_error = Cfunction{Cstring, Tuple{Cint}}(library, :plc_tag_decode_error)
			global plc_tag_create = Cfunction{Int32, Tuple{Cstring, Cint}}(library, :plc_tag_create)
			global plc_tag_lock = Cfunction{Cint, Tuple{Int32}}(library, :plc_tag_lock)
			global plc_tag_unlock = Cfunction{Cint, Tuple{Int32}}(library, :plc_tag_unlock)
			global plc_tag_abort = Cfunction{Cint, Tuple{Int32}}(library, :plc_tag_abort)
			global plc_tag_destroy = Cfunction{Cint, Tuple{Int32}}(library, :plc_tag_destroy)
			global plc_tag_read = Cfunction{Cint, Tuple{Int32, Cint}}(library, :plc_tag_read)
			global plc_tag_status = Cfunction{Cint, Tuple{Int32}}(library, :plc_tag_status)
			global plc_tag_write = Cfunction{Cint, Tuple{Int32, Cint}}(library, :plc_tag_write)
			global plc_tag_get_size = Cfunction{Cint, Tuple{Int32}}(library, :plc_tag_get_size)
			global plc_tag_get_uint64 = Cfunction{UInt64, Tuple{Int32, Cint}}(library, :plc_tag_get_uint64)
			global plc_tag_set_uint64 = Cfunction{Cint, Tuple{Int32, Cint, UInt64}}(library, :plc_tag_set_uint64)
			global plc_tag_get_int64 = Cfunction{Int64, Tuple{Int32, Cint}}(library, :plc_tag_get_int64)
			global plc_tag_set_int64 = Cfunction{Cint, Tuple{Int32, Cint, Int64}}(library, :plc_tag_set_int64)
			global plc_tag_get_uint32 = Cfunction{UInt32, Tuple{Int32, Cint}}(library, :plc_tag_get_uint32)
			global plc_tag_set_uint32 = Cfunction{Cint, Tuple{Int32, Cint, UInt32}}(library, :plc_tag_set_uint32)
			global plc_tag_get_int32 = Cfunction{Int32, Tuple{Int32, Cint}}(library, :plc_tag_get_int32)
			global plc_tag_set_int32 = Cfunction{Cint, Tuple{Int32, Cint, Int32}}(library, :plc_tag_set_int32)
			global plc_tag_get_uint16 = Cfunction{UInt16, Tuple{Int32, Cint}}(library, :plc_tag_get_uint16)
			global plc_tag_set_uint16 = Cfunction{Cint, Tuple{Int32, Cint, UInt16}}(library, :plc_tag_set_uint16)
			global plc_tag_get_int16 = Cfunction{Int16, Tuple{Int32, Cint}}(library, :plc_tag_get_int16)
			global plc_tag_set_int16 = Cfunction{Cint, Tuple{Int32, Cint, Int16}}(library, :plc_tag_set_int16)
			global plc_tag_get_uint8 = Cfunction{UInt8, Tuple{Int32, Cint}}(library, :plc_tag_get_uint8)
			global plc_tag_set_uint8 = Cfunction{Cint, Tuple{Int32, Cint, UInt8}}(library, :plc_tag_set_uint8)
			global plc_tag_get_int8 = Cfunction{Int8, Tuple{Int32, Cint}}(library, :plc_tag_get_int8)
			global plc_tag_set_int8 = Cfunction{Cint, Tuple{Int32, Cint, Int8}}(library, :plc_tag_set_int8)
			global plc_tag_get_float64 = Cfunction{Cdouble, Tuple{Int32, Cint}}(library, :plc_tag_get_float64)
			global plc_tag_set_float64 = Cfunction{Cint, Tuple{Int32, Cint, Cdouble}}(library, :plc_tag_set_float64)
			global plc_tag_get_float32 = Cfunction{Cfloat, Tuple{Int32, Cint}}(library, :plc_tag_get_float32)
			global plc_tag_set_float32 = Cfunction{Cint, Tuple{Int32, Cint, Cfloat}}(library, :plc_tag_set_float32)
		end
	end
end
