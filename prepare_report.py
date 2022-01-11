import logging
import glob
from jinja2 import Template

def main():
	envs = []
	for file in glob.glob("*.csv"):
		envs.append(file.removesuffix('.csv'))
	with open('endpoints.tex.j2') as f:
		template = Template(f.read())
		template.stream(envs=envs).dump('endpoints.tex')

if __name__ == '__main__':
	logging.basicConfig(level=logging.INFO)
	
	main()
