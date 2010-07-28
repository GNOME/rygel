/*
 * Copyright (C) 2010 Jens Georg <mail@jensge.org>.
 *
 * This file is part of Rygel.
 *
 * Rygel is free software; you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * Rygel is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program; if not, write to the Free Software Foundation,
 * Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
 */
using Gee;

internal class Rygel.MediaExport.Harvester : GLib.Object {
    private HashMap<File, HarvestingTask> tasks;
    private ArrayList<HarvestingTask> trash;
    private MetadataExtractor extractor;
    private RecursiveFileMonitor monitor;

    public Harvester (MetadataExtractor    extractor,
                      RecursiveFileMonitor monitor) {
        this.extractor = extractor;
        this.monitor = monitor;
        this.tasks = new HashMap<File, HarvestingTask> (file_hash, file_equal);
        this.trash = new ArrayList<HarvestingTask> ();
    }

    public void schedule (File           file,
                           MediaContainer parent,
                           string?        flag   = null) {
        if (this.extractor == null) {
            warning (_("No Metadata extractor available. Will not crawl"));

            return;
        }

        // Cancel currently running harvester
        this.cancel (file);

        var task = new HarvestingTask (this.extractor,
                                       this.monitor,
                                       file,
                                       parent,
                                       flag);
        task.completed.connect (this.on_file_harvested);
        this.tasks[file] = task;
        task.run ();
    }

    public void cancel (File file) {
        if (this.tasks.contains (file)) {
            var task = this.tasks[file];
            task.completed.disconnect (this.on_file_harvested);
            this.tasks.remove (file);
            task.cancellable.cancel ();
            task.completed.connect (this.on_remove_cancelled_harvester);
            this.trash.add (task);
        }
    }

    private void on_file_harvested (StateMachine state_machine) {
        var task = state_machine as HarvestingTask;
        var file = task.origin;
        message (_("'%s' harvested"), file.get_uri ());

        this.tasks.remove (file);
    }

    private void on_remove_cancelled_harvester (StateMachine state_machine) {
        this.trash.remove (state_machine as HarvestingTask);
    }
}
