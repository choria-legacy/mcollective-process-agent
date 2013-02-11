#Process Agent

An agent that can be used to list running processes on remote machines.

##Installation

* Follow the [basic plugin install guide](http://projects.puppetlabs.com/projects/mcollective-plugins/wiki/InstalingPlugins).
* You need to have the [sys-proctable](http://raa.ruby-lang.org/project/sys-proctable/) Gem installed.

##Configuration

The Process client application can be configured to list only a subset of possible process field values. This can be
configured in your client configuration file. Available fields are PID, USER, VSZ, COMMAND, TTY, RSS and STATE.
Unconfigured the output will default to PID, USER, VSZ and COMMAND.

```
plugin.process.fields = PID, COMMAND, TTY, STATE
```

##Usage
```
% mco process list ruby

 * [ ============================================================> ] 2 / 2

   node1.your.com

     PID       USER     VSZ            COMMAND
     31187     root     137.465 MB     ruby /usr/sbin/mcollectived --pid=/var/run/mcollectived.pid

   node2.your.com

     PID       USER     VSZ            COMMAND
     5202      root     120.793 MB     /usr/bin/ruby /usr/bin/puppet agent
     17348     root     112.105 MB     ruby /usr/sbin/mcollectived --pid=/var/run/mcollectived.pid


Summary of The Process List:

           Matched hosts: 2
       Matched Processes: 3
           Resident Size: 28.921 MB
            Virtual Size: 370.363 MB


Finished processing 2 / 2 hosts in 134.67 ms
```

```
mco process list ruby --fields=pid,command,state

 * [ ============================================================> ] 2 / 2

   node1.your.com

     PID       COMMAND                                                          STATE
     5202      /usr/bin/ruby /usr/bin/puppet agent                              S
     17348     ruby /usr/sbin/mcollectived --pid=/var/run/mcollectived.pid      R

   node2.your.com

     PID       COMMAND                                                          STATE
     31187     ruby /usr/sbin/mcollectived --pid=/var/run/mcollectived.pid      R


Summary of The Process List:

           Matched hosts: 2
       Matched Processes: 3
           Resident Size: 28.805 MB
            Virtual Size: 369.863 MB


Finished processing 2 / 2 hosts in 96.65 ms
```

##Data Plugin

The Process agent also supplies a data plugin which uses the sys-proctable Gem to check if there exists a process
that matches a given pattern and can be used during discovery or any other place where the MCollective discovery
language is used.

```
mco rpc rpcutil ping -S "process('ruby').exists=true"
```
