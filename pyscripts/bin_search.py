import pandas as pd
import os
from argparse import ArgumentParser

def count_MAGs(df: pd.DataFrame, sp: str) -> pd.DataFrame:
    df_tmp = df[df.classification.str.contains(sp)].reset_index(drop=True)
    print(f'{sp} MAGs in your metadata file: {len(df_tmp)}')
    return df_tmp

argparser: ArgumentParser = ArgumentParser()
argparser.add_argument('-f', '--file', required=True, help='File to search')
argparser.add_argument('-s', '--species', required=True,
                       help='Species to search for')
argparser.add_argument('-o', '--output', required=True)
args = argparser.parse_args()

file_path = args.file
species = args.species
species_with_space = species.replace('_', ' ')
out_path = args.output
out_path = os.path.join(out_path, f'{species}_MAGs.tsv')

mag_df: pd.DataFrame = pd.read_table(file_path)
bin_df: pd.DataFrame = count_MAGs(mag_df, species_with_space)
bin_df.to_csv(out_path, sep='\t', index=False)
