# Process beginning
if {$argc != 1} {
	puts "Comparsion between Reno & New Reno "
	puts "Example:ns sim.tcl Reno or ns sim.tcl Newreno"
	exit
}

# Capture TCP ver. setting
set par1 [lindex $argv 0]

# Set simu period
set period 12 

# Initialzing ns
set ns [new Simulator]

# Open a NAM trace file
set nf [open out-$par1.nam w]
$ns namtrace-all $nf

# Open a trace file
set nd [open out-$par1.tr w]
$ns trace-all $nd

set f0 [open cwnd-$par1.tr w]

# Set colors for NAM
$ns color 1 Blue
$ns color 2 Red

# Define finish process
proc finish {} {
    global ns nf nd tcp par1 f0 period
    # Print out avg. throughput (fstring)
    puts [format "average throughput: %.1f Kbps" \
        [expr [$tcp set ack_]*([$tcp set packetSize_])*8/1000.0/$period]]
    
    $ns flush-trace
    close $nf
    close $nd
    close $f0

    # Analysis using awk
    exec awk {
        BEGIN {
            highest_packet_id = -1;
            packet_count = 0;
            q_eln = 0;
        }

        {
            # Correspond to tr file format
            action = $1;
            time = $2;
            src_node = $3;
            dst_node = $4;
            type = $5;
            flow_id = $8;
            seq_no = $11;
            packet_id = $12;

            if (src_node == "1" && dst_node == "2") {
                if (packet_id > highest_packet_id) {
                    highest_packet_id = packet_id;
                }
                if (action == "+") {
                    q_len++;
                    print time, q_len;
                }
                if (action == "-" || action == "d") {
                    q_eln = q_len--;
                    print time, q_len;
                }
            }
            
        }
    } out-$par1.tr > queue_length-$par1.tr

    # Call NAM
    # exec nam out-$par1.nam &
    exit 0
}

proc record {} {
    global ns tcp f0

    set now [$ns now]
    puts $f0 "$now [$tcp set cwnd_]"
    $ns at [expr $now+0.01] "record"
}

# Declare nodes
set send [$ns node]
set n0 [$ns node]
set n1 [$ns node]
set recv [$ns node]
# set null [$ns node]

# Node connections
$ns duplex-link $n0 $send 10Mb 1ms DropTail
$ns duplex-link $n0 $n1 1Mb 5ms DropTail
$ns duplex-link $n1 $recv 10Mb 1ms DropTail
# $ns duplex-link $n1 $null 10Mb 1ms DropTail

# Set queue size
# TUNE HERE
set buffer_size 11
$ns queue-limit $n0 $n1 $buffer_size

# Positioning & setting for NAM
$ns duplex-link-op $send $n0 orient right-down
$ns duplex-link-op $n0 $n1 orient right
$ns duplex-link-op $n1 $recv orient right-up

$ns duplex-link-op $n0 $n1 queuePos 0.5
$ns duplex-link-op $send $n0 queuePos 0.3
$ns duplex-link-op $n1 $recv queuePos 0.3

# Set TCP ver.
if {$par1=="Reno"} {
    set tcp [new Agent/TCP/Reno]
    set tcpsink [new Agent/TCPSink]
    $tcp set debug_ 0
} elseif {$par1=="Newreno"} {
    set tcp [new Agent/TCP/Newreno]
    set tcpsink [new Agent/TCPSink]
    $tcp set debug_ 0
} else {
    set tcp [new Agent/TCP/Sack1]
    set tcpsink [new Agent/TCPSink/Sack1]
    $tcp set debug_ 1
}

# TCP transmission shows in blue
$tcp set fid_ 1

set null [new Agent/Null]
$ns attach-agent $send $tcp
# $ns attach-agent $null $null_a

$tcp set window_ 30
$ns attach-agent $recv $tcpsink
$ns connect $tcp $tcpsink

set ftp [new Application/FTP]
$ftp attach-agent $tcp
$ftp set fid_ 2

$ns at 0.0 "$ftp start"
$ns at 6.0 "$ns detach-agent $recv $tcpsink"
$ns at 6.0 "$ns attach-agent $recv $null"
$ns at 7.5 "$ns detach-agent $recv $null"
$ns at 7.5 "$ns attach-agent $recv $tcpsink"
$ns at $period "$ftp stop"
$ns at 0.0 "record"
$ns at $period "finish"

puts [format "on path: %.2f packets" \
    [expr (1000000/(8*([$tcp set packetSize_]+40)) * ((1+4+1) * 2 * 0.001)) + $buffer_size]]

$ns run
