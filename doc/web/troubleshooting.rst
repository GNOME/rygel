.. SPDX-License-Identifier: LGPL-2.1-or-later

===============
Troubleshooting
===============

Providing backtraces in case of crashes
=======================================

For providing a good backtrace in case Rygel crashes, please refer to
`this blog post by Michael Cantazero <https://blogs.gnome.org/mcatanzaro/2021/09/18/creating-quality-backtraces-for-crash-reports/>`_


Providing log files
===================

When reporting a non-fatal issue such as Rygel not being seen by other devices, you will be ased to provide a
detailed log.

This can be achieved by starting Rygel manually from a terminal with the following command line:

::

  G_MESSAGES_DEBUG=all rygel -g 5 2>&1 | tee rygel.log

Instead of passing :code:`-g 5` you can also edit the log level in the :code:`rygel.conf` file,
as described in the man page

Providing a packet dump
=======================

In case the problem exists before the device actually talks to Rygel, you might be asked to do a packet capture.

This can either be done with `Wireshark <https://www.wireshark.org/>`_ or `tcpdump <https://www.tcpdump.org/>`_.

For tcpdump, the commandline should look something like the snippet below, assuming Rygel is running on IP 192.168.0.1 and
the device in question has IP 192.168.0.2 and the network device you are capturing on is eth0.

::

    tcpdump -i eth0 -s 0 -w rygel.pcap "(ip src 192.168.0.1 and ip dst 192.168.0.2) \
        or (ip dst 192.168.0.1 and ip src 192.168.0.2) \
        or (ip dst 239.255.255.250) or (ip src 239.255.255.250)"

This will capture all traffic between the two hosts in question as well as the SSDP annoncement traffic. There is also a small wizard script that can help you
generate the commandline above, `gen-capture <https://gitlab.gnome.org/GNOME/rygel/-/raw/master/tools/gen-capture?ref_type=heads>`_
