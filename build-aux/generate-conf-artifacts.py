#!/usr/bin/python3

import yaml
import argparse
import textwrap
import re
import sys


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


def render_example_conf(config, output):
    print("# Rygel default configuration\n", file=output)
    # generate the example documentation
    for section_number, section in enumerate(config):
        if section_number > 0:
            print(file=output)

        if "description" in section:
            raw_desciption = section["description"]
            if "display_name" in section:
                raw_description = section["display_name"] + "\n\n" + raw_desciption

            description = comment_text(raw_description, width=80, strip=True)
            print(description, file=output)
            print(file=output)

        if len(section["name"]) > 0:
            print(f"[{section['name']}]", file=output)
        for index, value in enumerate(section["values"]):
            if index > 0:
                print(file=output)
            if "description" in value:
                print(f"{comment_text(value['description'], strip=True)}", file=output)
            if "comment" in value and value["comment"]:
                print("#", end="", file=output)
            default = value.get("default", "not defined")
            print(f"{value['name']}={default}", file=output)


def render_man_page(config):
    pass


def render_documentation(config, output):
    print("Rygel's default configuration file", file=output)
    print("----------------------------------", file=output)

    # generate the example documentation
    for section_number, section in enumerate(config):
        if section_number > 0:
            print(file=output)

        if "description" in section:
            if "display_name" in section:
                print(section["display_name"], file=output)
                print("~" * len(section["display_name"]) + "\n", file=output)
            else:
                if len(section["name"]) > 0:
                    heading = f"Section [{section['name']}]"
                    print("\n" + heading, file=output)
                    print('~' * len(heading) + "\n", file=output)

            raw_description = section["description"].replace('%%Note: ', ".. note::\n\n")

            print(reflow_text(raw_description), file=output)
            print(file=output)

        for index, value in enumerate(section["values"]):
            # skip title and enabled since they are described in a general section
            if value['name'] in ('title', 'enabled') and (len(section['name']) > 0):
                continue

            print(value["name"], file=output)
            if "description" in value:
                raw_description = value["description"].replace('%%Note: ', ".. note::\n\n")
                print(
                    textwrap.indent(
                        reflow_text(raw_description, 77), "   ", lambda line: True
                    ),
                    file=output,
                )
            else:
                print(f"{value['name']} does not have a description", file=sys.stderr)
            print(file=output)
            if "default" in value and (len(str(value["default"])) > 0):
                print(f"   *Default value*: ``{value['default']}``", file=output)
                print(file=output)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Generate rygel.conf, man page and documentation from a single source of truth"
    )
    parser.add_argument("yaml", type=argparse.FileType("r", encoding="UTF-8"))
    parser.add_argument("output", type=argparse.FileType("w", encoding="UTF_8"))
    parser.add_argument("-m", "--mode", choices=["rst", "conf", "man"], required=True)
    args = parser.parse_args()

    config = yaml.safe_load(args.yaml)

    if args.mode == "rst":
        render_documentation(config, args.output)
    elif args.mode == "man":
        pass
    else:
        render_example_conf(config, args.output)
