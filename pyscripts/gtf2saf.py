import sys
import pandas as pd
import os

args = sys.argv
input_1 = str(args[1])  # gtf_file_filtered
species_name = str(args[2])
to_path = str(args[3])

df_raw = pd.read_table(
    input_1, names=["genome", "Start", "End", "Strand", "GeneID"])

for index in df_raw.index:
    list_temp = [i.lstrip(" ") for i in df_raw.at[index,
                                                  "GeneID"].split(";") if "transcript_id" in i]
    list_temp = [i for i in list_temp[0].split(" ")]

    df_raw.at[index, "GeneID"] = list_temp[1].strip('"')


df_out = df_raw[["GeneID", "genome", "Start", "End", "Strand"]]


to_path = os.path.join(to_path, "{}.saf".format(species_name))
df_out.to_csv(to_path, sep="\t", index=False)
