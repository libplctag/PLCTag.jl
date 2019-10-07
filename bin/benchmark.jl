using PLCTag

const ITERATIONS      = 100
const DATA_TIMEOUT    = 5000

function createIndividualTags(fields::Int, instances::Int)
	return vcat([string("protocol=ab_eip&gateway=192.168.1.1&path=1,0&cpu=compactlogix&elem_size=4&elem_count=1&name=field_", string(f-1), "_", string(i-1), string("&debug=1")) for f in 1:fields, i in 1:instances]...)
end

function createArrayedTags(fields::Int, instances::Int)
	vcat([string("protocol=ab_eip&gateway=192.168.1.1&path=1,0&cpu=compactlogix&elem_size=4&elem_count=", string(instances), "&name=field_", string(f-1), "&debug=1") for f in 1:fields]...)
end

struct NamedTag
	name::AbstractString
	tag::Int32
end

function create(paths::Vector{String})
	tags = NamedTag[]
	for path in paths
		tag = PLCTag.C.plc_tag_create(path, 5000)
		tag <= 0 && error("ERROR $(PLCTag.C.plc_tag_decode_error(tag)): Could not create tag!")
		code = PLCTag.C.plc_tag_status(tag)
		code == PLCTag.C.PLCTAG_STATUS_OK || error("ERROR: Error setting up tag internal state. Got error code $(code): $(unsafe_string(PLCTag.C.plc_tag_decode_error(code)))")
		push!(tags, NamedTag(path, tag))
	end
	return tags
end


function destroy(tags::Vector{NamedTag})
	for tag in map(v -> v.tag, tags)
		code = PLCTag.C.plc_tag_destroy(tag)
		code == PLCTag.C.PLCTAG_STATUS_OK || error("Failed to destroy tag")
	end
end


function readIndividualTagsSync(tags::Vector{NamedTag})
	for named_tag in tags
		tag = named_tag.tag
		code = PLCTag.C.plc_tag_read(tag, DATA_TIMEOUT)
		code == PLCTag.C.PLCTAG_STATUS_OK || error("ERROR: Unable to read the data! Got error code $(code): $(unsafe_string(PLCTag.C.plc_tag_decode_error(code)))")
	end
	
	for named_tag in tags
		tag = named_tag.tag
		val = PLCTag.C.plc_tag_get_int32(tag, 0)
	end
end


function readIndividualTagsAsync(tags::Vector{NamedTag})
	for named_tag in tags
		tag = named_tag.tag
		code = PLCTag.C.plc_tag_read(tag, 0)
		code in (PLCTag.C.PLCTAG_STATUS_OK, PLCTag.C.PLCTAG_STATUS_PENDING) || error("ERROR: Unable to read the data! Got error code $(code): $(unsafe_string(PLCTag.C.plc_tag_decode_error(code)))")
	end
	
	for named_tag in tags
		tag = named_tag.tag
		while PLCTag.C.plc_tag_status(tag) == PLCTag.C.PLCTAG_STATUS_PENDING
			sleep(0.001)
		end
		PLCTag.C.plc_tag_status(tag) == PLCTag.C.PLCTAG_STATUS_OK || error("Failed to read tag: $(named_tag.name)")
		
		val = PLCTag.C.plc_tag_get_int32(tag, 0)
	end
end


function readArrayedTagsSync(tags::Vector{NamedTag}, instances::Int)
	for tag in tags
		tag = named_tag.tag
		code = PLCTag.C.plc_tag_read(tag, DATA_TIMEOUT)
		code == PLCTag.C.PLCTAG_STATUS_OK || error("ERROR: Unable to read the data! Got error code $(code): $(unsafe_string(PLCTag.C.plc_tag_decode_error(code)))")
	end
	
	for tag in tags
		tag = named_tag.tag
		for instance in 1:instances
			val = PLCTag.C.plc_tag_get_int32(tag, instance-1)
		end
	end
end


function readArrayedTagsAsync(tags::Vector{NamedTag}, instances::Int)
	for named_tag in tags
		tag = named_tag.tag
		code = PLCTag.C.plc_tag_read(tag, 0)
		code in (PLCTag.C.PLCTAG_STATUS_OK, PLCTag.C.PLCTAG_STATUS_PENDING) || error("ERROR: Unable to read the data! Got error code $(code): $(unsafe_string(PLCTag.C.plc_tag_decode_error(code)))")
	end
	
	for named_tag in tags
		tag = named_tag.tag
		while PLCTag.C.plc_tag_status(tag) == PLCTag.C.PLCTAG_STATUS_PENDING
			sleep(0.001)
		end
		PLCTag.C.plc_tag_status(tag) == PLCTag.C.PLCTAG_STATUS_OK || error("Failed to read tag")
		
		for instance in 1:instances
			val = PLCTag.C.plc_tag_get_int32(tag, instance-1)
		end
	end
end


function timeOne(paths::Vector{String}, f::Function)
	function g(tags::Vector{NamedTag})
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


function timeAll(;fields::Int=5, instances::Int=10)
	@info "Running tests with fields=$(fields) and instances=$(instances) and iterations=$(ITERATIONS)"
	# @info "synchronously reading individual tags"
	# timeOne(createIndividualTags(fields, instances), readIndividualTagsSync)
	@info "asynchronously reading individual tags"
	timeOne(createIndividualTags(fields, instances), readIndividualTagsAsync)
	# @info "synchronously reading arrayed tags"
	# timeOne(createArrayedTags(fields, instances), (tags) -> readArrayedTagsSync(tags, instances))
	# @info "asynchronously reading arrayed tags"
	# timeOne(createArrayedTags(fields, instances), (tags) -> readArrayedTagsAsync(tags, instances))
end
