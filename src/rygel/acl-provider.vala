
public class Rygel.AclProvider : DBusAclProvider, Object {
    public async bool is_allowed (GLib.HashTable<string, string> device,
                                  GLib.HashTable<string, string> service,
                                  string path,
                                  string address,
                                  string? agent)
                                  throws DBusError, IOError {

        Idle.add (() => { is_allowed.callback (); return false; });
        yield;


        if (device.size () == 0 || service.size () == 0) {
            message ("Nothing to decide on, passing true");

            return true;
        }

        message ("%s from %s is trying to access %s. Allow?",
                 agent, address, device["FriendlyName"]);

        if (path.has_prefix ("/Event")) {
            message ("Trying to subscribe to events of %s on %s",
                     service["Type"], device["FriendlyName"]);
        } else if (path.has_prefix ("/Control")) {
            message ("Trying to access control of %s on %s",
                     service["Type"], device["FriendlyName"]);
        } else {
            return true;
        }

        return true;
    }

    private void on_bus_aquired (DBusConnection connection) {
        try {
            debug ("Trying to register ourselves at path %s",
                   DBusAclProvider.OBJECT_PATH);
            connection.register_object (DBusAclProvider.OBJECT_PATH,
                                        this as DBusAclProvider);
            debug ("Success.");
        } catch (IOError error) {
            warning (_("Failed to register service: %s"), error.message);
        }
    }

    public void register () {
        debug ("Trying to aquire name %s on session DBus",
               DBusAclProvider.SERVICE_NAME);
        Bus.own_name (BusType.SESSION,
                      DBusAclProvider.SERVICE_NAME,
                      BusNameOwnerFlags.NONE,
                      this.on_bus_aquired,
                      () => {},
                      () => { warning (_("Could not aquire bus name %s"),
                                       DBusAclProvider.SERVICE_NAME);
                      });
    }

    public int run () {
        message (_("Rygel ACL Provider v%s starting."),
                 BuildConfig.PACKAGE_VERSION);
        MainLoop loop = new MainLoop ();
        this.register ();
        loop.run ();
        message (_("Rygel ACL Provider done."));

        return 0;
    }

    public static int main (string[] args) {
        return new AclProvider().run();
    }
}
