#!/usr/bin/python3

import yaml
import argparse
import textwrap
import re

def reflow_text(raw_description: str, width: int = 80, strip: bool = False) -> str:
    paragraphs = []
    if strip:
        raw_description = raw_description.replace('``', '')
        raw_description = raw_description.replace('%%', '')
    for paragraph in re.split(r'\n\n', raw_description):
        paragraphs.append(textwrap.fill(paragraph, width))

    return "\n\n".join(paragraphs)

def comment_text(raw_text: str, width: int = 80, strip: bool = False) -> str:
    return textwrap.indent(reflow_text(raw_text, 78, strip), '# ', lambda line: True)

def render_example_conf(config):
    # generate the example documentation
    for section_number, section in enumerate(config):
        if section_number > 0:
            print()

        if 'description' in section:
            raw_desciption = section['description']
            if 'display_name' in section:
                raw_description = section['display_name'] + '\n\n' + raw_desciption

            description = comment_text(raw_description, width=80, strip=True)
            print(description)
            print()

        if len(section['name']) > 0:
            print(f"[{section['name']}]")
        for index, value in enumerate(section['values']):
            if index > 0:
                print()
            if 'description' in value:
                print(f"{comment_text(value['description'], strip=True)}")
            if 'comment' in value and value['comment']:
                print('#', end='')
            default = value.get('default', 'not defined')
            print(f"{value['name']}={default}")


def render_man_page(config):
    pass


def render_documentation(config):
    pass

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description="Generate rygel.conf, man page and documentation from a single source of truth")
    parser.add_argument('yaml')
    args = parser.parse_args()

    with open(args.yaml, 'r') as config_meta:
        config = yaml.safe_load(config_meta)

        render_example_conf(config)
        render_man_page(config)
