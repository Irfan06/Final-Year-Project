BEGIN {

	# Calculation of throughput
	# initialization

	data = 0;
}

{
	# Pattern and Action

	if($1 == "r" && $4 == "AGT") {

		data = data + $8;
		time = $2;
	} 
}

END {

	# Calculation and Result Printing

        print "dataaa = " data "and time = " time;
	throughput = data*8/time/100000;
	print "Throughput = "throughput"MB/s";
}
#$1 -> Event
#$2 -> Time
#$3 -> Node id
#$4 -> Layer
#$5 -> Flags
#$6 -> Sequence Number
#$7 -> Packet Type
#$8 -> Packet Size 
