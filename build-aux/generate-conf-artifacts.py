#!/usr/bin/python3
# SPDX-License-Identifier: LGPL-2.1-or-later
# SPDX-FileCopyrightText: 2025 Jens Georg <mail@jensge.org>

import typing
import yaml
import argparse
import textwrap
import re
import sys

admonition_map = {"Note" : ".. note::", "Warning" : '.. warning::', "Example" : '.. example::'}
admonition_regex = re.compile(r'%%(\w+): ')

def reflow_text(raw_description: str, width: int = 80, strip: bool = False) -> str:
    paragraphs = []
    if strip:
        raw_description = raw_description.replace("``", "")
        raw_description = raw_description.replace("%%", "")
    for paragraph in re.split(r"\n\n", raw_description):
        paragraphs.append(textwrap.fill(paragraph, width))

    return "\n\n".join(paragraphs)


def comment_text(raw_text: str, width: int = 80, strip: bool = False) -> str:
    return textwrap.indent(reflow_text(raw_text, 78, strip), "# ", lambda line: True)

def indent_text(raw_text: str, level: int = 0, maxwidth: int = 80, strip: bool = False) -> str:
    return textwrap.indent(reflow_text(raw_text, maxwidth - level * 4, strip),  " " * level * 4, lambda line: True)


def render_example_conf(config, output):
    print("# Rygel default configuration\n", file=output)
    # generate the example documentation
    for section_number, section in enumerate(config):
        if section_number > 0:
            print(f'\n{"#" * 80}', file=output)

        if "description" in section:
            raw_description = section["description"]
            if "display_name" in section:
                raw_description = section["display_name"] + "\n\n" + raw_description

            description = comment_text(raw_description, width=80, strip=True)
            print(description, file=output)
            print(file=output)

        if len(section["name"]) > 0:
            if "comment" in section and section["comment"]:
                print(comment_text(f"[{section['name']}]"), file=output)
            else:
                print(f"[{section['name']}]", file=output)
        for index, value in enumerate(section["values"]):
            if index > 0:
                print(file=output)

            if "only-in" in value and "conf" not in value["only-in"]:
                continue

            if "description" in value:
                print(f"{comment_text(value['description'], strip=True)}", file=output)
            if "comment" in value and value["comment"]:
                print("#", end="", file=output)
            default = value.get("default", "not defined")
            print(f"{value['name']}={default}", file=output)


def render_man_page(config, output):
    print("==========", file=output)
    print("rygel.conf", file=output)
    print("==========\n", file=output)

    print("----------------------------", file=output)
    print("Configuration file for Rygel", file=output)
    print("----------------------------\n", file=output)
    print(":Manual section: 5\n", file=output)
    print("SYNOPSIS", file=output)
    print("=========\n\n", file=output)
    print("  - ``/etc/rygel.conf``", file=output)
    print("  - ``$XDG_CONFIG_HOME/rygel.conf``\n", file=output)

    for section_index, section in enumerate(config):
        if section_index > 0:
            print(file=output)
        if section["name"] == "general":
            print("DESCRIPTION", file=output)
            print("===========", file=output)
            print(indent_text(section["description"], 1), file=output)
            print(file=output)
        if 'display_name' in section:
            print(f"{section['display_name'].upper()}", file=output)
            print(f"{"=" * len(section['display_name'])}\n", file=output)
        else:
            if len(section["name"]) > 0:
                heading = f"SECTION {section['name'].upper()}"
                print(heading, file=output)
                print(f"{"=" * len(heading)}\n", file=output)

        if section["name"] != "general":
            print(indent_text(section["description"], 1), file=output)
            print(file=output)

        for index, value in enumerate(section["values"]):
            if "only-in" in value and value["only-in"] != "man":
                continue

            if index > 0:
                print(file=output)
            default = value.get("default", "not defined")
            print(f"    *{value['name']}*", file=output)
            if "description" in value:
                print(f"{indent_text(value['description'], level=2, strip=True)}", file=output)

def _render_doc_paragraph(text: str, output: typing.io.TextIO, base_indent: int = 0):
    paragraphs = text.split("\n\n")
    for paragraph in paragraphs:
        match = admonition_regex.search(paragraph)
        if match:
            replacement = admonition_map[match.group(1)]
            d = paragraph.replace(match.group(0), f"{replacement}\n\n")

            sections = d.split(f"{replacement}\n")
            print(indent_text(sections[0], base_indent), file=output)
            print(indent_text(f"{replacement}\n", base_indent), file=output)
            print(indent_text("".join(sections[1:]).strip(), base_indent + 1), file=output)
            print(file=output)

        else:
            print(indent_text(paragraph, base_indent), file=output)
            print(file=output)


def render_documentation(config, output):

    print("Rygel's default configuration file", file=output)
    print("----------------------------------", file=output)

    # generate the example documentation
    for section_number, section in enumerate(config):
        if section_number > 0:
            print(file=output)

        if "description" in section:
            if "display_name" in section:
                print(f".. _{section['display_name'].lower().replace(" ", "_")}_configuration:\n", file=output)
                print(section["display_name"], file=output)
                print("~" * len(section["display_name"]) + "\n", file=output)
            else:
                if len(section["name"]) > 0:
                    print(f".. _{section['name'].lower()}_configuration:\n", file=output)
                    heading = f"Section [{section['name']}]"
                    print("\n" + heading, file=output)
                    print('~' * len(heading) + "\n", file=output)

            _render_doc_paragraph(section["description"], output)

            print(file=output)

        for index, value in enumerate(section["values"]):
            # skip title and enabled since they are described in a general section
            if value['name'] in ('title', 'enabled') and (len(section['name']) > 0):
                continue

            if "only-in" in value and value["only-in"] != "doc":
                continue

            print(value["name"], file=output)
            if "description" in value:
                _render_doc_paragraph(value["description"], output, 1)
            else:
                print(f"{value['name']} does not have a description", file=sys.stderr)
            print(file=output)
            if "default" in value and (len(str(value["default"])) > 0):
                print(indent_text(f"*Default value*: ``{value['default']}``", 1), file=output)
                print(file=output)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Generate rygel.conf, man page and documentation from a single source of truth"
    )
    parser.add_argument("yaml", type=argparse.FileType("r", encoding="UTF-8"))
    parser.add_argument("output", type=argparse.FileType("w", encoding="UTF-8"))
    parser.add_argument("-m", "--mode", choices=["rst", "conf", "man"], required=True)
    args = parser.parse_args()

    config = yaml.safe_load(args.yaml)

    if args.mode == "rst":
        render_documentation(config, args.output)
    elif args.mode == "man":
        render_man_page(config, args.output)
    elif args.mode == "conf":
        render_example_conf(config, args.output)
    else:
        print(f"Unknown mode {args.mode}")
        sys.exit(1)
