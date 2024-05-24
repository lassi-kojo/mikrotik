# This script adds and removes DNS records for DHCP clients.
# DHCP server is RouterOS builtin DHCP server
# DNS server is Technitium DNS Server: https://github.com/TechnitiumSoftware/DnsServer

# Fill out dnsServerIp, dnsServerPort and dns_server_token

:if ([:len $"lease-hostname"] > 0) do={

    # Taken from: https://github.com/mmastrac/snippets/blob/master/mikrotik/dhcp-dns.rsc
    :local cleanHostname do={
        :local max ([:len $1] - 1);
        :if ($1 ~ "^[a-zA-Z0-9]+[a-zA-Z0-9\\-]*[a-zA-Z0-9]+\$" && ([:pick $1 ($max)] != "\00")) do={
            :return ($1);
        } else={
            :local cleaned "";
            :for i from=0 to=$max do={
            :local c [:pick $1 $i]
            :if ($c ~ "^[a-zA-Z0-9]{1}\$") do={
                :set cleaned ($cleaned . $c)
            } else={
                if ($c = "-" and $i > 0 and $i < $max) do={
                :set cleaned ($cleaned . $c)
                }
            }
            }
            :return ($cleaned);
        }
    }

    :local dnsServerIp <dns_server_ip>;
    :local dnsServerPort <dns_server_port>;
    :local ttl [:tonum [/ip dhcp-server get [find name=$leaseServerName] lease-time]];
    :local token <technitium_dns_server_token>;
    :local type A;

    :local hostCleaned ""
    :set hostCleaned [$cleanHostname $"lease-hostname"]

    :foreach dhcpserver in [/ip dhcp-server find] do={
        :local dhcpservernet [/ip dhcp-server/network get $dhcpserver address];
        :if ($leaseActIP in $dhcpservernet) do={
            :local zone [/ip dhcp-server/network get $dhcpserver domain];
            :local domain "$hostCleaned.$zone"
            :if ($leaseBound = 1) do={
                :do {
                    :local result [/tool fetch url="http://$dnsServerIp:$dnsServerPort/api/zones/records/add?token=$token&domain=$domain&zone=$zone&type=$type&ipAddress=$leaseActIP&comments=$leaseActMAC&ttl=$ttl&overwrite=true" as-value output=user];
                    :log info "Added DNS record $domain for $leaseActIP.";
                } on-error={
                    :log error "Failed to add DNS record $domain for $leaseActIP!";
                }
            } else={
                :do {
                    :local result [/tool fetch url="http://$dnsServerIp:$dnsServerPort/api/zones/records/delete?token=$token&domain=$domain&zone=$zone&type=A&ipAddress=$leaseActIP" as-value output=user];
                    :log info "Removed DNS record $domain for $leaseActIP.";
                } on-error={
                    :log error "Failed to remove DNS record $domain for $leaseActIP!";
                }
            }
        }
    }
}
