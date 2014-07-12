#!/usr/bin/env python

from gi.repository import RygelCore as rc
from gi.repository import RygelRenderer as rr
from gi.repository import GObject

class ExamplePlayer(GObject.Object, rr.MediaPlayer):
    __gtype_name = "RygelPythonExamplePlayer"

    # Abstract properties
    playback_state = GObject.property (type = str, default = "NO_MEDIA_PRESENT")
    allowed_playback_speeds = GObject.property (type = GObject.TYPE_STRV, default = ["1"])
    playback_speed = GObject.property (type = str, default = "1")
    uri = GObject.property (type = str, default = "")
    volume = GObject.property (type = float, default = 1.0)
    duration = GObject.property (type = GObject.TYPE_INT64, default = 0)
    size = GObject.property (type = GObject.TYPE_INT64, default = 0)
    metadata = GObject.property (type = str, default = None)
    mime_type = GObject.property (type = str, default = "")
    can_seek = GObject.property (type = bool, default = False)
    can_seek_bytes = GObject.property (type = bool, default = False)
    content_features = GObject.property (type = str, default = None)
    position = GObject.property (type = GObject.TYPE_INT64, default = 0)
    byte_position = GObject.property (type = GObject.TYPE_INT64, default = 0)

    # Abstract methods
    def do_seek(self, position):
        return False

    def do_seek_bytes(self, position):
        return False

    def do_get_protocols(self):
        return ["http"], 1

    def do_get_mime_types(self):
        val = ["image/jpeg"]
        print ("Mime types: ", val)
        return val, len(val)

    # Property setters/getters
    def do_get_volume(self):
        return self.volume;

    def do_set_volume(self, _volume):
        self.volume = _volume;

    def __init__(self):
        GObject.Object.__init__(self)

d = rr.MediaRenderer (title = "DLNA renderer from Python!",
                      player = ExamplePlayer())

d.add_interface ("lo")

GObject.MainLoop().run()
