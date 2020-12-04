#!/bin/bash


if [[ $# -lt 2 ]] ; then
	echo "Usage: $0 <system> <library> <# of GPUs>"
	echo "e.g.:"
	echo "$0 7cpa Enamine-PC 4"
	exit 0
fi


SYSTEM=$1
LIBRARY=$2
GPUS=$3

if [[ ! -d ${SYSTEM} ]]; then
	echo "${SYSTEM} does not exist"
	exit 0
fi

if [[ ! -d ${SYSTEM}/${LIBRARY}/ ]]; then
	echo "${SYSTEM}/${LIBRARY} does not exist"
	exit 0
fi

if [[ ${GPUS} -gt 0 ]]; then
	:
else
	echo "${GPUS} should be a positive integer"
	exit 0
fi


NAME=${SYSTEM}_${LIBRARY}_${GPUS}
ROOTDIR=/scratch/03439/wallen/autodock_GPU
TOPDIR=${ROOTDIR}/${SYSTEM}/${LIBRARY}/GPUS-${GPUS}

rm -rf ${SYSTEM}/${LIBRARY}/GPUS-${GPUS}
mkdir -p ${SYSTEM}/${LIBRARY}/GPUS-${GPUS}
cd ${SYSTEM}/${LIBRARY}/GPUS-${GPUS}


ln -s ${ROOTDIR}/${LIBRARY} ligands
mkdir -p output/
NUM_DIRS=` find ligands/ -type d | wc -l `
((NUM_DIRS=NUM_DIRS-1))
for NUM in `seq 1 ${NUM_DIRS}`; do
	mkdir -p output/${NUM}
	#mkdir -p /dev/shm/output/${NUM}
done


for NUM in `seq 1 ${GPUS}`; do
	touch ${NAME}.batch${NUM}
	echo "${ROOTDIR}/${SYSTEM}/derived/${SYSTEM}_rec.maps.fld" >> ${NAME}.batch${NUM}
	#echo "/dev/shm/derived/${SYSTEM}_rec.maps.fld" >> ${NAME}.batch${NUM}
done

find ${ROOTDIR}/${LIBRARY} -type f -name '*pdbqt' >> temp
split -n l/${GPUS} temp temp; rm temp


for NUM in `seq 1 ${GPUS}`; do

	FILE=` ls temp* | head -n ${NUM} | tail -n1 `
	for LINE in ` cat ${FILE} `; do

		#OUT=${LINE:3:-6}
		OUT=` echo $LINE | awk -F/ '{print $(NF-1)"/"$NF}' | awk -F. '{print $1}' `
		echo "${LINE}" >> ${NAME}.batch${NUM}
		echo "${TOPDIR}/output/${OUT}" >> ${NAME}.batch${NUM}
		#echo "/dev/shm/${LIBRARY}/${OUT}.pdbqt" >> ${NAME}.batch${NUM}
		#echo "/dev/shm/output/${OUT}" >> ${NAME}.batch${NUM}

	done # end for each line

	rm ${FILE}
done # end for each num


AUTODOCK_BIN=/home/03439/wallen/autodock_GPU/AutoDock-GPU-wjallen/bin
#AUTODOCK_BIN=/home/03439/wallen/autodock_GPU/AutoDock-GPU-1.3/bin
#AUTODOCK_BIN=/dev/shm/bin

#AUTODOCK_EXE=${AUTODOCK_BIN}/autodock_gpu_256wi
#AUTODOCK_EXE=${AUTODOCK_BIN}/autodock_gpu_128wi
#AUTODOCK_EXE=${AUTODOCK_BIN}/autodock_gpu_64wi
AUTODOCK_EXE=${AUTODOCK_BIN}/autodock_gpu_32wi


for NUM in ` seq 1 ${GPUS}`; do
	echo "${AUTODOCK_EXE} -initpopfn initpop_${NUM}.txt -xmloutput 0 -nrun 10 -filelist ${TOPDIR}/${NAME}.batch${NUM} > ${TOPDIR}/output_${NUM}.log" >> ${NAME}.jobfile
done



NODES=` echo "${GPUS} / 4" | bc `
cat <<EOF > ${NAME}.slurm
#!/bin/bash
#SBATCH -J ${NAME}
#SBATCH -o ${NAME}.o%j
#SBATCH -e ${NAME}.e%j
#SBATCH -p v100
#SBATCH -N ${NODES}
#SBATCH -n ${GPUS}
#SBATCH -t 06:00:00
#SBATCH -A longhorn3

module load gcc/7.3.0
module load cuda/10.2
module load launcher_gpu/1.1

export LAUNCHER_PLUGIN_DIR=\$LAUNCHER_DIR/plugins
export LAUNCHER_RMI=SLURM
export LAUNCHER_JOB_FILE=${NAME}.jobfile

#for JOBNODE in \` scontrol show hostnames \$SLURM_JOB_NODELIST \`; do
#	scp -r ${AUTODOCK_BIN} \${JOBNODE}:/dev/shm
#	scp -r ${ROOTDIR}/${SYSTEM}/derived \${JOBNODE}:/dev/shm
#       scp -r ${ROOTDIR}/${LIBRARY} \${JOBNODE}:/dev/shm
#done

echo -n "start time = "
date
START_TIME=\` date +%s \`

\$LAUNCHER_DIR/paramrun

echo -n "end time = "
date
END_TIME=\` date +%s \`


echo -n "seconds elapsed = "
echo "\${END_TIME} - \${START_TIME}" | bc

grep "setup" output*log | awk '{print \$4}' > time_run.dat
grep "setup" output*log | awk '{print \$8}' > time_wait.dat

EOF





