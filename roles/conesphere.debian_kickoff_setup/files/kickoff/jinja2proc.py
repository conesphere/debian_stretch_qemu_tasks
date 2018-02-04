#!/usr/bin/python3
import sys
import yaml
import os
import re
import datetime
from jinja2 import *
import argparse
# This script renders a .yaml with a .jinja2 template


parser = argparse.ArgumentParser(description="render a yaml with a jinja2 template")
parser.add_argument("-s", "--stdin", action="store_true",
	help="read input yaml from stdin in addition to input file")
parser.add_argument("-i", "--input", type=str,
	help="use the given filename for input")
parser.add_argument("-o", "--output", type=str,
	help="use the given filename for output")
parser.add_argument("-p", "--path", type=str,
	help="look for templates in the given path", default="./")
parser.add_argument("template", type=str,
	help="use the given template to render output")
args = parser.parse_args()

if (args.input == None) or (args.stdin==True):
	input_yaml=''
	for line in sys.stdin:
		input_yaml=input_yaml+line
	render_stdin=yaml.load(input_yaml)
else:
	render_stdin={}

if args.input != None:
	print(args.input)
	render_stdin=yaml.load(args.input)
else:
	render_input={}

render={**render_input, **render_stdin}

template=Environment(
	loader=FileSystemLoader(args.path)
).get_template(args.template)


if (args.output == None):
	outf=sys.stdout
else:
	outf=open(args.output, "w")

outf.write(template.render(render))

