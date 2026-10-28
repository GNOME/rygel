RYGEL_IFACE
    Set the network interfaces to bind to.

RYGEL_PORT
    Define the network port to bind to.

RYGEL_DISABLE_TRANSCODING
    Disable transcoding globally.

RYGEL_LOG
    Set the log level of rygel.

RYGEL_PLUGIN_PATH
    Set the plugin search path of rygel.

RYGEL_ENGINE_PATH
    Set the media streaming and transcoding engine search path for rygel.

RYGEL_MEDIA_ENGINE
    Set a specific media streaming engine to pick up from the media engine search path.

RYGEL_DISABLE_UPLOAD
    Disable media file upload via UPnP.

RYGEL_DISABLE_DELETION
    Disable remote file deletion via UPnP.

RYGEL_PLUGIN_TIMEOUT
    Set the time-out for finding the plugins. Useful to increase when running inside valgrind.

RYGEL_DATABASE_DEBUG
    If set to 1, the database library will print the used SQL statements.

Also for every plugin you can set the following environment variables:

RYGEL_PLUGIN_NAME_TITLE
    Set the title of the plugin.

RYGEL_PLUGIN_NAME_ENABLED
    Enable or disable the plugin.
