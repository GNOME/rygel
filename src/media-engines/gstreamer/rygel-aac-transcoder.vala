/*
 * Copyright (C) 2011 Nokia Corporation.
 * Copyright (C) 2013 Cable Television Laboratories, Inc.
 *
 * Author: Luis de Bethencourt <luis.debethencourt@collabora.com>
 *         Prasanna Modem <prasanna@ecaspia.com>
 *
 * This file is part of Rygel.
 *
 * Rygel is free software; you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * Rygel is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA
 */

/**
 * Transcoder for 3GP stream containing MPEG4 audio (AAC).
 */
internal class Rygel.AACTranscoder : Rygel.AudioTranscoder {
    private const int BITRATE = 256;
    // FIXME: This basically forces GstFaac. The proper way would be
    // stream-format=raw and have aacparse transform the stream to ADTS which
    // isn't possible with encodebin
    private const string CODEC = "audio/mpeg,mpegversion=4," +
                                 "stream-format=adts,rate=44100,base-profile=lc";

    private const string NAME = "AAC_ADTS_320";
    public AACTranscoder () {
        base (NAME, "audio/vnd.dlna.adts", NAME, BITRATE, null, CODEC, "adts");
        this.preset = "Rygel AAC_ADTS_320 preset";
    }
}
