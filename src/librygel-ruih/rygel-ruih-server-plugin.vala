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
 */

/**
 * This is the base class for every Rygel UPnP Ruih plugin.
 *
 * This class is useful when implementing Rygel Ruih Server plugins.
 *
 */
public class Rygel.RuihServerPlugin : Rygel.Plugin {
    private static const string RUIH_SERVER_DESC_PATH =
                                BuildConfig.DATA_DIR +
                                "/xml/RuihServer2.xml";
    private static const string RUIH = "urn:schemas-upnp-org:device:RemoteUIServer";


    /**
     * Create an instance of the plugin.
     *
     * @param name The non-human-readable name for the plugin, used in UPnP messages and in the Rygel configuration file.
     * @param title An optional human-readable name (friendlyName) of the UPnP renderer provided by the plugin. If the title is empty then the name will be used.
     * @param description An optional human-readable description (modelDescription) of the UPnP renderer provided by the plugin.
     */
    public RuihServerPlugin (string  name,
                                string? title,
                                string? description = null,
                                PluginCapabilities capabilities =
                                        PluginCapabilities.NONE) {
        Object (desc_path : RUIH_SERVER_DESC_PATH,
                name : name,
                title : title,
                description : description,
                capabilities : capabilities);
    }

    public override void constructed () {
        base.constructed ();

        var resource = new ResourceInfo (RuihService.UPNP_ID,
                                         RuihService.UPNP_TYPE,
                                         RuihService.DESCRIPTION_PATH,
                                         typeof (RuihService));
        this.add_resource (resource);
    }
}
