#------------------------------------------------------------------------------
# FUNCTION: Collect and manipulate some commonly used network info.
#  AUTHORS: Todd E Thomas
#     DATE: 2012/01/08
# MODIFIED:
#------------------------------------------------------------------------------


###----------------------------------------------------------------------------
### VARIABLES
###----------------------------------------------------------------------------
privNetwork="$(ip a | grep eth0 | grep brd | cut -d" " -f6 | cut -d"." -f1-3)"
x='1'


###----------------------------------------------------------------------------
### FUNCTION
###----------------------------------------------------------------------------
netaddress() {
	# Get the network segment
	while [ "$x" -le '3' ]; do
		eval octet$x="$(echo $privNetwork | cut -d"." -f$x)"
		x="$(( $x + 1 ))"
	done

	export privNetwork
	export InAddrArpa="$(echo $octet3.$octet2.$octet1)"

	# Now get the server's IP address for the reverse dns maps
	srvIP="$(ip a | grep eth0 | grep brd | cut -d" " -f6 | cut -d"." -f4 | cut -d"/" -f1)"
	export srvIP

	# Tell us what's going on
	echo "  This is a privNetwork=$privNetwork network."
	echo "  We will use InAddrArpa=$InAddrArpa for our reverse address."
	echo "  This is the address we will use for the servers local domain reverse dns map: srvIP=$srvIP"
}

netaddress &> /dev/null
