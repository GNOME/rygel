#!/usr/bin/env python

from gi.repository import Gst, GObject, RygelRendererGst

GObject.threads_init()
Gst.init()

renderer = RygelRendererGst.PlaybinRenderer.new("rygel gst renderer")
renderer.add_interface("eth1")

#start the mainloop and wait for a connection
GObject.MainLoop().run() 
