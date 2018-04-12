
set val(chan)      	 Channel/WirelessChannel        ;# Channel Type
set val(prop)      	 Propagation/TwoRayGround     	;# Radio Propagation Model
set val(netif)       	 Phy/WirelessPhy       		;# Network Interface Type
set val(ant)       	 Antenna/OmniAntenna      	;# Antenna Model
set val(rp)        	 AODV     			;# Routing Protocol
set val(ifq)       	 Queue/DropTail/PriQueue        ;# Interface Queue Type
set val(ifqlen)    	 50     			;# Maximum Packet in ifq
set val(mac)       	 Mac/802_11	     		;# MAC type
set val(ll)        	 LL                         	;# LinkLayer Type
set val(nn)        	 80              		;# Number of Mobilenodes
set val(ni)        	 4              		;# Number of Interfaces
set val(channum)   	 4				;# Number of Channel
set val(stop)      	 30                		;# Simulation Time
set val(x) 		 1000				;# X Dimension Area	
set val(y)       	 1000				;# Y Dimension Area
set val(energymodel) 	 EnergyModel	        	;# Energy set up


# Initialize Global Variables
set ns_	[new Simulator]
set tracefd  [open test.tr w]
$ns_ trace-all $tracefd

# Set up Topography Object
set topo       [new Topography]
$topo load_flatgrid $val(x) $val(y)

set r1 [open cluster.tr w]
set d1 [open Distance.tr w]

# Create Nam
set namtrace [open test.nam w]
$ns_ namtrace-all-wireless $namtrace $val(x) $val(y)

# Create God
set god_ [create-god $val(nn)]

#Mac/802_11 set RTSThreshold_  3000               ;# bytes
# Configure Node
$ns_ node-config -adhocRouting $val(rp) -llType $val(ll) -macType $val(mac) -ifqType $val(ifq) -ifqLen $val(ifqlen) -antType $val(ant) -propType $val(prop) -phyType $val(netif) -topoInstance $topo -EnergyModel $val(energymodel) -agentTrace ON -routerTrace ON -macTrace OFF -movementTrace ON

# Add ni*channum Channels

for {set i 0} {$i < [expr $val(ni)*$val(channum)]} {incr i} {
	set chan_($i) [new $val(chan)]
}

# Configure for Interface and Channel

$ns_ node-config -ifNum $val(ni) -channel $chan_(0)
$ns_ node-config -ChannelNum $val(channum)

# Add ni*channum Channels

for {set i 0} {$i < [expr $val(ni)*$val(channum)]} {incr i} {
	$ns_ add-channel $i $chan_($i)
}

source ./energy.tcl

for {set i 0} {$i < $val(nn)} {incr i} {

    set IE($i) $energy($i)
    $ns_ node-config  -energyModel $val(energymodel) \
                     -initialEnergy $energy($i) \
                     -rxPower 0.01 \
	             -txPower 0.03 \

	set node_($i) [$ns_ node]
        $node_($i) set recordIfall 1
	$node_($i) random-motion 0		;# disable random motion
	$node_($i) color black
	$ns_ at 0.0 "$node_($i) color black"
	$ns_ at 0.1 "$node_($i) color darkviolet"
}

# True Location

source ./topology.tcl

for {set i 0} {$i < $val(nn)} {incr i} {

	#set xx($i) [expr rand() * $val(x)]
	#set yy($i) [expr rand() * $val(y)]

	$node_($i) set X_ $xx($i)
	$node_($i) set Y_ $yy($i)
}

$ns_ at 0.1 "[$node_(0) set ragent_] channel_interface $val(channum) ff"
#$ns_ at 0.1 "[$node_(1) set netif_(1)] n_channel $val(channum)"

set communication_range 250
set sink 0

set midx [expr $val(x) / 2]
set midy [expr $val(y) / 2]
$node_($sink) set X_ $midx
$node_($sink) set Y_ $midy
$node_($sink) set Z_ 0.0
set xx($sink) $midx
set yy($sink) $midy
$ns_ at 0.0 "$node_($sink) setdest $xx($sink) $yy($sink) 500.0"
$ns_ at 0.1 "$node_($sink) color #FF1493"
$ns_ at 0.1 "$node_($sink) label SINK"

set basestation 1
set cor_x 906.8
set cor_y 881.9

$node_($basestation) set X_ $cor_x
$node_($basestation) set Y_ $cor_y
$node_($basestation) set Z_ 0.0
set xx($basestation) $cor_x
set yy($basestation) $cor_y
$ns_ at 0.0 "$node_($basestation) setdest $xx($basestation) $yy($basestation) 500.0"
$ns_ at 0.1 "$node_($basestation) color #FF1493"
$ns_ at 0.1 "$node_($basestation) label BASESTATION"

for {set i 2} {$i < 12} {incr i} {
    set PU($i) $i
    set SU_status($i) 0
    set PU_status($i) 1
    $ns_ at 0.1 "$node_($PU($i)) color Darkgreen"
    $ns_ at 0.1 "$node_($PU($i)) label PU_($i)"
}

############## Optimal Number of Clusterhead Selection #################
 		
set ncluster [expr [expr $val(x)/$communication_range]]

puts $r1 "Ncluster=$ncluster"

############## Grid Assignment of Nodes [at 1.0] ##################

set cluster $ncluster
puts "Cluster=$cluster"
puts $r1 "Cluster=$cluster"

set gheight [expr $val(y) / [expr pow($cluster, 0.5)]] 
#500
set gwidth [expr $val(x) / [expr pow($cluster, 0.5)]] 
#500
set g [expr $val(x) / $gwidth] 
#2

puts "g=$g"
puts "gheight=$gheight"
puts "gwidth=$gwidth"

for {set i 12} {$i < $val(nn)} {incr i} {
	set SU_status($i) 1
	set PU_status($i) 0
	set grid 1
	for {set gx 1} {$gx <= $g} {incr gx} {

		if {$xx($i) <= [expr $gwidth * $gx]} {
		
			set xp [expr $gwidth * $gx]
			set gx [expr round($g) + 1]
			
			for {set gy 1} {$gy <= $g} {incr gy} {
				set yp [expr $gheight * $gy]
				if {$yy($i) <= [expr $gheight * $gy]} {
					set gridid($i) $grid
					break;
				} else {
					set grid [expr $grid + 1]
				}
			}
		} else {
			set grid [expr [expr $gx * $g] + 1]
		}
	}
}

for {set i 2} {$i < $val(nn)} {incr i} {

	$ns_ at 0.5 "[$node_($i) set ragent_] Status $PU_status($i) $SU_status($i) $i"
}


set cm(1) DarkCyan 
set cm(2) OliveDrab
set cm(3) DarkSalmon
set cm(4) DarkViolet
set cm(5) brown
set cm(6) cyan
set cm(7) green
set cm(8) Darkgreen
set cm(9) SteelBlue
set cm(10) DarkKhaki

for {set i 1} {$i <= $cluster} {incr i} {
	set count($i) 0
}

for {set j 12} {$j < $val(nn)} {incr j} {
set mark($j) 0
set status1($j) 0

	for {set i 1} {$i <= $cluster} {incr i} {
		if {$gridid($j) == $i} {
			set count($i) [expr $count($i) + 1]
			#puts " $count($i) and $gr($i-$count($i)) and $j"
			set gr($i-$count($i)) $j
		}
	}

}

for {set i 1} {$i <= $cluster} { incr i } {
	puts "Grid: $i Grid Members Count: $count($i)"
}


#color selection for nodes

set now 1.0
for {set i 1} {$i <= $cluster} { incr i} {
	set m1 $i
	for {set j 1} {$j <= $count($i)} {incr j} {
		puts $r1 "grid_ID($i-$j)=$gr($i-$j)"    	
		if {$i > 10} {
			set m1 [expr $m1 % 10]
		}
	$ns_ at $now "$node_($gr($i-$j)) color $cm($i)"
        $ns_ at $now "$node_($gr($i-$j)) label CLUSTER_$i"
	}	
	puts $r1 "\n"
}


# distance caluation 
for {set i 12} {$i < $val(nn)} {incr i} {
    for {set j 12} {$j < $val(nn)} {incr j} {
    
        set dx [expr $xx($i) - $xx($j)]
        set dy [expr $yy($i) - $yy($j)]
        set dx1 [expr $dx * $dx]
        set dy1 [expr $dy * $dy]
        set h [expr $dx1 + $dy1]
        set distance($i-$j) [expr pow($h,0.5)]
        
        puts $d1 "Distance from ($i) to ($j) = $distance($i-$j)"
    }
    
    puts $d1 "\n"
}

# neighbor calculation

for {set i 12} {$i < $val(nn)} {incr i} {

set ncount($i) 0
puts $d1 "\n"

    for {set k 12} {$k < $val(nn)} {incr k} {
    
        if {$distance($i-$k) < $communication_range && $distance($i-$k) != 0} {        
               set ncount($i) [expr $ncount($i) + 1]   
               set neid($i-$ncount($i)) $k

		puts $d1 "Neighbor of node $i = $neid($i-$ncount($i))"
        }
    }
puts $d1 "Neighbor COunt of node $i = $ncount($i)"
}



# clusterhead Selection

set ini_energy 10
for {set i 1} {$i <= $cluster} {incr i} {

	for {set j 1} {$j <= $count($i)} {incr j} {
	
	set ene($gr($i-$j)) $energy($gr($i-$j))
	
	set EE($gr($i-$j)) [expr $ene($gr($i-$j)) / $ini_energy]
	set NC1($gr($i-$j)) [expr $ncount($gr($i-$j)) / [expr $val(nn) * 1.0]]

	set tot_fa($gr($i-$j)) [expr ($EE($gr($i-$j)) * 0.5) + ($NC1($gr($i-$j)) * 0.5)]

	#puts "gr($i-$j)=$gr($i-$j).......TOTAL_Factor=$tot_fa($gr($i-$j))"
	}
}

set c1 [open clusterhead.tr w]
for {set i 1} {$i <= $cluster} {incr i} {
    set max($i) 0
    for {set j 1} {$j <= $count($i)} {incr j} {
    
        if {$max($i) < $tot_fa($gr($i-$j))} {
            set max($i) $tot_fa($gr($i-$j))
            set CH($i) $gr($i-$j)
            set mark($CH($i)) 1
        } 
     }
    puts $c1 "Clusterhead($i)=$CH($i).....Maximum Value=$max($i) "
    puts $r1 "Clusterhead($i)=$CH($i).....Maximum Value=$max($i) "
    puts "Clusterhead($i)=$CH($i).....Maximum Value=$max($i) "
    $ns_ at 1.0 "$node_($CH($i)) color cyan"
    $ns_ at 1.0 "$node_($CH($i)) label ClusterHead($i)"
}

for {set i 1} {$i <= $cluster} {incr i} {
    for {set j 1} {$j <= $count($i)} {incr j} {
        $ns_ at 1.0 "[$node_($gr($i-$j)) set ragent_] clusterhead $i $CH($i) $count($i) $gr($i-$j)"
    }
}

set now 4.0
set source 49
$ns_ at 2.0 "$node_($source) color magenta"
$ns_ at 2.0 "$node_($source) label Source"

	set udp [new Agent/UDP]
	$ns_ attach-agent $node_($source) $udp
	set null [new Agent/Null]
	$ns_ attach-agent $node_($sink) $null
	$ns_ connect $udp $null
	set cbr [new Application/Traffic/CBR]
	$cbr attach-agent $udp
	$cbr set packetSize_ 512
	$cbr set interval_ 1.0
	$ns_ at [expr $now + 5.0] "$cbr start"
	$ns_ at [expr $now + 5.1] "$ns_ trace-annotate \" Data Transmission from Sender to Receiver\""
	$ns_ at [expr $now + 5.1] ""	
	$ns_ at [expr $now + 15.0] "$cbr stop"

set source 52
$ns_ at 2.0 "$node_($source) color magenta"
$ns_ at 2.0 "$node_($source) label Source"

	set udp [new Agent/UDP]
	$ns_ attach-agent $node_($source) $udp
	set null [new Agent/Null]
	$ns_ attach-agent $node_($sink) $null
	$ns_ connect $udp $null
	set cbr [new Application/Traffic/CBR]
	$cbr attach-agent $udp
	$cbr set packetSize_ 512 
	$cbr set interval_ 1.0
	$ns_ at [expr $now + 5.0] "$cbr start"
	$ns_ at [expr $now + 5.1] "$ns_ trace-annotate \" Data Transmission from Sender to Receiver\""
	$ns_ at [expr $now + 15.0] "$cbr stop"

set source 61
$ns_ at 2.0 "$node_($source) color magenta"
$ns_ at 2.0 "$node_($source) label Source"

	set udp [new Agent/UDP]
	$ns_ attach-agent $node_($source) $udp
	set null [new Agent/Null]
	$ns_ attach-agent $node_($sink) $null
	$ns_ connect $udp $null
	set cbr [new Application/Traffic/CBR]
	$cbr attach-agent $udp
	$cbr set packetSize_ 512 
	$cbr set interval_ 1.0
	$ns_ at [expr $now + 5.0] "$cbr start"
	$ns_ at [expr $now + 5.1] "$ns_ trace-annotate \" Data Transmission from Sender to Receiver\""
	$ns_ at [expr $now + 15.0] "$cbr stop"


	set pus 5
	set udp [new Agent/UDP]
	$ns_ attach-agent $node_($pus) $udp
	set null [new Agent/Null]
	$ns_ attach-agent $node_($basestation) $null
	$ns_ connect $udp $null
	set cbr [new Application/Traffic/CBR]
	$cbr attach-agent $udp
	$cbr set packetSize_ 512 
	$cbr set interval_ 1.0
	$ns_ at [expr $now + 7.0] "$cbr start"
	$ns_ at [expr $now + 7.1] "$ns_ trace-annotate \" Data Transmission from Sender to Receiver\""
	$ns_ at [expr $now + 15.0] "$cbr stop"

#source $val(cp)  ;#source topology and traffic file generated by others

$ns_ at 5.0 "findEnergyConsumption"

set en [open energyConsumption.tr w] 

proc findEnergyConsumption { } {

	global ns_ node_ val EConsumption IE en  
        set now [$ns_ now]

        set EConsumption 0.0 	
	set total_re 0.0

	for {set i 0} {$i < $val(nn) } { incr i } {
		set FE($i) [$node_($i) energy]
	}
	for {set i 0} {$i < $val(nn) } { incr i } {
		set total_re [expr $total_re + $FE($i)]
	}

	puts "Total Residual Energy=$total_re"
	
	for {set i 0} {$i < $val(nn) } { incr i } {
		set CE($i) [expr $IE($i) - $FE($i)]
	}
	
	for {set i 0} {$i < $val(nn) } { incr i } {
		set EConsumption [expr $CE($i) + $EConsumption]
	}

        set avg_eng [expr $EConsumption / $val(nn)]

	puts $en "Routing_Energy Consumption = $EConsumption J"	

        puts $en "Average_Energy Consumption = $avg_eng J"

	$ns_ at [expr $now + 5.0] "findEnergyConsumption"
}	


# Define the Node Size for NAM

for {set i 0} {$i < $val(nn)} {incr i} {
	$ns_ initial_node_pos $node_($i) 40
}

# Tell Nodes When the Simulation Ends
for {set i 0} {$i < $val(nn)} {incr i} {
    $ns_ at [expr $val(stop)+0.1] "$node_($i) reset"; 
}

$ns_ at $val(stop) "$ns_ nam-end-wireless $val(stop)"
$ns_ at $val(stop) "stop"
$ns_ at $val(stop) "puts \"NS EXITING...\" ; $ns_ halt "

# Stop Procedure

proc stop { } {
	global ns_ tracefd
	$ns_ flush-trace
	close $tracefd
   	exec nam test.nam &
	exec awk -f Throughput.awk test.tr > Throughput.tr &
	#exec awk -f Overhead.awk test.tr > Overhead.tr &
	exec awk -f Delay.awk test.tr > Delay.tr &
    	exit 0
}
puts "Starting Simulation..."
$ns_ run


