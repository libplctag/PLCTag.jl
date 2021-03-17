# PLCTag.jl

[![Build Status](https://github.com/libplctag/PLCTag.jl/workflows/CI/badge.svg)](https://github.com/libplctag/PLCTag.jl/actions)

Julia wrapper for [libplctag](https://github.com/libplctag/libplctag) to communicate with PLC's.


## Install

PLCTag.jl downloads and builds libplctag from a released tar file.
You must have build-essentials installed or analogous build support packages for your OS.
If you wish to override the version downloaded and built, an environment variable is the means to do that:

1. in Julia: `ENV["LIBPLCTAG_VERSION"] = "2.1.8"`
2. or Bash: `export LIBPLCTAG_VERSION='2.1.8'`

The environment variable must be set before installing (`add PLCTag`) or building (`build PLCTag`) with the package manager.


## Usage

The libplctag C bindings that are generated with [CBinding.jl](https://github.com/analytech-solutions/CBinding.jl) are exported in the `libplctag` module.
Additional high-level facilities are provided by PLCTag.jl for a more Julian experience.


### Low-Level Usage

The following example uses the C bindings to read and write a 32-bit integer tag called `some_tag`.

```julia
using CBinding
using PLCTag
using PLCTag.libplctag

const TAG_PATH = "protocol=ab-eip&gateway=192.168.2.1&path=1,0&cpu=compactlogix&elem_size=4&elem_count=1&name=some_tag&debug=3"
const DATA_TIMEOUT = 5000

tag = plc_tag_create(TAG_PATH, DATA_TIMEOUT)
tag <= 0 && error("$(plc_tag_decode_error(tag)): Could not create tag!")

code = plc_tag_status(tag)
code == c"PLCTAG_STATUS_OK" || error("Error setting up tag internal state. Got error code $(code): $(unsafe_string(plc_tag_decode_error(code)))")

# read
code = plc_tag_read(tag, DATA_TIMEOUT)
code == c"PLCTAG_STATUS_OK" || error("Unable to read the data! Got error code $(code): $(unsafe_string(plc_tag_decode_error(code)))")
val = plc_tag_get_int32(tag, 0)
@info val

# write
code = plc_tag_set_int32(tag, 0, 42)
code == c"PLCTAG_STATUS_OK" || error("Unable to write the data! Got error code $(code): $(unsafe_string(plc_tag_decode_error(code)))")

code = plc_tag_write(tag, DATA_TIMEOUT)
code == c"PLCTAG_STATUS_OK" || error("Unable to write the data! Got error code $(code): $(unsafe_string(plc_tag_decode_error(code)))")

plc_tag_destroy(tag)
```


### High-Level Usage

The high-level interface is much more pleasant to work with, and the example below is the equivalent to the low-level example above.

```julia
using PLCTag

const plc = PLC(
	protocol = "ab-eip",
	gateway  = "192.168.2.1",
	path     = "1,0",
	cpu      = "compactlogix",
	debug    = 0,
)
const DATA_TIMEOUT = 5000


tag = PLCRef{Int32}(plc, "some_tag"; timeout = DATA_TIMEOUT)

# read & fetch
read(tag)
@info fetch(tag)
# or
@info tag[]

# write & flush
write(tag, 42)
flush(tag)
# or
tag[] = 42

# just for demonstration purposes, a tag's resources get cleaned
# up when it's no longer referenced and garbage collection occurs
tag = nothing
GC.gc()
```
