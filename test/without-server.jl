
@testset "PLCTag" begin
	@test unsafe_string(LibPLCTag.plc_tag_decode_error(LibPLCTag.PLCTAG_STATUS_OK)) == "PLCTAG_STATUS_OK"
end
