BEGIN {

	# Calculation of Delay
	# initialization

	Total_Delay = 0;
	count = 0;
}

{

#$1 -> Event
#$2 -> Time
#$3 -> Node id
#$4 -> Layer
#$5 -> Flags
#$6 -> Sequence Number
#$7 -> Packet Type
#$8 -> Packet Size 

	# Pattern and Action

	if($1 == "s" && $4 == "AGT") {
		
		sending_time[$6] = $2;

		packet_sequence_number = $6;

	} 

	else if($1 == "r" && $4 == "AGT") {
		
		receiving_time[$6] = $2;

	} 

	else if ($1 == "D" && $7 == "cbr") {

		receiving_time[$6] = -1;
	}
}

END {
	# Calculation and Result Printing	

	for (i=0; i<=packet_sequence_number; i++) {

		if (receiving_time[i] > 0.0) {		

			delay[i] = receiving_time[i] - sending_time[i];

			Total_Delay = Total_Delay + delay[i];

			count++;
		} else {

			delay[i] = -1;
		}
	} 

	if (count != 0) {

		Average_Delay =  Total_Delay / count;

		print "Total_Delay ="Total_Delay;	
		print "Count ="count;
		print "Average Delay  = "Average_Delay"s";
	}
}


