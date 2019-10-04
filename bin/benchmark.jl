using PLCTag


const FIELDS          = 5
const INSTANCES       = 10
const ITERATIONS      = 100
const DATA_TIMEOUT    = 5000
const INDIVIDUAL_TAGS = ["protocol=ab_eip&gateway=192.168.1.1&path=1,0&cpu=compactlogix&elem_size=4&elem_count=1&name=field_${f-1}_${i-1}&debug=1" for f in 1:FIELDS, i in 1:INSTANCES]
const ARRAYED_TAGS    = ["protocol=ab_eip&gateway=192.168.1.1&path=1,0&cpu=compactlogix&elem_size=4&elem_count=${INSTANCES}&name=field_${f-1}&debug=1" for f in 1:FIELDS]


function create(paths::Vector{String})
	tags = Int32[]
	for path in paths
		tag = PLCTag.C.plc_tag_create(TAG_PATH, DATA_TIMEOUT)
		tag <= 0 && error("ERROR $(PLCTag.C.plc_tag_decode_error(tag)): Could not create tag!")
		code = PLCTag.C.plc_tag_status(tag)
		code == PLCTag.C.PLCTAG_STATUS_OK || error("ERROR: Error setting up tag internal state. Got error code $(code): $(unsafe_string(PLCTag.C.plc_tag_decode_error(code)))")
		push!(tags, tag)
	end
	return tags
end


function destroy(tags::Vector{Int32})
	for tag in tags
		code = PLCTag.C.plc_tag_destroy(tag)
		code == PLCTag.C.PLCTAG_STATUS_OK || error("Failed to destroy tag")
	end
end


function readIndividualTagsSync(tags::Vector{Int32})
	for tag in tags
		code = PLCTag.C.plc_tag_read(tag, DATA_TIMEOUT)
		code == PLCTag.C.PLCTAG_STATUS_OK || error("ERROR: Unable to read the data! Got error code $(code): $(unsafe_string(PLCTag.C.plc_tag_decode_error(code)))")
	end
	
	for tag in tags
		val = PLCTag.C.plc_get_int32(tag, 0)
	end
end


function readIndividualTagsAsync(tags::Vector{Int32})
	for tag in tags
		code = PLCTag.C.plc_tag_read(tag, 0)
		code in (PLCTag.C.PLCTAG_STATUS_OK, PLCTag.C.PLCTAG_STATUS_PENDING) || error("ERROR: Unable to read the data! Got error code $(code): $(unsafe_string(PLCTag.C.plc_tag_decode_error(code)))")
	end
	
	for tag in tags
		while PLCTag.C.plc_tag_status(tag) == PLCTag.C.PLCTAG_STATUS_PENDING
			sleep(0.001)
		end
		PLCTag.C.plc_tag_status(tag) == PLCTag.C.PLCTAG_STATUS_OK || error("Failed to read tag")
		
		val = PLCTag.C.plc_get_int32(tag, 0)
	end
end


function readArrayedTagsSync(tags::Vector{Int32})
	for tag in tags
		code = PLCTag.C.plc_tag_read(tag, DATA_TIMEOUT)
		code == PLCTag.C.PLCTAG_STATUS_OK || error("ERROR: Unable to read the data! Got error code $(code): $(unsafe_string(PLCTag.C.plc_tag_decode_error(code)))")
	end
	
	for tag in tags
		for instance in 1:INSTANCES
			val = PLCTag.C.plc_get_int32(tag, instance-1)
		end
	end
end


function readArrayedTagsAsync(tags::Vector{Int32})
	for tag in tags
		code = PLCTag.C.plc_tag_read(tag, 0)
		code in (PLCTag.C.PLCTAG_STATUS_OK, PLCTag.C.PLCTAG_STATUS_PENDING) || error("ERROR: Unable to read the data! Got error code $(code): $(unsafe_string(PLCTag.C.plc_tag_decode_error(code)))")
	end
	
	for tag in tags
		while PLCTag.C.plc_tag_status(tag) == PLCTag.C.PLCTAG_STATUS_PENDING
			sleep(0.001)
		end
		PLCTag.C.plc_tag_status(tag) == PLCTag.C.PLCTAG_STATUS_OK || error("Failed to read tag")
		
		for instance in 1:INSTANCES
			val = PLCTag.C.plc_get_int32(tag, instance-1)
		end
	end
end


function timeOne(paths::Vector{String}, f::Function)
	function g(tags::Vector{Int32})
		for _ in 1:ITERATIONS
			f(tags)
		end
	end
	
	tags = create(paths)
	try
		g(tags)
		@time g(tags)
	finally
		destroy(tags)
	end
end


function timeAll()
	@info "synchronously reading individual tags"
	timeOne(INDIVIDUAL_TAGS, readIndividualTagsSync)
	@info "asynchronously reading individual tags"
	timeOne(INDIVIDUAL_TAGS, readIndividualTagsAsync)
	@info "synchronously reading arrayed tags"
	timeOne(ARRAYED_TAGS, readArrayedTagsSync)
	@info "asynchronously reading arrayed tags"
	timeOne(ARRAYED_TAGS, readArrayedTagsAsync)
end

