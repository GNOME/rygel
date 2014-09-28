#!/usr/bin/env python
#
# Copyright (c) 2014, Jens Georg <mail@jensge.org>
#
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# 1. Redistributions of source code must retain the above copyright notice, this
# list of conditions and the following disclaimer.
#
# 2. Redistributions in binary form must reproduce the above copyright notice,
# this list of conditions and the following disclaimer in the documentation
# and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
#         SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
# HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
# LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT
# OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH
# DAMAGE.

from gi.repository import RygelCore as rc
from gi.repository import RygelRenderer as rr
from gi.repository import GLib
from gi.repository import GObject

import gi
import sys

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
        return val, len(val)

    # Property setters/getters
    def do_get_volume(self):
        return self.volume;

    def do_set_volume(self, _volume):
        self.volume = _volume;

    def do_get_playback_speed(self):
        return "1.0"

    def do_get_duration(self):
        return 0

    def do_set_uri(self, uri):
        self.uri = uri

    def do_get_uri(self):
        return self.uri

    def do_get_metadata(self):
        return self.metadata

    def do_set_playback_state(self, new_state):
        print("Client is requesting new state " + new_state)
        self.playback_state = new_state

    def do_get_playback_state(self):
        return self.playback_state

    def do_get_can_seek(self):
        return False

    def do_get_can_seek_bytes(self):
        return False

    def do_get_allowed_playback_speeds(self):
        return ["1.0"]

    def do_get_position(self):
        return 0

    def do_get_byte_position(self):
        return 0

    def do_set_mime_type(self, mime_type):
        print("Setting mime type to " + mime_type)
        self.mime_type = mime_type

    def do_set_content_features(self, content_features):
        print("Setting content features to " + content_features)
        self.content_features = content_features

    def do_set_metadata(self, metadata):
        print("Setting meta data to " + metadata)
        self.metadata = metadata

    def __init__(self):
        GObject.Object.__init__(self)

major,minor,micro = gi.version_info

ok = (major >= 3 and minor > 13) or (major == 3 and minor == 13 and micro >= 4)

if not ok:
    print("Need at least pygobject version 3.13.4 to work")
    sys.exit(-1)
else:
    print("Proper PyGObject version found!")

d = rr.MediaRenderer (title = "DLNA renderer from Python!",
                      player = ExamplePlayer())

d.add_interface ("lo")

GLib.MainLoop().run()
