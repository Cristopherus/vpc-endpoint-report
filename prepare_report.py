'''
Creates tex file from templates with data from csv files
'''
import logging
import glob
from datetime import datetime
from jinja2 import Template

def prepareList(file_name : str, position: int):
    lines = []
    report_file = open(file_name, "r")
    report_full = report_file.readlines()
    for line in report_full:
        line_split = line.split(",")
        lines.append(line_split[position])
    headline_index = lines.index("name")
    del lines[headline_index]
    return lines

def compareLists(first_list : list, second_list : list):
    result = list(set(first_list)-set(second_list))
    return result

def getEndpointsNotUsed(envs: list):
    endpoints_not_used = {}
    for env in envs:
        usage = prepareList("usage-" + str(env) + ".csv", 2)
        print(usage)
        endpoints = prepareList("endpoint-list-" + str(env) + ".csv", 3)
        print(endpoints)
        endpoints_not_used[env]=compareLists(endpoints, usage)
    return endpoints_not_used

def main():
    '''
    Read names of csv files and genereate tex file from template with using those csv-file names
    '''
    envs = []
    logging.info("Checking envs number and names")
    for file in glob.glob("endpoint-list-*.csv"):
        envs.append(file.removeprefix('endpoint-list-').removesuffix('.csv'))
    logging.info("Creating tex file from template")
    endpoints_not_used = getEndpointsNotUsed(envs)
    with open('endpoints-report.tex.j2',encoding='utf-8') as file:
        template = Template(file.read())
        template.stream(envs=envs, date=datetime.date(datetime.now()), not_used=endpoints_not_used).dump('endpoints-report.tex')

if __name__ == '__main__':
    logging.basicConfig(level=logging.INFO)
    main()
