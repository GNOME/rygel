#!/usr/bin/env python

from gi.repository import GObject
from gi.repository import RygelCore as rc
from gi.repository import RygelServer as rs

rs.MediaEngine.init ()

c = rs.SimpleContainer.root ("DLNA from Python!")
i = rs.VideoItem (id = "0001",
                  parent = c,
                  title = "Test Video",
                  upnp_class = rs.ImageItem.UPNP_CLASS)
i.set_property ("mime-type", "video/ogv")
c.add_child_item (i)

d = rs.MediaServer (title = "DLNA server from Python!",
                    root_container = c,
                    capabilities = rc.PluginCapabilities.NONE)
d.add_interface ("eth0")

GObject.MainLoop().run()
