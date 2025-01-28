#!/bin/bash
#$ -S /bin/bash
#$ -N pipeline2
#$ -cwd
#$ -o ./pipeline_2-1/
#$ -e ./pipeline_2-1/
#$ -pe smp 20
#$ -l s_vmem=10G
#$ -l mem_req=10G
#$ -l h_rss=10G
#$ -t 1-2:1

start_time=$(date +%s)
# ******* the constant values you hace to specify *******
THREADS=20
SAVE_PATH=/your/path/to/save
SPECIES=/your/path/to/species_list.txt
SINGULARITY="/the/path/to/singularity"
ROARY_SIF="/the/path/to/roary_3.13.0--pl526h516909a_0.sif" 
SCRIPT_PATH=/the/path/to/gtf2saf.py
# *******************************************************
for species in $(head -n ${SGE_TASK_ID} ${SPECIES}| tail -n 1) ;do
    # prokka
    species_path=${SAVE_PATH}/species/${species}
    prokka_out=${species_path}/prokka_out
    annotation=${species_path}/annotation
    gffs=${annotation}/gffs
    roary_out=${species_path}/roary_out
    mkdir -p ${prokka_out}
    mkdir -p ${gffs}
    echo "----------------------------prokka start------------------------------"
    genome_path=${species_path}/genome
    for batch in $(ls ${genome_path});do
        for file_name in $(ls ${genome_path}/${batch});do
            bin=${file_name%.fa}
            prokka ${genome_path}/${batch}/${file_name} -o ${prokka_out}/${bin} --metagenome --prefix ${bin} --cpus ${THREADS}
            cp ${prokka_out}/${bin}/${bin}.gff ${gffs} 
        done
    done
    echo "----------------------------prokka end------------------------------"

    echo "----------------------------roary start------------------------------"
    ${SINGULARITY} exec --cleanenv --bind /data2:/data2 ${ROARY_SIF}  roary -p ${THREADS} -cd 100 -e --mafft -i 95 -f ${roary_out} ${gffs}/*.gff
    echo "----------------------------roary end------------------------------"
    
    echo "----------------------------gffread start------------------------------"
    # convert gffs into a gtf
    for file_name in $(ls ${gffs});do
        bin=${file_name%.gff}
        gffread -E ${gffs}/${bin}.gff -T -o ${gffs}/${bin}.gtf
        rm ${gffs}/${bin}.gff
    done
    echo "----------------------------gffread end------------------------------"

    echo "----------------------------gtf2saf start------------------------------"
    # convert a gtf into a saf
    cat ${gffs}/*.gtf > ${gffs}/${species}.gtf
    cat ${gffs}/${species}.gtf| grep CDS | cut -f 1,4,5,7,9 >  ${gffs}/${species}_filtered.gtf
    python ${SCRIPT_PATH} ${gffs}/${species}_filtered.gtf ${species} ${gffs}
    
    rm ${gffs}/*.gtf
    echo "----------------------------gtf2saf end------------------------------"
done

end_time=$(date +%s)
time=$((end_time - start_time))
echo "time:$time"