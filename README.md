apsh

An ssh wrapper for executing a command on multiple nodes.

There are many good projects out there for parallel command execution. However, I was looking for something written in perl, lightweight and functionally along the lines of xCAT's psh without having to install full blown xCAT. Here it is...

Hope you find it useful.


Notes
------------------------------------------------
apsh supports non-interactive mode only, so that means:

    all nodes must be setup for ssh key authentication 

    if the remote user is not root and you are using sudo, that user must sudo without supplying a password 



Installation
------------------------------------------------
cd apsh/
sudo ./install.sh



Config File
------------------------------------------------
Location:

/etc/apsh/nodes.tab

Format:

nodename[,<SSH_OPTIONS>]:username:comma,separated,groupnames

The group "all" is implied, however, you can exclude a node from this implied group via:

nodename[,<SSH_OPTIONS>]:username:comma,separated,groupnames,-all


A word on ssh options
------------------------------------------------
When supplying ssh options via the nodes.tab file, it is best to use the -o variety as these work with both ssh and scp.

For example, specifying the port to use with both ssh and scp the usual way:

ssh -p 22

scp -P 22

So, rather the use the -p/-P option, use the "-o Port=22" which works the same with both.

ssh -o Port=22

scp -o Port=22

apsh Usage
------------------------------------------------------------------------------------------------

General
------------------------------------------------
apsh all uptime


Commands with spaces
------------------------------------------------
apsh all "uname -a"


Multiple nodes and groups
------------------------------------------------
apsh group1,group2,node1,node2 uptime


Exclude a node
------------------------------------------------
apsh group1,-node1 uptime


Exclude a group
------------------------------------------------
apsh all,-group1 uptime


Run a series of commands
------------------------------------------------
apsh all "date;modinfo e1000e | grep '^version'"

apscp Usage
------------------------------------------------------------------------------------------------

General
------------------------------------------------
apscp file1 all,-node1:/tmp

Multiple file upload
------------------------------------------------
apscp file1 file2 file3 all,-node1:/tmp

or

apscp file* all,-node1:/tmp


acoll Usage
------------------------------------------------------------------------------------------------
The command acoll collates the ouput from apsh as follows:

$ apsh group1,group2,-node2 date | acoll

##########################################

node1 group2

##########################################

Sat May 11 08:34:47 EDT 2013


$
