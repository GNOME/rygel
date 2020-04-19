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
    try {
        var config = new Rygel.UserConfig.with_paths (
            "data/plugin-loader/conflicts/test.conf",
            "data/plugin-loader/conflicts/test.conf");
        Rygel.MetaConfig.register_configuration (config);
    } catch (Error error) {
        critical("%s", error.message);
        assert_not_reached ();
    }

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