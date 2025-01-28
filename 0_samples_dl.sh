#!/bin/bash
#$ -S /bin/bash
#$ -N pipeline_0
#$ -cwd
#$ -o ./pipeline_0/
#$ -e ./pipeline_0/
#$ -pe smp 10
#$ -l s_vmem=5G
#$ -l mem_req=5G
#$ -l h_rss=5G


start_time=$(date +%s)
# ******* the constant values you hace to specify *******
THREADS=10
SAVE_PATH=/your/path/to/save
PATIENTS=/your/path/to/patient_list.txt
CLINICAL_DATA=/your/path/to/clinical_data.tsv
READS=/your/path/to/reads_samples/
# *******************************************************

download_to=${SAVE_PATH}/patients
for patient_id in $(head -n ${SGE_TASK_ID} ${PATIENTS} | tail -n 1);do
    patient_path=${download_to}/${patient_id}
    for bin in $(cat ${CLINICAL_DATA} | awk -v patient_id=${patient_id} '$4 == patient_id {print $2}');do
        mkdir -p ${patient_path}/${bin}
        cp ${READS}/${sample}/QC/${sample}_R1.pairend.fastq.gz ${patient_path}/${bin}
        cp ${READS}/${sample}/QC/${sample}_R2.pairend.fastq.gz ${patient_path}/${bin}
        gzip -d ${patient_path}/${bin}/*
    done
done

end_time=$(date +%s)
time=$((end_time - start_time))
echo "time:$time"