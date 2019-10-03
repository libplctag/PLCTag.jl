# PLCTag.jl
Wraps https://github.com/kyle-github/libplctag

# Install

You must have build-essentials and cmake installed.

In Pkg mode, `add https://github.com/laurium-labs/PLCTag.jl`

# Usage

```julia
using PLCTag

const TAG_PATH = "protocol=ab_eip&gateway=192.168.2.1&path=1,0&cpu=compactlogix&elem_size=4&elem_count=1&name=topTerm&debug=3"
const DATA_TIMEOUT = 5000

tag = PLCTag.C.plc_tag_create(TAG_PATH, DATA_TIMEOUT)
tag <= 0 && error("ERROR $(PLCTag.C.plc_tag_decode_error(tag)): Could not create tag!")

code = PLCTag.C.plc_tag_status(tag)
        
code == PLCTag.C.PLCTAG_STATUS_OK || error("ERROR: Error setting up tag internal state. Got error code $(code): $(unsafe_string(PLCTag.C.plc_tag_decode_error(code)))")

# read
code = PLCTag.C.plc_tag_read(tag, DATA_TIMEOUT)
code == PLCTag.C.PLCTAG_STATUS_OK || error("ERROR: Unable to read the data! Got error code $(code): $(unsafe_string(PLCTag.C.plc_tag_decode_error(code)))")
val = PLCTag.C.plc_tag_get_int32(tag, 0)
@info "data= $(val)"

# write
code = PLCTag.C.plc_tag_set_int32(tag, 0, 1)
code == PLCTag.C.PLCTAG_STATUS_OK || error("ERROR: Unable to write the data! Got error code $(code): $(unsafe_string(PLCTag.C.plc_tag_decode_error(code)))")


code = PLCTag.C.plc_tag_write(tag, DATA_TIMEOUT)        
code == PLCTag.C.PLCTAG_STATUS_OK || error("ERROR: Unable to write the data! Got error code $(code): $(unsafe_string(PLCTag.C.plc_tag_decode_error(code)))")


```
