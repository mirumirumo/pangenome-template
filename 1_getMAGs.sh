#!/bin/bash
#$ -S /bin/bash
#$ -N pipeline_1
#$ -cwd
#$ -o ./pipeline_1/
#$ -e ./pipeline_1/
#$ -pe smp 30
#$ -l s_vmem=20G
#$ -l mem_req=20G
#$ -l h_rss=20G
#$ -t 1-2:1
start_time=$(date +%s)

# ******* the constant values you hace to specify *******
THREADS=30
SAVE_PATH=/your/path/to/save
MAG_METADATA=/your/path/to/mag_metadata.tsv
MAG_PATH=/your/path/to/MAGs
SPECIES=/your/path/to/species_list.txt
BIN_FILTER=/your/path/to/bin_filter.py
# *******************************************************

for species in $(head -n ${SGE_TASK_ID} ${SPECIES}| tail -n 1); do
    echo "Downloading MAGs relevant to ${species} is now processing."
    species_path=${SAVE_PATH}/species/${species}
    index_path=${species_path}/index
    genome_path=${species_path}/genome
    mkdir -p ${index_path}
    mkdir -p ${genome_path}
    python ${BIN_FILTER} -s ${species} -f ${MAG_METADATA} -o ${genome_path}
    bin_tmp=${genome_path}/${species}_MAGs.tsv
    bin_counter=0
    genome_counter=0
    genome_tmp=-1
    for bin in $(cat ${bin_tmp}| awk 'NR > 1 {print $1}'); do
        if [ ${genome_counter} -eq 0 ]; then
            genome_tmp=$((genome_tmp+1))
            genome_path_tmp=${genome_path}/batch_${genome_tmp}
            mkdir -p ${genome_path_tmp}
        fi
        bin_path=${MAG_PATH}/${bin}.fa
        awk -v strain_num="${bin_counter}" '/^>/ {$0 = ">" strain_num "_" "contig" "_" ++i} 1' ${bin_path} > ${genome_path_tmp}/${bin}.fa 
        bin_counter=$((bin_counter+1))
        genome_counter=$(((genome_counter + 1) % 5))
    done
    rm ${bin_tmp}
    echo "${bin_counter} MAGs related to ${species} have downloaded."
    echo ""

    # run checkM2
    echo "----------------------------checkM2 start------------------------------"
    checkm2_out=${species_path}/checkm2_out
    mkdir -p ${checkm2_out}
    for batch in $(ls ${genome_path}); do
        genome_batch=${genome_path}/${batch}
        checkm2 predict --threads ${THREADS} --input ${genome_batch}/* --output-directory ${checkm2_out}/${batch} -x fa --lowmem
        for bin in $(awk 'NR > 1 && ($2 < 90 || $3 > 5) {print $1}' ${checkm2_out}/${batch}/quality_report.tsv); do
            rm ${genome_batch}/${bin}.fa
            echo "removing ${bin}.fa"
            bin_counter=$((bin_counter-1))
        done
    done

    echo "${bin_counter} MAGs related to ${species} have passed checkM2."
    echo "----------------------------checkM2 end------------------------------"
    echo ""

    # make index
    echo "------------------------- making index start ----------------------------"
    for batch in $(ls ${genome_path}); do
        genome_batch=${genome_path}/${batch}
        for bin in $(ls ${genome_batch}); do
            cat ${genome_batch}/${bin} >> ${genome_path}/${species}_MAGs.fa
        done
    done
    bowtie2-build -f ${genome_path}/${species}_MAGs.fa ${index_path}/${species}_index
    rm ${genome_path}/${species}_MAGs.fa 
    echo "------------------------- making index end ----------------------------"
done

end_time=$(date +%s)
time=$((end_time - start_time))
echo "time:$time"