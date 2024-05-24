# This script checks PiHole DNS server status.
# If PiHole is healthy, change DHCP servers to use it.
# Otherwise revert all DHCP servers to use public DNS servers.

:local piholeip <piHoleIpAddress>
:local dhcpservers [/ip dhcp-server find];
:local upstreamDnsServers <quotedAndCommaSeparatedListOfPublicDnsServers>

:do {
    /tool fetch url="http://$piholeip/admin/api.php?status";
    :foreach dhcpserver in $dhcpservers do={
        :local dhcpservername [/ip dhcp-server get $dhcpserver name];
        :local dnsserver [/ip dhcp-server network get $dhcpserver dns-server];
        if ($dnsserver != $piholeip) do={
            /ip dhcp-server network set $dhcpserver dns-server=$piholeip;
            :log info "Using Pi-hole as DNS Server for $dhcpservername";
        }
    }
} on-error {
    if ($dnsservers != $upstreamDnsServers) do={
        :foreach dhcpserver in $dhcpservers do={
            :local dhcpservername [/ip dhcp-server get $dhcpserver name];
            /ip dhcp-server network set $dhcpserver dns-server=$upstreamDnsServers;
            :log error "Pi-hole isn't working, using upstream DNS instead for $dhcpservername";
        }
    }
}

