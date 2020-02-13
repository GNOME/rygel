/*
 * Copyright (C) 2012 Intel Corporation.
 *
 * Author: Jens Georg <jensg@openismus.com>
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
 * Load a media engine.
 */
internal class Rygel.EngineLoader : RecursiveModuleLoader {
    private delegate MediaEngine ModuleInstanceFunc ();
    private MediaEngine instance;
    private string engine_name;

    public EngineLoader () {
        Object (base_path : get_config ());
    }

    public override void constructed () {
        base.constructed ();

        if (this.base_path == null) {
            this.base_path = get_config ();
        }

        try {
            var config = MetaConfig.get_default ();
            this.engine_name = config.get_media_engine ();
            debug ("Looking for specific engine named '%s",
                   this.engine_name);
        } catch (Error error) {}
    }

    /**
     * Load a media engine.
     */
    public MediaEngine load_engine () {
        this.load_modules_sync ();

        return instance;
    }

    protected override bool load_module_from_file (File file) {
        if (this.engine_name != null) {
            if (file.get_basename () != this.engine_name) {
                return true;
            }
        }

#if VALA_0_46
        var module = Module.open (file.get_path (), ModuleFlags.LOCAL);
#else
        var module = Module.open (file.get_path (), ModuleFlags.BIND_LOCAL);
#endif
        if (module == null) {
            debug ("Failed to load engine %s: %s",
                   file.get_path (),
                   Module.error ());
            if (this.engine_name != null) {
                // If engine name is not null, we only got here because the
                // names match. If we couldn't load the engine that matches,
                // we stop loading.
                return false;
            }

            return true;
        }

        void* function;
        if (!module.symbol ("module_get_instance", out function)) {
            if (this.engine_name != null) {
                // If engine name is not null, we only got here because the
                // names match. If we couldn't load the engine that matches,
                // we stop loading.
                return false;
            }

            return true;
        }

        unowned ModuleInstanceFunc get_instance =
                                    (ModuleInstanceFunc) function;
        module.make_resident ();
        this.instance = get_instance ();

        return false;
    }

    protected override bool load_module_from_info (PluginInformation info) {
        return load_module_from_file (File.new_for_path (info.module_path));
    }

    private static string get_config () {
        var path = BuildConfig.ENGINE_DIR;
        var config = MetaConfig.get_default ();
        try {
            path = config.get_engine_path ();
        } catch (Error error) { }

        return path;
    }
}
