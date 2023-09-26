#!/usr/bin/env python
# get_fasta_lengths.py
# Gets lengths of entries in a FastA file
# Jackson M. Tsuji, 2023

import os
import sys
import time
import argparse
import logging
from Bio import SeqIO

# GLOBAL VARIABLES
SCRIPT_VERSION = '0.2.0'

# Set up the logger
logging.basicConfig(format='[ %(asctime)s UTC ]: %(module)s: %(levelname)s: %(message)s')
logging.Formatter.converter = time.gmtime
logger = logging.getLogger(__name__)


def get_fasta_lengths(fasta_filepath: str):
    """
    Returns the length of each entry in a FastA file, along with the sequence name

    :param fasta_filepath: path to the FastA file
    :return: prints sequence names and lengths (tab separated) to STDOUT
    """

    with open(fasta_filepath) as fasta_handle:

        for entry in SeqIO.parse(fasta_handle, 'fasta'):

            seqname = entry.name
            seqlength = len(entry.seq)

            print(f'{seqname}\t{seqlength}')


def main(args):

    # Set user variables
    fasta_filepath = args.fasta_filepath
    verbose = args.verbose

    # Startup checks
    if verbose is True:
        logger.setLevel(logging.DEBUG)
    else:
        logger.setLevel(logging.INFO)

    # Startup messages
    logger.debug('Running ' + os.path.basename(sys.argv[0]))
    logger.debug('Version: ' + SCRIPT_VERSION)
    logger.debug('### SETTINGS ###')
    logger.debug(f'FastA filepath: {fasta_filepath}')
    logger.debug(f'Verbose logging: {verbose}')

    get_fasta_lengths(fasta_filepath)

    logger.debug(os.path.basename(sys.argv[0]) + ': done.')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(
        description=f'{os.path.basename(sys.argv[0])}: get lengths of entries in a FastA file. \n'
                    f'Copyright Jackson M. Tsuji, 2023. \n'
                    f'Version: {SCRIPT_VERSION}')
    parser.add_argument('fasta_filepath', help='FastA filepath')
    parser.add_argument('-v', '--verbose', required=False, action='store_true',
                        help='Enable for verbose logging.')
    command_line_args = parser.parse_args()
    main(command_line_args)
