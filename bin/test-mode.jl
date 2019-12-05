using PLCTag
using Sockets
using JSON


struct Conveyor
	STOP::Int8
	TIMER::Int32
	DIRECTION::Int8
end

struct Return
	ERROR::Int32
end


function main()
	plc = PLC(
		cpu = "compactlogix",
		protocol = "ab-eip",
		gateway = "192.168.1.1",
		path = "1,0",
		debug = 1,
	)
	
	conveyors = [
		"IN1_CONV1_MTR1",
	]
	bindings = Dict{String, PLCBinding}(map(conv -> conv => PLCBinding(plc, conv, Conveyor, Return), conveyors)...)
	
	serve = listen(8888)
	@info "listening..."
	while true
		sock = accept(serve)
		@info "connected"
		try
			while !eof(sock)
				stat = "unknown error"
				try
					stat = "read failure"
					req = readline(sock)
					
					stat = "parsing failure"
					req = JSON.parse(req)
					
					stat = "bad id"
					id = String(req["id"])
					binding = bindings[id]
					
					stat = "bad direction"
					dir = lowercase(String(req["direction"])) == "forward" ? 1 : 0
					
					stat = "bad duration"
					dur = round(Int32, req["duration"]*1000)
					
					stat = "failed to call plc"
					@info "@time binding($(dur), $(dir))"
					ret = @time binding(Conveyor(0, dur, dir))
					
					stat = "plc command failed"
					ret.ERROR == 0 || error("Errors have occurred")
					
					stat = "ok"
				finally
					println(sock, """{"status": $(repr(stat))}""")
				end
			end
		finally
			close(sock)
		end
	end
end





