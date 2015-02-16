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

public class Rygel.DTCPCleartextResponse : Rygel.HTTPResponseElement {
    public static const string DTCP_CONTENT_RANGE_HEADER = "Content-Range.dtcp.com";

    /**
     * The start of the response range in bytes
     */
    public int64 start_byte { get; private set; }

    /**
     * The end of the range in bytes (inclusive)
     */
    public int64 end_byte { get; private set; }

    /**
     * The length of the range in bytes
     */
    public int64 range_length { get; private set; }

    /**
     * The length of the resource in bytes. May be HTTPSeekRequest.UNSPECIFIED
     */
    public int64 total_size { get; private set; }

    /**
     * The encrypted length of the response
     */
    public int64 encrypted_length { get; public set;}

    public DTCPCleartextResponse (int64 start_byte, int64 end_byte, int64 total_size,
                                  int64 encrypted_length = UNSPECIFIED) {
        this.start_byte = start_byte;
        this.end_byte = end_byte;
        this.range_length = end_byte - start_byte + 1; // +1, since range is inclusive
        this.total_size = total_size;
        this.encrypted_length = encrypted_length;
    }

    public DTCPCleartextResponse.from_request (DTCPCleartextRequest request,
                                               int64 encrypted_length = UNSPECIFIED) {
        this.start_byte = request.start_byte;
        this.end_byte = request.end_byte;
        this.range_length = request.range_length;
        this.total_size = request.total_size;
        this.encrypted_length = encrypted_length;
    }

    public override void add_response_headers (Rygel.HTTPRequest request) {
        // Content-Range.dtcp.com: bytes START_BYTE-END_BYTE/TOTAL_LENGTH (or "*")
        if (this.start_byte != UNSPECIFIED) {
            string response = "bytes " + this.start_byte.to_string ()
                              + "-" + this.end_byte.to_string () + "/"
                              + ( (this.total_size == UNSPECIFIED) ? "*"
                                  : this.total_size.to_string () );

            request.msg.response_headers.append (DTCP_CONTENT_RANGE_HEADER, response);
        }
        if (this.encrypted_length != UNSPECIFIED) {
            request.msg.response_headers.set_content_length (this.encrypted_length);
        }
    }

    public override string to_string () {
        return ("DTCPCleartextResponse(bytes=%lld-%lld/%lld, enc_len=%lld)"
                .printf (this.start_byte, this.end_byte, this.total_size, this.encrypted_length));
    }
}
