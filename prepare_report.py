'''
Creates tex file from templates with data from csv files
'''
import logging
import glob
from datetime import datetime
from jinja2 import Template

def prepare_list(file_name: str, position: int):
    '''
    Returns list of values readed from specific position from file

    Parameters:
        file_name(str):Name of the file that will be read
        position(int):Number of columnt that will provide data

    Returns:
        lines(list):List of elements read from provided column number from provided file
    '''
    lines = []
    report_file = open(file_name, "r")
    report_full = report_file.readlines()
    for line in report_full:
        line_split = line.split(",")
        if "Gateway" not in line_split:
            lines.append(line_split[position])
    headline_index = lines.index("name")
    del lines[headline_index]
    return lines

def compare_lists(first_list: list, second_list: list):
    '''
    Compare two lists and returns difference (left minus join)

    Parameters:
        first_list(list):First list to compare
        second_list(list):Second list to compare

    Returns:
        result(list):Left minus join
    '''
    result = list(set(first_list)-set(second_list))
    return result

def get_endpoints_not_used(envs: list):
    '''
    Generate dict with lists of no used endpoint names and env as key

    Parameters:
        envs(list):List of environment names

    Returns:
        endpoints_not_used(dict):Dictionary with lists of no used endpoints and env as keys
    '''
    endpoints_not_used = {}
    for env in envs:
        usage = prepare_list("usage-" + str(env) + ".csv", 2)
        endpoints = prepare_list("endpoint-list-" + str(env) + ".csv", 0)
        compared_list = compare_lists(endpoints, usage)
        if compared_list:
            endpoints_not_used[env] = compared_list
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
    endpoints_not_used = get_endpoints_not_used(envs)
    with open('endpoints-report.tex.j2', encoding='utf-8') as file:
        template = Template(file.read())
        template.stream(envs=envs, date=datetime.date(datetime.now()), \
                        not_used=endpoints_not_used).dump('endpoints-report.tex')

if __name__ == '__main__':
    logging.basicConfig(level=logging.INFO)
    main()
