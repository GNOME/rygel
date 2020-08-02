class TestConfig : Rygel.BaseConfiguration {
    public HashTable<string, bool> enable = new HashTable<string, bool> (str_hash, str_equal);

    public void toggle_enable (string module) {
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

void
test_meta_config_single_instance ()
{
    var instance_a = Rygel.MetaConfig.get_default ();
    var instance_b = Rygel.MetaConfig.get_default ();

    assert (instance_a == instance_b);
    Rygel.MetaConfig.cleanup ();
}

const string SECTION_A = "Tracker";
const string SECTION_B = "SomePlugin";

void
test_meta_config_overrides () {

    var first_config = new TestConfig ();
    first_config.enable[SECTION_A] = true;

    Rygel.MetaConfig.register_configuration (first_config);

    var second_config = new TestConfig ();
    second_config.enable[SECTION_A] = false;
    second_config.enable[SECTION_B] = true;

    Rygel.MetaConfig.register_configuration (second_config);

    var instance = Rygel.MetaConfig.get_default ();

    // Check that signalling a change for a value that only exists
    // on lower priority will trigger a signal on the MetaConfig
    try {
        assert_true (instance.get_enabled (SECTION_A));
        assert_true (instance.get_enabled (SECTION_B));
    } catch (Error e) {
        assert_not_reached ();
    }

    var id = instance.section_changed.connect ((section, entry) => {
        assert_true (section == SECTION_B);
        assert_true (entry == Rygel.SectionEntry.ENABLED);
        try {
            assert_false (instance.get_enabled (section));
        } catch (Error e) {
            assert_not_reached ();
        }
    });

    second_config.toggle_enable (SECTION_B);
    instance.disconnect (id);

    // Check that changing a value on a lower priority will not
    // propagated up if there is a value with higher priority
    id = instance.section_changed.connect ((section, entry) => {
        assert_not_reached ();
    });
    second_config.toggle_enable (SECTION_A);
    instance.disconnect (id);

    // Check that changing a value on a higher priority will be
    // propagated up
    id = instance.section_changed.connect ((section, entry) => {
        assert_true (section == SECTION_A);
        assert_true (entry == Rygel.SectionEntry.ENABLED);
        try {
            assert_false (instance.get_enabled (section));
        } catch (Error error) {
            assert_not_reached ();
        }
    });
    first_config.toggle_enable (SECTION_A);
    instance.disconnect (id);

    Rygel.MetaConfig.cleanup ();
}

int main(string[] args) {
    Test.init (ref args);

    Test.add_func ("/librygel-core/meta-config/single-instance",
                   test_meta_config_single_instance);

    Test.add_func ("/librygel-core/meta-config/overrides",
                   test_meta_config_overrides);

    return Test.run ();
}
