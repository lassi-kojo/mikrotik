# This script upgrades selected container automatically.

# Container identifier
:global hostname "pihole";

/container 
:global id [find where hostname=$hostname];
:global rootdir [get $id root-dir];
:global interface [get $id interface];
:global envlist [get $id envlist];
:global mounts [get $id mounts];
:global tag [get $id tag];
:global dns [get $id dns];
:global logging [get $id logging];
:global status [get $id status];

# Stop the container
stop $id
:put "Stopping the container...";
:while ($status != "stopped") do={
    :put "Waiting for the container to stop...";
    :delay 5;
    :set status [get $id status];
} 
:put "Stopped.";

# Remove the container
remove $id
:put "Removing the container...";
:while ($status = "stopped") do={
    :put "Waiting for the container to be removed...";
    :delay 5;
    :set status [get $id status];
} 
:put "Removed.";

# Add the container
:delay 5;
:put "Adding the container...";
add remote-image=$tag \
    interface=$interface \
    envlist=$envlist \
    mounts=$mounts \
    root-dir=$rootdir \
    start-on-boot=yes \
    hostname=$hostname \
    logging=$logging\
    dns=$dns
:do {
    :set status [get [find where hostname=$hostname] status];
    :if ($status != "stopped") do={
        :put "Waiting for the container to be added...";
        :delay 5;
    }
} while ($status != "stopped")
:put "Added."

# Start the container
:put "Starting the container.";
:set id [find where hostname=$hostname];
start $id
