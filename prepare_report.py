'''
Creates tex file from templates with data from csv files
'''
import logging
import glob
from datetime import datetime
from jinja2 import Template

def main():
    '''
    Read names of csv files and genereate tex file from template with using those csv-file names
    '''
    envs = []
    logging.info("Checking envs number and names")
    for file in glob.glob("endpoint-list-*.csv"):
        envs.append(file.removeprefix('endpoint-list-').removesuffix('.csv'))
    logging.info("Creating tex file from template")
    with open('endpoints.tex.j2',encoding='utf-8') as file:
        template = Template(file.read())
        template.stream(envs=envs, date=datetime.date(datetime.now())).dump('endpoints-report.tex')

if __name__ == '__main__':
    logging.basicConfig(level=logging.INFO)
    main()
