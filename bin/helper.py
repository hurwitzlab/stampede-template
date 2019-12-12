#!/usr/bin/env python3
"""
Author : Ken Youens-Clark <kyclark@gmail.com>
Date   : 2019-12-11
Purpose: Rock the Casbah
"""

import argparse
import re
from json import dumps


# --------------------------------------------------
def get_args():
    """Get command-line arguments"""

    parser = argparse.ArgumentParser(
        description='Rock the Casbah',
        formatter_class=argparse.ArgumentDefaultsHelpFormatter)

    parser.add_argument('file',
                        metavar='FILE',
                        type=argparse.FileType('r'),
                        help='Input file')

    parser.add_argument('-a',
                        '--app_name',
                        help='App name',
                        metavar='str',
                        type=str,
                        default='app')

    parser.add_argument('-v',
                        '--version',
                        help='App version',
                        metavar='str',
                        type=str,
                        default='0.1.0')

    parser.add_argument('-o',
                        '--outfile',
                        help='Output filename',
                        metavar='str',
                        type=str,
                        default='app.json')

    return parser.parse_args()


# --------------------------------------------------
def main():
    """Make a jazz noise here"""

    args = get_args()
    regex = re.compile(r'^\s*'
                       r'(?:[-](?P<short>[^,]),\s+)?'
                       r'[-]{2}(?P<long>[a-zA-Z0-9_-]+)\s+'
                       r'(?:[<](?P<type>[^>]+)[>])?\s+'
                       r'(?P<desc>.+)?')

    data = mk_app(args.app_name, args.version)
    last_input, last_param = 0, 0
    for i, line in enumerate(map(str.rstrip, args.file)):
        if not line:
            continue

        match = regex.search(line)
        if match:
            long = match.group('long')
            type_ = match.group('type') or 'NA'
            desc = match.group('desc') or 'NA'

            if long.lower() == 'help' or long.lower() == 'version':
                continue

            if re.search('(FILE|DIR)', type_):
                last_input += 1
                data['inputs'].append(mk_input(long, desc, last_input))
            else:
                last_param += 1
                data['parameters'].append(
                    mk_param(long, type_, desc, last_param))

    out_fh = open(args.outfile, 'wt')
    out_fh.write(dumps(data, indent=4))
    out_fh.close()
    print(f'See output in "{args.outfile}"')


# --------------------------------------------------
def mk_param(name, type_, desc, order):
    """make param"""

    return {
        'id': name.upper(),
        'value': {
            'default':
            '',
            'type':
            'flag' if type_.lower() == 'na' else
            'string' if type_.lower() == 'str' else 'number',
            'order':
            order,
            'required':
            False,
            'visible':
            True,
            'enquote':
            False,
            'validator':
            ''
        },
        'details': {
            'description': desc,
            'label': name.title().replace('_', ' '),
            'argument': f'--{name} ',
            'repeatArgument': False,
            'showArgument': True
        }
    }


# --------------------------------------------------
def mk_input(name, desc, order):
    """make input"""

    return {
        'id': name.upper(),
        'value': {
            'default': '',
            'order': order,
            'validator': '',
            'required': True,
            'visible': True,
            'enquote': False
        },
        'semantics': {
            'ontology': ['http://sswapmeet.sswap.info/mime/application/X-bam'],
            'minCardinality': 1,
            'maxCardinality': -1,
            'fileTypes': ['raw-0']
        },
        'details': {
            'description': name.title().replace('_', ' '),
            'label': desc,
            'argument': f'--{name} ',
            'repeatArgument': False,
            'showArgument': True
        }
    }


# --------------------------------------------------
def mk_app(app_name, version):
    """make base json"""

    return {
        'name': app_name,
        'version': version,
        'shortDescription': app_name,
        'longDescription': app_name,
        'available': True,
        'checkpointable': False,
        'defaultMemoryPerNode': 32,
        'defaultProcessorsPerNode': 16,
        'defaultMaxRunTime': '12:00:00',
        'defaultNodeCount': 1,
        'defaultQueue': 'serial',
        'deploymentPath':
        f'kyclark/applications/{app_name}-{version}/stampede',
        'deploymentSystem': 'data.iplantcollaborative.org',
        'executionSystem': 'tacc-stampede-kyclark',
        'executionType': 'HPC',
        'helpURI': '',
        'label': app_name,
        'parallelism': 'SERIAL',
        'templatePath': 'template.sh',
        'testPath': 'test.sh',
        'modules': ['load tacc-singularity'],
        'tags': [''],
        'ontology': ['http://sswapmeet.sswap.info/agave/apps/Application'],
        'inputs': [],
        'parameters': []
    }


# --------------------------------------------------
if __name__ == '__main__':
    main()
