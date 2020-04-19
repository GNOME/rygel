class TestConfig : Rygel.BaseConfiguration {
    public HashTable<string, bool> enable = new HashTable<string, bool> (str_hash, str_equal);

    public void toggl_enable (string module) {
        enable[module] = !enable[module];
        this.section_changed (module, Rygel.SectionEntry.ENABLED);
    }

    public override bool get_enabled(string module) throws Error {
        if (module in this.enable) {
            return this.enable[module];
        }

        throw new Rygel.ConfigurationError.NO_VALUE_SET ("Should not happen");
    }
}

class TestPluginLoader : Rygel.PluginLoader {
    private string[] expected_plugins;
    private string[] forbidden_plugins;
    public string[] loaded_plugins;

    public TestPluginLoader(string testset_location,
                            string[] expected_plugins,
                            string[] forbidden_plugins) {
        Object(base_path : "data/plugin-loader/" + testset_location);
        this.forbidden_plugins = forbidden_plugins;
        this.expected_plugins = expected_plugins;
        this.loaded_plugins = new string[0];
    }

    protected override bool load_module_from_file (File module) {
        assert (module.get_basename () in expected_plugins);
        assert (!(module.get_basename () in forbidden_plugins));

        loaded_plugins += module.get_basename ();

        // Just do nothing
        return true;
    }
}

void test_plugin_loader_conflict () {
    var config = new TestConfig ();
    config.enable["Tracker"] = true;
    config.enable["Tracker3"] = true;
    config.enable["SomePlugin"] = true;
    Rygel.MetaConfig.register_configuration (config);

    var loader = new TestPluginLoader("conflicts",
                                      {"librygel-tracker.so", "librygel-no-conflict.so"},
                                      {"librygel-tracker3.so"});
    loader.load_modules_sync (null);
    assert (loader.loaded_plugins.length == 2);
    assert ("librygel-tracker.so" in loader.loaded_plugins);
    assert ("librygel-no-conflict.so" in loader.loaded_plugins);
}

int main (string[] args) {
    Test.init (ref args);

    Test.add_func ("/librygel-core/plugins/load-conflict",
                   test_plugin_loader_conflict);
    return Test.run ();
}