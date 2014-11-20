/*
 * Copyright (C) 2013  Cable Television Laboratories, Inc.
 *
 * Author: Craig Pratt <craig@ecaspia.com>
 *
 * This file is part of Rygel.
 *
 * Rygel is free software; you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program; if not, write to the Free Software Foundation,
 * Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS
 * IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
 * THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL CABLE TELEVISION LABORATORIES
 * INC. OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
 * TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 * PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 * LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 * NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

using GUPnP;
using Gee;

/**
 * Represents a media resource (Music, Video, Image, etc).
 */
public class Rygel.MediaResource : GLib.Object {
    private string name;

    // Res block fields
    public string uri { get; set; }
    public string import_uri { get; set; }
    public string extension { get; set; default = null; }
    public int64 size { get; set; default = -1; } // In bytes
    public int64 cleartext_size { get; set; default = -1; } // In bytes
    public long duration { get; set; default = -1; } // In seconds
    public int bitrate { get; set; default = -1; } // In bits per second
    public int bits_per_sample { get; set; default = -1; }
    public int color_depth { get; set; default = -1; } // In bits
    public int width { get; set; default = -1; } // In pixels
    public int height { get; set; default = -1; } // In pixels
    public int audio_channels { get; set; default = -1; }
    public int sample_freq { get; set; default = -1; } // In Hz

    // ProtocolInfo fields
    public string protocol { get; set; default = null; }
    public string mime_type  { get; set; default = null; }
    public string dlna_profile  { get; set; default = null; }
    public string network  { get; set; default = null; }
    public string[] play_speeds = null;
    public DLNAConversion dlna_conversion { get; set; default = DLNAConversion.NONE; }
    public DLNAFlags dlna_flags { get; set; default = DLNAFlags.NONE; }
    public DLNAOperation dlna_operation { get; set; default = DLNAOperation.NONE; }

    // I know gupnp-av DIDLLiteResource and ProtocolInfo structures have the above fields.
    //  But both proved to be problematic in their current form. This class can be
    //  refactored if/when these classes are made more more flexible. For now, this class
    //  needs to serve the needs of Rygel first and foremost...

    public MediaResource (string name) {
        this.name = name;
    }

    /**
     * Copy constructor
     */
    public MediaResource.from_resource (string name, MediaResource that) {
        this.name = name;
        // res block
        this.uri = that.uri;
        this.import_uri = that.uri;
        this.extension = that.extension;
        this.size = that.size;
        this.cleartext_size = that.cleartext_size;
        this.duration = that.duration;
        this.bitrate = that.bitrate;
        this.bits_per_sample = that.bits_per_sample;
        this.color_depth = that.color_depth;
        this.width = that.width;
        this.height = that.height;
        this.audio_channels = that.audio_channels;
        this.sample_freq = that.sample_freq;
        // protocol info
        this.protocol = that.protocol;
        this.mime_type = that.mime_type;
        this.dlna_profile = that.dlna_profile;
        this.network = that.network;
        this.play_speeds = copy_speeds (that.play_speeds);
        this.dlna_conversion = that.dlna_conversion;
        this.dlna_flags = that.dlna_flags;
        this.dlna_operation = that.dlna_operation;
    }

    public static string []? copy_speeds (string? [] src) {
        if (src == null) {
            return null;
        }
        var new_speeds = new string[src.length];
        int speed_index = 0;
        foreach (var speed in src) {
            new_speeds[speed_index++] = speed;
        }

        return new_speeds;
    }

    public MediaResource dup () {
        return new MediaResource.from_resource (this.get_name (), this);
    }

    public string get_name () {
        return this.name;
    }

    private HashMap<string,string> property_table = new HashMap<string,string> ();

    public void set_custom_property (string ? name, string ? value) {
        property_table.set (name,value);
    }

    public string get_custom_property (string ? name) {
        return property_table.get (name);
    }

    public Set get_custom_property_names () {
        return property_table.keys;
    }

    public void apply_didl_lite (DIDLLiteResource didl_resource) {
        //  Populate the MediaResource from the given DIDLLiteResource
        // Note: For a DIDLLiteResource, a value of -1/null also signals "not set"
        this.uri = didl_resource.uri;
        this.size = didl_resource.size64;
        this.cleartext_size = didl_resource.cleartext_size;
        this.duration = didl_resource.duration;
        this.bitrate = didl_resource.bitrate;
        this.bits_per_sample = didl_resource.bits_per_sample;
        this.color_depth = didl_resource.color_depth;
        this.width = didl_resource.width;
        this.height = didl_resource.height;
        this.audio_channels = didl_resource.audio_channels;
        this.sample_freq = didl_resource.sample_freq;
        if (didl_resource.protocol_info != null) {
            this.protocol = didl_resource.protocol_info.protocol;
            this.mime_type = didl_resource.protocol_info.mime_type;
            this.dlna_profile = didl_resource.protocol_info.dlna_profile;
            this.network = didl_resource.protocol_info.network;
            this.play_speeds = copy_speeds (didl_resource.protocol_info.play_speeds);
            this.dlna_conversion = didl_resource.protocol_info.dlna_conversion;
            this.dlna_flags = didl_resource.protocol_info.dlna_flags;
            this.dlna_operation = didl_resource.protocol_info.dlna_operation;
        }
    }

    public DIDLLiteResource serialize (DIDLLiteResource didl_resource) {
        // Note: For a DIDLLiteResource, a value of -1/null also signals "not set"
        didl_resource.uri = this.uri;
        didl_resource.size64 = this.size;
        didl_resource.cleartext_size = this.cleartext_size;
        didl_resource.duration = this.duration;
        didl_resource.bitrate = this.bitrate;
        didl_resource.bits_per_sample = this.bits_per_sample;
        didl_resource.color_depth = this.color_depth;
        didl_resource.width = this.width;
        didl_resource.height = this.height;
        didl_resource.audio_channels = this.audio_channels;
        didl_resource.sample_freq = this.sample_freq;
        didl_resource.protocol_info = this.get_protocol_info ();

        return didl_resource;
    }

    public void set_protocol_info (ProtocolInfo pi) {
        this.protocol = pi.protocol;
        this.network = pi.network;
        this.mime_type = pi.mime_type;
        this.dlna_profile = pi.dlna_profile;
        this.dlna_conversion = pi.dlna_conversion;
        this.dlna_operation = pi.dlna_operation;
        this.dlna_flags = pi.dlna_flags;
        this.play_speeds = copy_speeds (pi.play_speeds);
    }

    public ProtocolInfo get_protocol_info () {
        var new_pi = new ProtocolInfo ();

        new_pi.protocol = this.protocol;
        new_pi.network = this.network;
        new_pi.mime_type = this.mime_type;
        new_pi.dlna_profile = this.dlna_profile;
        new_pi.dlna_conversion = this.dlna_conversion;
        new_pi.dlna_operation = this.dlna_operation;
        new_pi.dlna_flags = this.dlna_flags;
        // ProtocolInfo doesn't like having play_speeds set to null
        if (this.play_speeds != null) {
            new_pi.play_speeds = copy_speeds (this.play_speeds);
        }

        return new_pi;
    }

    public bool supports_arbitrary_byte_seek () {
        return is_dlna_operation_mode_set (DLNAOperation.RANGE);
    }

    public bool supports_arbitrary_time_seek () {
        return is_dlna_operation_mode_set (DLNAOperation.TIMESEEK);
    }

    public bool supports_limited_byte_seek () {
        return is_dlna_protocol_flag_set (DLNAFlags.BYTE_BASED_SEEK);
    }

    public bool supports_limited_time_seek () {
        return is_dlna_protocol_flag_set (DLNAFlags.TIME_BASED_SEEK);
    }

    public bool supports_limited_cleartext_byte_seek () {
        return is_dlna_protocol_flag_set (DLNAFlags.LOP_CLEARTEXT_BYTESEEK);
    }

    public bool supports_full_cleartext_byte_seek () {
        return is_dlna_protocol_flag_set (DLNAFlags.CLEARTEXT_BYTESEEK_FULL);
    }

    public bool is_link_protection_enabled () {
        return is_dlna_protocol_flag_set (DLNAFlags.LINK_PROTECTED_CONTENT);
    }

    public bool is_dlna_content () {
        return (this.dlna_profile != null);
    }

    public string get_default_transfer_mode () {
        if (is_dlna_protocol_flag_set (DLNAFlags.STREAMING_TRANSFER_MODE)) {
            return "Streaming";
        } else {
            return "Interactive";
        }
    }

    public bool supports_transfer_mode (string transfer_mode) {
        if (!this.is_dlna_content ()) {
            return true;
        }

        switch (transfer_mode) {
            case "Streaming" :
                return is_dlna_protocol_flag_set (DLNAFlags.STREAMING_TRANSFER_MODE);
            case "Interactive" :
                return is_dlna_protocol_flag_set (DLNAFlags.INTERACTIVE_TRANSFER_MODE);
            case "Background" :
                return is_dlna_protocol_flag_set (DLNAFlags.BACKGROUND_TRANSFER_MODE);
            default:
                return false;
        }
    }

    public bool is_streamable () {
        return is_dlna_protocol_flag_set (DLNAFlags.STREAMING_TRANSFER_MODE);
    }

    // This is to check if any of the cleartext byte seek operations are supported.
    public bool is_cleartext_range_support_enabled () {
        return ( is_dlna_protocol_flag_set (DLNAFlags.CLEARTEXT_BYTESEEK_FULL
                                            | DLNAFlags.LOP_CLEARTEXT_BYTESEEK) );
    }

    public bool supports_playspeed () {
        return (this.play_speeds.length > 0);
    }

    public bool is_dlna_protocol_flag_set (long flags) {
        return ((this.dlna_flags & flags) != 0);
    }

    public bool is_dlna_operation_mode_set (long flags) {
        return ((this.dlna_operation & flags) != 0);
    }

    public string to_string () {
        var strbuf = new StringBuilder ();
        strbuf.append (name).append_unichar ('(');
        if (this.size >= 0) {
            strbuf.append ("size ").append (this.size.to_string ())
                  .append_unichar (',');
        }
        if (this.cleartext_size >= 0) {
            strbuf.append ("cleartextsize ").append (this.cleartext_size.to_string ())
                  .append_unichar (',');
        }
        if (this.duration >= 0) {
            strbuf.append ("duration ").append (this.duration.to_string ())
                  .append_unichar (',');
        }
        if (this.bitrate >= 0) {
            strbuf.append ("bitrate ").append (this.bitrate.to_string ())
                  .append_unichar (',');
        }
        if (this.bits_per_sample >= 0) {
            strbuf.append ("bits_per_sample ").append (this.bits_per_sample.to_string ())
                  .append_unichar (',');
        }
        if (this.width >= 0) {
            strbuf.append ("width ").append (this.width.to_string ())
                  .append_unichar (',');
        }
        if (this.height >= 0) {
            strbuf.append ("height ").append (this.height.to_string ())
                  .append_unichar (',');
        }
        if (this.color_depth >= 0) {
            strbuf.append ("color_depth ").append (this.color_depth.to_string ())
                  .append_unichar (',');
        }
        if (this.audio_channels >= 0) {
            strbuf.append ("audio_channels ").append (this.audio_channels.to_string ())
                  .append_unichar (',');
        }
        if (this.sample_freq >= 0) {
            strbuf.append ("sample_freq ").append (this.sample_freq.to_string ())
                  .append_unichar (',');
        }
        if (this.network != null) {
            strbuf.append ("network ").append (this.network).append_unichar (',');
        }
        strbuf.append ("protocol ")
              .append (this.protocol == null ? "null" : this.protocol)
              .append_unichar (',');
        strbuf.append ("mime_type ")
              .append (this.mime_type == null ? "null" : this.mime_type)
              .append_unichar (',');
        strbuf.append ("dlna_profile ")
              .append (this.dlna_profile == null ? "null" : this.dlna_profile)
              .append_unichar (',');
        strbuf.append_printf ("dlna_flags %.8X,", this.dlna_flags);
        if (this.dlna_conversion != DLNAConversion.NONE) {
            strbuf.append_printf ("dlna_conversion %1d,", this.dlna_conversion);
        }
        if (this.dlna_operation != DLNAOperation.NONE) {
            strbuf.append_printf ("dlna_operation %.2X,", this.dlna_operation);
        }
        if (this.play_speeds != null) {
            strbuf.append ("play_speeds [");
            foreach (var speed in this.play_speeds) {
                strbuf.append (speed).append_unichar (',');
            }
            strbuf.overwrite (strbuf.len-1,"]"); // Replace comma
        }
        strbuf.append (",uri ").append (this.uri == null ? "null" : this.uri);
        strbuf.append_unichar (')');

        return strbuf.str;
    }
}
