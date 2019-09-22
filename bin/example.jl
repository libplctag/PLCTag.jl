using PLCTag


const TAG_PATH     = "protocol=ab-eip&gateway=127.0.0.1&path=1,5&cpu=micro800&elem_size=4&elem_count=200&name=TestBigArray&debug=4"
const ELEM_COUNT   = 200
const ELEM_SIZE    = 4
const DATA_TIMEOUT = 5000


function main()
	tag = PLCTag.C.plc_tag_create(TAG_PATH, DATA_TIMEOUT)
	tag <= 0 && error("ERROR $(PLCTag.C.plc_tag_decode_error(tag)): Could not create tag!")
	
	try
		# code = PLCTag.C.plc_tag_lock(tag)
		# code == PLCTag.C.PLCTAG_STATUS_OK || error("ERROR: Unable to obtain tag lock! Got error code $(code): $(unsafe_string(PLCTag.C.plc_tag_decode_error(code)))")
		
		code = PLCTag.C.plc_tag_status(tag)
		code == PLCTag.C.PLCTAG_STATUS_OK || error("ERROR: Error setting up tag internal state. Got error code $(code): $(unsafe_string(PLCTag.C.plc_tag_decode_error(code)))")
		
		# read values
		code = PLCTag.C.plc_tag_read(tag, DATA_TIMEOUT)
		code == PLCTag.C.PLCTAG_STATUS_OK || error("ERROR: Unable to read the data! Got error code $(code): $(unsafe_string(PLCTag.C.plc_tag_decode_error(code)))")
		
		for i in 1:ELEM_COUNT
			val = PLCTag.C.plc_tag_get_int32(tag, (i-1)*ELEM_SIZE)
			@info "data[$(i)] = $(val)"
		end
		
		# set new values
		for i in 1:ELEM_COUNT
			val = PLCTag.C.plc_tag_get_int32(tag, (i-1)*ELEM_SIZE)
			val = val+1
			PLCTag.C.plc_tag_set_int32(tag, (i-1)*ELEM_SIZE, val)
		end
		
		code = PLCTag.C.plc_tag_write(tag, DATA_TIMEOUT)
		code == PLCTag.C.PLCTAG_STATUS_OK || error("ERROR: Unable to write the data! Got error code $(code): $(unsafe_string(PLCTag.C.plc_tag_decode_error(code)))")
		
		# read values again
		code = PLCTag.C.plc_tag_read(tag, DATA_TIMEOUT)
		code == PLCTag.C.PLCTAG_STATUS_OK || error("ERROR: Unable to read the data! Got error code $(code): $(unsafe_string(PLCTag.C.plc_tag_decode_error(code)))")
		
		for i in 1:ELEM_COUNT
			val = PLCTag.C.plc_tag_get_int32(tag, (i-1)*ELEM_SIZE)
			@info "data[$(i)] = $(val)"
		end
		
		# PLCTag.C.plc_tag_unlock(tag)
	finally
		PLCTag.C.plc_tag_destroy(tag)
	end
end

main()
