#!/bin/bash
#$ -S /bin/bash
#$ -N pipeline_2
#$ -cwd
#$ -o ./pipeline_2/
#$ -e ./pipeline_2/
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
    patient_path=${SAVE_PATH}/patients/${patient_id}
    patient_reads=${patient_path}/HQ_reads
    for species in $(cat ${SPECIES}) ;do
        species_path=${SAVE_PATH}/species/${species}

        # mapping to ref
        echo "------------------- mapping start ----------------------"
        index_path=${species_path}/index
        bowtie2_out=${patient_path}/bowtie2_out
        mkdir -p ${bowtie2_out}
        for bin in $(ls ${patient_reads});do
            forward=${patient_reads}/${bin}/${bin}_R1.pairend.fastq
            reverse=${patient_reads}/${bin}/${bin}_R2.pairend.fastq
            bowtie2 -1 ${forward} -2 ${reverse} -p ${THREADS} --very-sensitive --non-deterministic -x ${index_path}/${species}_index -S ${bowtie2_out}/${bin}.sam  
        done

        echo "------------------- mapping end ----------------------"

        echo "------------------- rm unmapped reads start ----------------------"
        for bin in $(ls ${patient_reads});do
            samtools view -@ ${THREADS} -bS ${bowtie2_out}/${bin}.sam > ${bowtie2_out}/${bin}.bam
            samtools view -F 4 -@ ${THREADS} -b ${bowtie2_out}/${bin}.bam > ${bowtie2_out}/${bin}_unmapped_removed.bam
            rm ${bowtie2_out}/${bin}.sam
            rm ${bowtie2_out}/${bin}.bam         
        done
        echo "------------------- rm unmapped reads end ----------------------"
        
        # get mapped reads
        mapped_reads=${patient_path}/mapped_reads
        mkdir -p ${mapped_reads}
        for bin in $(ls ${patient_reads});do
            mkdir -p ${mapped_reads}/${bin}
            forward=${mapped_reads}/${bin}/${bin}_R1.pairend_mapped.fastq
            reverse=${mapped_reads}/${bin}/${bin}_R2.pairend_mapped.fastq
            picard SamToFastq INPUT=${bowtie2_out}/${bin}_unmapped_removed.bam F=${forward} F2=${reverse}    
        done 
    done
done

end_time=$(date +%s)
time=$((end_time - start_time))
echo "time:$time"