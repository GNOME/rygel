// SPDX-License-Identifier: LGPL-2.1-or-later
// SPDX-FileCopyrightText: 2023 Jens Georg <mail@jensge.org>

internal class Rygel.AgentMatcher : Object {
    public Gee.ArrayList<string> agents { get; construct; }
    public string name{get; construct; }
    public Regex agent_regex {get; private set; }

    private string agent_pattern;

    private const string MATCHING_PATTERN = ".*%s.*";

    public AgentMatcher (string name, Gee.ArrayList<string> agents) {
        Object(agents: agents, name: name);
    }

    public override void constructed () {
        if (base.constructed != null) {
            base.constructed();
        }

        var agents_with_pattern = new string[0];
        foreach (var agent in agents) {
            agents_with_pattern += MATCHING_PATTERN.printf
                                    (Regex.escape_string (agent));
        }

        if (agents_with_pattern.length > 0) {
            agent_pattern = string.joinv ("|", agents_with_pattern);
        } else {
            agent_pattern = "";
        }

        debug ("Agent matcher configured for matching %s",
               agent_pattern);

        try {
            agent_regex = new Regex(agent_pattern);
        } catch (Error e) {
            critical("Error generating UserAgent regex: %s, Must not be reached", e.message);
            assert_not_reached();
        }
    }

    public bool empty () {
        return agent_pattern == "";
    }

    public bool matches (string header) {
        return agent_regex.match(header);
    }
}