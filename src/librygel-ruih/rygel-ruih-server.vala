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

internal class Plugin : Rygel.RuihServerPlugin {
    public Plugin (Rygel.PluginCapabilities capabilities) {
        base ("LibRygelRuih", "LibRygelRuih", null, capabilities);
    }
}

/**
 * This class may be used to implement in-process UPnP RUIH servers.
 *
 * Call rygel_media_device_add_interface () on the RygelRuihServer to allow it
 * to serve requests via that network interface.
 *
 */
public class Rygel.RuihServer : MediaDevice {

    /**
     * Create a RuihServer to serve the UIs.
     */
    public RuihServer (string title,
                        PluginCapabilities capabilities =
                                        PluginCapabilities.NONE) {
        Object (title: title,
                capabilities: capabilities);
    }

    public override void constructed () {
        base.constructed ();

        if (this.plugin == null) {
            this.plugin = new global::Plugin (this.capabilities);
        }
        this.plugin.title = this.title;
    }
}
