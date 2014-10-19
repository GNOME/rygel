/*
 * Copyright (C) 2013  Cable Television Laboratories, Inc.
 * Contact: http://www.cablelabs.com/
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
 *
 * Author: Neha Shanbhag <N.Shanbhag@cablelabs.com>
 */

using GUPnP;
using Gee;

/**
 * Basic implementation of UPnP RemoteUIServer service version 1.
 */
internal class Rygel.RuihService: Service {
    public const string UPNP_ID =
                     "urn:upnp-org:serviceId:RemoteUIServer";
    public const string UPNP_TYPE =
                    "urn:schemas-upnp-org:service:RemoteUIServer:1";
    public const string DESCRIPTION_PATH =
                    "xml/RemoteUIServerService.xml";

    public override void constructed () {
        base.constructed ();

        this.query_variable["UIListingUpdate"].connect
                                        (this.query_ui_listing);

        this.action_invoked["GetCompatibleUIs"].connect
                                        (this.get_compatible_uis_cb);
    }

    /* Browse action implementation */
    private void get_compatible_uis_cb (Service       content_dir,
                                        ServiceAction action) {

        string input_device_profile, input_ui_filter;
        action.get ("InputDeviceProfile",
                        typeof (string),
                        out input_device_profile);
        action.get ("UIFilter", typeof (string), out input_ui_filter);

        try {
            var manager = RuihServiceManager.get_default ();
            var compat_ui = manager.get_compatible_uis (input_device_profile,
                                                        input_ui_filter);

            action.set ("UIListing", typeof (string), compat_ui);
            action.return ();
        } catch (RuihServiceError e) {
            action.return_error (e.code, e.message);
        }
    }

    private void query_ui_listing (Service        ruih_service,
                                   string         variable,
                                   ref GLib.Value value) {
        value.init (typeof (string));
        value.set_string ("");
    }
}
