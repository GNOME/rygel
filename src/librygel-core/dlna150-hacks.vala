// SPDX-License-Identifier: LGPL-2.1-or-later
// SPDX-FileCopyrightText: 2023 Jens Georg <mail@jensge.org>

public class Rygel.Dlna150Hacks : Object {
    public string description_path;
    
    private static AgentMatcher agent_matcher;

    private const string[] AGENTS = { "Dart" };

    private const string X_DLNADOC_MDMS_XPATH = "//*[local-name()='X_DLNADOC'"+
                                                 " and contains(.,\"M-DMS-1.51\")]";
    private const string X_DLNADOC_DMS_XPATH = "//*[local-name()='X_DLNADOC'"+
                                                 " and contains(.,\"DMS-1.51\")]";
    private const string X_DLNADOC_MDMR_XPATH = "//*[local-name()='X_DLNADOC'"+
                                                 " and contains(.,\"M-DMR-1.51\")]";
    private const string X_DLNADOC_DMR_XPATH = "//*[local-name()='X_DLNADOC'"+
                                                 " and contains(.,\"DMR-1.51\")]";

    public override void constructed () {
        base.constructed ();

        if (Dlna150Hacks.agent_matcher == null) {
            var defaults = new Gee.ArrayList<string>.wrap (AGENTS, (Gee.EqualDataFunc<string>?)str_equal);
            var config = MetaConfig.get_default ();
            var agents = config.get_string_list_with_default ("general", "force-downgrade-for", defaults);
            agent_matcher = new AgentMatcher ("V1 hacks", agents);
        }
    }

    public void apply_on_device (RootDevice device,
                                 string? template_path) throws Error {
        if (template_path == null) {
            return;
        }

        var file = File.new_for_path (template_path);
        uint8[] contents;
        file.load_contents (null, out contents, null);
        unowned string data = (string)contents;
        var patched_contents = data.replace ("-1.51", "-1.50");

        this.description_path = template_path.replace (".xml", "-dlna150.xml");
        var description_file = File.new_for_path (this.description_path);
        description_file.replace_contents (patched_contents.data, null, false, FileCreateFlags.REPLACE_DESTINATION, null);

        var server_path = "/" + device.get_description_document_name ();
        if (!Dlna150Hacks.agent_matcher.empty ()) {
            device.context.host_path_for_agent (this.description_path,
                                                server_path,
                                                Dlna150Hacks.agent_matcher.agent_regex);
        }
    }
}