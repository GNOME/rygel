/*
 * Copyright (C) 2013 Intel Corporation.
 *
 * Author: Christophe Guiraud,
 *         Jussi Kukkonen
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

using GLib;

internal abstract class Rygel.BasicManagementTest : Object, StateMachine {
    protected Cancellable _cancellable;
    public Cancellable cancellable {
        get {
            return this._cancellable;
        }
        set {
            this._cancellable = value;
            this._cancellable.cancelled.connect (() => {
                if (this.execution_state == ExecutionState.IN_PROGRESS) {
                    Posix.killpg (this.child_pid, ProcessSignal.TERM);
                    this.execution_state = ExecutionState.CANCELED;
                }
            });
        }
    }

    protected enum InitState {
        OK,
        SPAWN_FAILED,
        INVALID_PARAMETER,
    }
    protected InitState init_state;

    public enum ExecutionState {
        REQUESTED,
        IN_PROGRESS,
        COMPLETED,
        CANCELED;

        /* Return values fit for A_ARG_TYPE_TestState */
        public string to_string () {
            switch (this) {
                case REQUESTED:
                    return "Requested";
                case IN_PROGRESS:
                    return "InProgress";
                case COMPLETED:
                    return "Completed";
                case CANCELED:
                    return "Canceled";
                default:
                    assert_not_reached ();
            }
        }
    }

    public ExecutionState execution_state {
        get;
        protected set;
        default = ExecutionState.REQUESTED;
    }
    public string id;

    /* properties implementations need to provide */
    public abstract string method_type { get; }
    public abstract string results_type { get; }

    /* properties for implementations to access */
    protected uint iterations;
    protected SpawnFlags flags = SpawnFlags.SEARCH_PATH |
                                 SpawnFlags.LEAVE_DESCRIPTORS_OPEN;
    protected string[] command;

    private uint eof_count;
    private int std_out;
    private int std_err;
    private Pid child_pid;
    private SourceFunc async_callback;
    private uint current_iteration;

    /* These virtual/abstract functions will be called from run ():
     * - For every iteration:
     *    - init_iteration()
     *    - calls to handle_output() and handle_error(),
     *    - finish_iteration()
     */
    protected virtual void init_iteration () {}
    protected virtual void handle_output (string line) {}
    protected virtual void handle_error (string line) {
        debug ("%s stderr: %s", command[0], line);
    }
    protected virtual bool finish_iteration () {
        this.current_iteration++;

        /* No more iterations if
         *  - init failed, recovery is impossible or
         *  - execution has been canceled,
         *  - execution has ended prematurely (skip remaining iterations),
         *  - the specified nr of iterations have been executed already
         */
        if (this.init_state != InitState.OK ||
            (this.current_iteration >= this.iterations &&
             this.execution_state == ExecutionState.IN_PROGRESS)) {
            this.execution_state = ExecutionState.COMPLETED;
        }

        if (this.execution_state != ExecutionState.IN_PROGRESS) {
            this.async_callback ();
        } else {
            this.run_iteration ();
        }

        return false;
    }

    private void child_setup () {
        /* try to prevent possible changes in output */
        Environment.set_variable ("LC_MESSAGES", "C", true);

        /* Create new session to detach from tty, but set a process
         * group so all children can be ḱilled if need be */
        Posix.setsid ();
        Posix.setpgid (0, 0);
    }

    private void run_iteration () {
        this.init_iteration ();

        /*if we failed to initialize, skip spawning */
        if (this.init_state != InitState.OK) {
            Idle.add (this.finish_iteration);

            return;
        }

        try {

            this.eof_count = 0;
            Process.spawn_async_with_pipes (null,
                                            this.command,
                                            null,
                                            this.flags,
                                            this.child_setup,
                                            out this.child_pid,
                                            null,
                                            out this.std_out,
                                            out this.std_err);

            var out_channel = new IOChannel.unix_new (std_out);
            out_channel.add_watch (IOCondition.OUT | IOCondition.HUP,
                                   this.out_watch);

            var err_channel = new IOChannel.unix_new (std_err);
            err_channel.add_watch (IOCondition.OUT | IOCondition.HUP,
                                   this.err_watch);
        } catch (SpawnError e) {
            /* Let the async function yeild, then let the Test
             * implementation handle this in finish_iteration */
            this.init_state = InitState.SPAWN_FAILED;
            Idle.add (this.finish_iteration);
        }
    }

    private bool out_watch (IOChannel channel, IOCondition condition) {
        try {
            string line;
            IOStatus status = channel.read_line (out line, null, null);
            if (line != null) {
                this.handle_output (line);
            }

            if (status == IOStatus.EOF) {
                this.eof_count++;
                if (this.eof_count > 1) {
                    this.finish_iteration ();
                }

                return false;
            }
        } catch (Error e) {
            warning (_("Failed to read standard output from %s: %s"),
                     this.method_type,
                     e.message);
            this.finish_iteration ();

            return false;
        }

        return true;
    }

    private bool err_watch (IOChannel channel, IOCondition condition) {
        try {
            string line;
            IOStatus status = channel.read_line (out line, null, null);
            if (line != null) {
                this.handle_error (line);
            }

            if (status == IOStatus.EOF) {
                this.eof_count++;
                if (this.eof_count > 1) {
                    this.finish_iteration ();
                }

                return false;
            }
        } catch (Error e) {
            warning (_("Failed to read error output from %s: %s"),
                     this.method_type,
                     e.message);
            this.finish_iteration ();

            return false;
        }

        return true;
    }

    public bool is_active () {
        return this.execution_state == ExecutionState.REQUESTED ||
               this.execution_state == ExecutionState.IN_PROGRESS;
    }

    public async virtual void run () {
        if (this.execution_state != ExecutionState.REQUESTED) {
            debug ("Not running test: already started");

            return;
        }
        if (this.cancellable == null) {
            this.cancellable = new Cancellable ();
        }
        this.execution_state = ExecutionState.IN_PROGRESS;
        this.current_iteration = 0;
        this.async_callback = run.callback;

        this.run_iteration ();
        yield;

        this.completed ();
    }
}
