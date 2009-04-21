using Rygel;
using GUPnP;

[ModuleInit]
public Plugin load_plugin() {
    Plugin plugin = new Plugin("ZDFMediathek");

    var resource_info = new ResourceInfo (ContentDirectory.UPNP_ID,
                                          ContentDirectory.UPNP_TYPE,
                                          ContentDirectory.DESCRIPTION_PATH,
                                          typeof (ZdfMediathek.ZdfContentDir));

    plugin.add_resource (resource_info);

    return plugin;
}

public class ZdfMediathek.ZdfContentDir : ContentDirectory {
    public override MediaContainer? create_root_container () {
        return new ZdfRootContainer ();
    }
}



