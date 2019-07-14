+++
title = "CCSDS Router"
[taxonomies]
categories = ["Flight Software", "NASA"]
+++
This post is about a [CCSDS packet routing tool](https://github.com/nsmryan/CCSDS-Router) I've been writing in Rust. 
The motivation here is to provides a tool for moving CCSDS packets from one place to another, either from a file/TCP socket/
UDP socket to a file/TCP socket/UDP socket. I often have CCSDS packets in one of these forms, either stored or streaming,
and I want them to be in another (recorded to a file or streamed to a destination). When doing this, I sometimes want to
delay packets, throttle packets, or replay them according to their timestamp, such as when replaying captured data
during a test.


The use cases that I had when writing this:


* You have stored packets in a file, and you want to replay them according to a timestamp within the packet.
  This can be used for testing, such as to replay sensor data, or to test other tools by sending CCSDS packets to
  them.

* You want to save CCSDS from a network interface to a file.

* You want to route CCSDS packets from a TCP or UDP port to another TCP or UDP port.

* You want to delay packets by a fixed amount. This could be used to simulate a delay that would be experience in operation,
  but not in testing. Introducing this delay can expose issues in timeouts, for example, that would otherwise be seen first
  during operations.

* You want to throttle packet delivery such that packets are received no faster then a given rate. This might help, for example,
  with ensuring commands are not received faster then the maximum allowed rate.

* You want to do one of the above, while filtering for a subset of APIDs.

* You have regular CCSDS packets, or packets with a header and/or a footer of fixed size. The tool also supports packets
  that are not CCSDS, but they must be of fixed length for it to know how to find the next packet.

* You have a mixture of packets from a source, and you want to forward packets with certain APIDs to certain sinks. For example,
  you might store all packets in a file for logging, forward some packets to a visuzlizer program, and forward all packets to a
  ground system. You might also want to extract packets with a particular APID from a file, so you read from a file to another file,
  filtering for packets with that APID.


One thing to note about using this tool- as of today (02/23/2019) I have tested this tool with real data, but it have not been battle
tested. I know it has some rough edges, and I expect it will not cover all cases that one might see in production- it needs some
testing and production use before I would use it as a trusted part of a system. I would certainly use it for testing and development,
and fix up anything I find, and I hope someone out there might do the same.


Thanks for reading!

