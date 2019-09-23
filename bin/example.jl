using PLCTag


function main()
	plc = PLC(
		cpu = "compactlogix",
		protocol = "ab-eip",
		gateway = "192.168.1.1",
		path = "1,0",
	)
	
	str = String(plc, "str")
	@info str
end

main()

