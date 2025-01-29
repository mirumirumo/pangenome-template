#!/bin/bash
#$ -S /bin/bash
#$ -N pipeline3
#$ -cwd
#$ -o ./pipeline3/
#$ -e ./pipeline3/
#$ -pe smp 10
#$ -l s_vmem=10G
#$ -l mem_req=10G
#$ -l h_rss=10G
#$ -t 1-5:1

start_time=$(date +%s)
# ******* the constant values you hace to specify *******
THREADS=10
SAVE_PATH=/your/path/to/save
SPECIES=/your/path/to/species_list.txt
PATIENTS=/your/path/to/patient_list.txt
# *******************************************************

for patient_id in $(head -n ${SGE_TASK_ID} ${PATIENTS} | tail -n 1);do
    species_path=${SAVE_PATH}/species/${species}
    patient_path=${SAVE_PATH}/patients/${patient_id}
    for species in $(cat ${SPECIES}) ;do
        mapped_reads=${patient_path}/mapped_reads/${species}
        bowtie2_out=${patient_path}/bowtie2_rerun/${species}
        large_index_path=${species_path}/large_index
        mkdir -p ${bowtie2_out}

        echo "------------------- mapping start ----------------------"
        for bin in $(ls ${mapped_reads});do
            echo "-------${bin} start -------"
            now_time=$(date +%s)
            time=$((now_time - start_time))
            echo "time:$time"

            forward=${mapped_reads}/${bin}/${bin}_R1.pairend_mapped.fastq
            reverse=${mapped_reads}/${bin}/${bin}_R2.pairend_mapped.fastq
            bowtie2 -1 ${forward} -2 ${reverse} -p ${THREADS} --very-sensitive --non-deterministic -x ${large_index_path}/${species}_index -S ${bowtie2_out}/${bin}.sam  
            
            echo "-------${bin} end -------"
            now_time=$(date +%s)
            time=$((now_time - start_time))
            echo "time:$time"
        done

        echo "------------------- mapping end ----------------------"

        echo "------------------- rm unmapped reads start ----------------------"
        for bin in $(ls ${mapped_reads});do 
            samtools view -@ ${THREADS} -bS ${bowtie2_out}/${bin}.sam > ${bowtie2_out}/${bin}.bam
            samtools view -F 4 -@ ${THREADS} -b ${bowtie2_out}/${bin}.bam > ${bowtie2_out}/${bin}_unmapped_removed.bam
            rm ${bowtie2_out}/${bin}.sam
            rm ${bowtie2_out}/${bin}.bam         
        done
        echo "------------------- rm unmapped reads end ----------------------"

        echo "------------------- featureCounts start ----------------------"
        featureCounts_out=${patient_path}/featureCounts_out/${species}
        mkdir -p ${featureCounts_out}
        gffs_path=${species_path}/annotation/gffs
        sed -e '1d' ${gffs_path}/${species}.saf > ${gffs_path}/${species}_fixed.saf
        featureCounts -p -O -T ${THREADS} --minOverlap 50 -F SAF -t GeneID -g genome -a ${gffs_path}/${species}_fixed.saf -o ${featureCounts_out}/featureCounts_out ${bowtie2_out}/*.bam 
        echo "------------------- featureCounts end ----------------------"
    done
done
end_time=$(date +%s)
time=$((end_time - start_time))
echo "time:$time"