using PLCTag


struct Conveyor
	timer::Int32
	direction::Int8
end

struct Return
	error::Int32
end

# struct Mover
# 	conv1::Conveyor
# 	conv2::Conveyor
# 	f::Float32
# end


function main()
	plc = PLC(
		cpu = "compactlogix",
		protocol = "ab-eip",
		gateway = "192.168.1.1",
		path = "1,0",
	)
	
	testStruct = PLCBinding(plc, "test_struct", Conveyor, Return)
	ret = testStruct(Conveyor(10, 1))
	ret.error == 0 || error("Errors have occurred")
	
	
	# mover1 = PLCBinding(plc, "mover1", Mover, Return)
	# conv1  = PLCBinding(plc, "conv1", Conveyor, Return)
	# conv2  = PLCBinding(plc, "conv2", Conveyor, Return)
	
	# # synchronous call
	# ret = mover1(Mover(Conveyor(123), Conveyor(321), 0.2))
	# ret.errors && error("Errors have occurred")
	
	# # asynchronous call
	# task1 = @async conv1(Conveyor(123))
	# task2 = @async conv2(Conveyor(321))
	
	# # do other things...
	
	# ret = fetch(task1)
	# ret.errors && error("Errors have occurred")
	# ret = fetch(task2)
	# ret.errors && error("Errors have occurred")
end

main()
