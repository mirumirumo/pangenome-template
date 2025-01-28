#!/bin/bash
#$ -S /bin/bash
#$ -N pipeline_1-2
#$ -cwd
#$ -o ./pipeline_1-2/
#$ -e ./pipeline_1-2/
#$ -pe smp 20
#$ -l s_vmem=20G
#$ -l mem_req=20G
#$ -l h_rss=20G
#$ -t 1-2:1
start_time=$(date +%s)
# ******* the constant values you hace to specify *******
THREADS=20
SAVE_PATH=/your/path/to/save
MAG_METADATA=/your/path/to/mag_metadata.tsv
MAG_PATH=/your/path/to/MAGs
SPECIES=/your/path/to/species_list.txt
# *******************************************************
for species in $(head -n ${SGE_TASK_ID} ${SPECIES}| tail -n 1); do
    
    species_path=${SAVE_PATH}/species/${species}
    genome_path=${species_path}/genome
    large_index_path=${species_path}/large_index
    mkdir -p ${large_index_path}
    declare -A genome_exists

    for batch in $(ls ${genome_path}); do
        genome_batch=${genome_path}/${batch}
        for bin in $(ls ${genome_batch}); do
            bin=${bin%.fa}
            genome_exists[${bin}]=1
            cat ${genome_batch}/${bin}.fa >> ${large_index_path}/${species}_MAGs.fa
        done
    done
    bin_counter=0
    for bin in $(cat ${MAG_METADATA} | awk 'NR > 1 {print $1}' ); do
        if [ -z ${genome_exists[${bin}]} ]; then
            bin_path=${MAG_PATH}/${bin}.fa
            awk -v strain_num="${bin_counter}" '/^>/ {$0 = ">" "other_strain_" strain_num "_" "contig" "_" ++i} 1' ${bin_path} >> ${large_index_path}/${species}_MAGs.fa
            bin_counter=$((bin_counter+1))
        fi
    done
    echo "------------------------- copy ${bin_counter} other MAGs ----------------------------"

    echo "------------------- making large index start ----------------------"
    bowtie2-build -f ${large_index_path}/${species}_MAGs.fa --threads ${THREADS} --large-index ${large_index_path}/${species}_index
    
    # rm ${large_index_path}/${species}_MAGs.fa
    echo "------------------- making large index end ----------------------"

done


end_time=$(date +%s)
time=$((end_time - start_time))
echo "time:$time"