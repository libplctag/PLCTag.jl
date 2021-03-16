
@testset "PLCTag" begin
	@test unsafe_string(plc_tag_decode_error(c"PLCTAG_STATUS_OK")) == "PLCTAG_STATUS_OK"
end
