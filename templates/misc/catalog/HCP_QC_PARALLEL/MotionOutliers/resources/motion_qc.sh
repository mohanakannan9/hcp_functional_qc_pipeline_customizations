#!/bin/sh -e

### BOLD Motion QC script for HCP

# Michael Harms; 9/25/2012


################################################################
#  INPUTS
#
################################################################

task=$1 #series description of the scan
indir=$2 #path to the nifti file of the scan
mcdir=$3 #Outdir
outfile=$4 #Path to file which will contain the measures
tmpdir=$5 #Temp dir
#label=$5

##############################################
#
# Import the paths from configuration file
#
##############################################

source @PIPELINE_DIR_PATH@/catalog/HCP_QC_PARALLEL/Wrapper_QC/resources/config/level2qc.config


################################################################
#  Source setup script
#
################################################################
source $SETUP_SCRIPTS/fsl5_setup.sh;

source $SETUP_SCRIPTS/epd-python_setup.sh;

source $SETUP_SCRIPTS/AFNI_setup.sh;


computemomentspath=@PIPELINE_DIR_PATH@/catalog/HCP_QC_PARALLEL/MotionOutliers/resources

FSL_MOTIONOUTLIERS_PATH=$FSLDIR/bin

################################################################
#  DEFAULT VALUES
#
################################################################


normfactor=10000
verbose=1
biascorrect=0
smooth=0  #Controls whether spatial smoothing is applied to input to dvars calc
fwhm=2    #mm


################################################################
#  ALGORITHM
#
################################################################

basefilename=`basename $task .nii.gz`

input=$indir/$task

mkdir -p $mcdir


### Report some settings ###
if [ $verbose -ne 0 ]; then
  echo -e "\ninput=$input"
  if [ $biascorrect -ne 0 ]; then
    echo "biascorrect=$biascorrect"
  fi 
  if [ $smooth -ne 0 ]; then
    echo "smooth=$smooth; fwhm=$fwhm (applied to dvars input only)"
  fi
fi


### Motion correction ###
if [ $verbose -ne 0 ]; then
  echo -e "\n---- Motion correction ----"
  date
fi
refnum=`$FSLDIR/bin/fslval $input dim4`;
refnum=`echo $refnum / 2 | bc`;
mcfout=fmri_mcf
cd $mcdir
mcflirt -in $input -out $mcfout -spline_final  -mats -plots -refvol $refnum -rmsrel -rmsabs -stats

[ $? -eq 0 ] || Exit "ERROR : FATAL couldnt launch mcflirt -in $input -out $mcfout -mats -plots -refvol $refnum -rmsrel -rmsabs -stats"

 
# Convert from radians to degrees: multiply 1-3rd columns by 180/pi = 57.296
awk '{print 57.296*$1, 57.296*$2, 57.296*$3, $4, $5, $6;}' $mcfout.par > ${mcfout}_deg.par
fsl_tsplot -i ${mcfout}_deg.par -t 'MCFLIRT estimated rotations (degrees):'$basefilename -u 1 --start=1 --finish=3 -a x,y,z  --ymin=-3 --ymax=3 -o rot.png 
fsl_tsplot -i ${mcfout}_deg.par -t 'MCFLIRT estimated translations (mm):'$basefilename -u 1 --start=4 --finish=6 -a x,y,z  --ymin=-3 --ymax=3 -o trans.png 
#fsl_tsplot -i ${mcfout}_abs.rms,${mcfout}_rel.rms -t 'MCFLIRT estimated mean displacement (mm):'$basefilename -u 1  -a absolute,relative -o disp.png 
fsl_tsplot -i ${mcfout}_abs.rms -t 'MCFLIRT estimated mean absolute displacement (mm):'$basefilename -u 1  --ymin=0 --ymax=5 -o disp_abs.png 
fsl_tsplot -i ${mcfout}_rel.rms -t 'MCFLIRT estimated mean relative displacement (mm):'$basefilename -u 1  --ymin=0 --ymax=1 -o disp_rel.png 

# Compute % of frames with relative movement above specified thresholds
thr1=0.3
pcnt_rel_rms_thr1=`awk 'BEGIN{count=0;} {if ($1 > t) count++} END{printf ("%.2f", count*100/NR)}' t=$thr1  ${mcfout}_rel.rms`
thr2=0.5
pcnt_rel_rms_thr2=`awk 'BEGIN{count=0;} {if ($1 > t) count++} END{printf ("%.2f", count*100/NR)}' t=$thr2  ${mcfout}_rel.rms`
thr3=0.15
pcnt_rel_rms_thr3=`awk 'BEGIN{count=0;} {if ($1 > t) count++} END{printf ("%.2f", count*100/NR)}' t=$thr3  ${mcfout}_rel.rms`

# Compute 90 and 95th percentiles of relative movement
pcntile90_rel_rms=`cat ${mcfout}_rel.rms | sort -n | awk 'BEGIN{i=0} {s[i]=$1; i++;} END{print s[int(NR*0.90-0.5)]}'`
pcntile95_rel_rms=`cat ${mcfout}_rel.rms | sort -n | awk 'BEGIN{i=0} {s[i]=$1; i++;} END{print s[int(NR*0.95-0.5)]}'`

if [ $verbose -ne 0 ]; then 
  echo "Percent frames with rel.rms > $thr1 = $pcnt_rel_rms_thr1"
  echo "Percent frames with rel.rms > $thr2 = $pcnt_rel_rms_thr2"
  echo "Percent frames with rel.rms > $thr3 = $pcnt_rel_rms_thr3"
  echo "90th percentile rel.rms = $pcntile90_rel_rms"
  echo "95th percentile rel.rms = $pcntile95_rel_rms"
  mean_rel_rms=`cat ${mcfout}_rel_mean.rms`
  echo "Mean rel.rms = $mean_rel_rms"
fi

meanfunc=${mcfout}_meanvol  # available by including the -stats option in 'mcflirt'


### BET ###
if [ $verbose  -ne 0 ]; then
  echo -e "\n---- Running bet ----"
  date
fi
bet $meanfunc ${meanfunc}_brain -f 0.3 -m

[ $? -eq 0 ] || Exit "ERROR : FATAL couldnt launch bet $meanfunc ${meanfunc}_brain -f 0.3 -m"


mask=${meanfunc}_brain_mask

### Normalize ###
if [ $verbose -ne 0 ]; then
  echo -e "\n---- Normalize to median of $normfactor within mask ----"
  date
fi
P50=`fslstats $meanfunc -k $mask -P 50`
mcfoutnorm=${mcfout}_norm
fslmaths $mcfout -div $P50 -mul $normfactor $mcfoutnorm -odt float   #Need '-odt float' here! 

[ $? -eq 0 ] || Exit "ERROR : FATAL couldnt launch fslmaths $mcfout -div $P50 -mul $normfactor $mcfoutnorm -odt float"


### Compute SD and tSNR ###
if [ $verbose -ne 0 ]; then
  echo -e "\n---- Compute SD image and tSNR on motion corrected, median $normfactor normalized time series ----"
  date
fi
fslmaths $mcfoutnorm -Tmean ${mcfoutnorm}_mean
fslmaths $mcfoutnorm -Tstd ${mcfoutnorm}_std
fslmaths ${mcfoutnorm}_mean -div ${mcfoutnorm}_std ${mcfoutnorm}_tSNR
tSNRbrain=`fslstats ${mcfoutnorm}_tSNR -k $mask -P 50`
SDbrain=`fslstats ${mcfoutnorm}_std -k $mask -P 50`
if [ $verbose -ne 0 ]; then 
  echo "Median tSNR of brain = $tSNRbrain"
  echo "Median SD (over time) of brain = $SDbrain"
fi

  echo "MOTION_QC_MEDIAN_tSNR=$tSNRbrain" > $outfile
  echo "MOTION_QC_SD=$SDbrain" >> $outfile
  echo "MOTION_QC_MEDIANI=$P50" >> $outfile
  echo "MOTION_QC_PERCENTAGE_REL_RMS_0.3=$pcnt_rel_rms_thr1" >> $outfile
  echo "MOTION_QC_PERCENTAGE_REL_RMS_0.5=$pcnt_rel_rms_thr2" >> $outfile
  echo "MOTION_QC_PERCENTAGE_REL_RMS_0.15=$pcnt_rel_rms_thr3" >> $outfile
  echo "MOTION_QC_90Percentile_REL_RMS=$pcntile90_rel_rms" >> $outfile
  echo "MOTION_QC_95Percentile_REL_RMS=$pcntile95_rel_rms" >> $outfile
  
### Compute smoothness (using AFNI's '3dFWHMx') ###
if [ $verbose -ne 0 ]; then
  echo -e "\n---- Compute smoothness (using AFNI's '3dFWHMx') of motion corrected, median $normfactor normalized time series ----"
  date
fi
# AFNI needs files with the full extension as input, so get file names with extension
mask3dFWHMx=`imglob -extension $mask`
input3dFWHMx=`imglob -extension $mcfoutnorm`
out3dFWHM=3dFWHM.txt
rm -f $out3dFWHM  # remove file in case in case it already exists, since 3dFWHMx won't overwrite it
# Detrend over time with mean, linear, quadratic, and 5th order sin/cos terms 
# to keep it simple and fast for all runs
detrendorder=5  
FWHMvals=`3dFWHMx -mask $mask3dFWHMx -detrend $detrendorder -input $input3dFWHMx -combine -out $out3dFWHM`
[ $? -eq 0 ] || Exit "ERROR : FATAL couldnt launch 3dFWHMx -mask $mask3dFWHMx -detrend $detrendorder -input $input3dFWHMx -combine -out $out3dFWHM"


FWHMx=`echo $FWHMvals | awk '{print $1}'`
FWHMy=`echo $FWHMvals | awk '{print $2}'`
FWHMz=`echo $FWHMvals | awk '{print $3}'`
FWHM=`echo $FWHMvals | awk '{print $4}'`  # final value is the "grand mean" (generated by using the -combine option)
fsl_tsplot -i $out3dFWHM -t '3dFWHMx estimated smoothness (mm)' -u 1 -a x,y,z --ymin=0 --ymax=5 -o smoothness.png
fsl_tsplot -i $out3dFWHM -t '3dFWHMx estimated smoothness, x-axis (mm)' -u 1 --start=1 --finish=1 --ymin=0 --ymax=5 -o smoothness_x.png
fsl_tsplot -i $out3dFWHM -t '3dFWHMx estimated smoothness, y-axis (mm)' -u 1 --start=2 --finish=2 --ymin=0 --ymax=5 -o smoothness_y.png
fsl_tsplot -i $out3dFWHM -t '3dFWHMx estimated smoothness, z-axis (mm)' -u 1 --start=3 --finish=3 --ymin=0 --ymax=5 -o smoothness_z.png
if [ $verbose -ne 0 ]; then 
  echo "FWHM = $FWHM (FWHMx = $FWHMx; FWHMy = $FWHMy; FWHMz = $FWHMz)"
fi

echo "MOTION_QC_FWHMx=$FWHMx" >> $outfile
echo "MOTION_QC_FWHMy=$FWHMy" >> $outfile
echo "MOTION_QC_FWHMz=$FWHMz" >> $outfile
echo "MOTION_QC_FWHM=$FWHM" >> $outfile


### Optional smoothing of input to dvars calc ###
if [ $smooth -ne 0 ]; then
  sigma=`echo "$fwhm / 2.35" | bc -l | awk '{printf "%.4f\n",$1}'`
  if [ $verbose -ne 0 ]; then
    echo -e "\n---- Smoothing input for dvars calculation ----"
    date
    echo "fwhm=$fwhm; sigma=$sigma"
  fi
  fslmoinput=${mcfoutnorm}_sm
  fslmaths $mcfoutnorm -s $sigma $fslmoinput
else
  fslmoinput=${mcfoutnorm}
fi


### DVARS ###
metric=dvars
if [ $verbose -ne 0 ]; then
  echo -e "\n---- Compute DVARS using fsl_motion_outliers ----"
  date
  $FSL_MOTIONOUTLIERS_PATH/fsl_motion_outliers -i $fslmoinput -m $mask -t $tmpdir --${metric} --nomoco --nocleanup -s ${metric}.txt  -v -o confound_${metric}.txt
else
  $FSL_MOTIONOUTLIERS_PATH/fsl_motion_outliers -i $fslmoinput -m $mask -t $tmpdir --${metric} --nomoco  --nocleanup -s ${metric}.txt  -o confound_${metric}.txt
fi


# Plot over a 0-100 range for now
fsl_tsplot -i ${metric}.txt -t 'Motion outlier '$basefilename' metric: '$metric -x "frame #" -y "metric value" --ymin=0 --ymax=100 -o ${metric}.png
# Compute some quantitative metrics
moments=`awk -f $computemomentspath/compute_moments.awk ${metric}.txt`
dvar_mean=`echo $moments | awk '{print $1}'`
dvar_u2=`echo $moments | awk '{print $2}'`
dvar_u3=`echo $moments | awk '{print $3}'`
dvar_u4=`echo $moments | awk '{print $4}'`
dvar_skew=`echo $moments | awk '{print $5}'`
dvar_kurt=`echo $moments | awk '{print $6}'`
#dvar_mean=`awk 'BEGIN{sum=0;} {sum+=$1} END{printf ("%.1f", sum/NR)}'  ${metric}.txt`
#thr1=50
#pcnt_dvar_thr1=`awk 'BEGIN{count=0;} {if ($1 > t) count++} END{printf ("%.1f", count*100/NR)}' t=$thr1  ${metric}.txt`
#thr2=70
#pcnt_dvar_thr2=`awk 'BEGIN{count=0;} {if ($1 > t) count++} END{printf ("%.1f", count*100/NR)}' t=$thr2  ${metric}.txt`
if [ $verbose -ne 0 ]; then 
#  echo "Percent frames with dvars > $thr1 = $pcnt_dvar_thr1"
#  echo "Percent frames with dvars > $thr2 = $pcnt_dvar_thr2"
  echo "Mean dvar = $dvar_mean; 2nd moment = $dvar_u2; 3rd moment = $dvar_u3; 4th moment = $dvar_u4"
  echo "Skewness = $dvar_skew; kurtosis = $dvar_kurt"
fi

if [ $verbose -ne 0 ]; then
  echo -e "\n---- Finished ----"
  date
  echo "-----------------------------------"
fi



################################################################
#  VALUES TO CONSUME
#
################################################################


## Quantitative values to report (in tabular format) are:
# ${mcfout}_abs_mean.rms (output of mcflirt)
# ${mcfout}_rel_mean.rms (output of mcflirt)
# $pcnt_rel_rms_thr1, $pcnt_rel_rms_thr2, $pcnt_rel_rms_thr3 (calculated above)
# $tSNRbrain
# $SDbrain
# $dvar_mean, $dvar_u{2-4}, $dvar_skew, $dvar_kurt
# $FWHM, $FWHM{x,y,z}

## Images to display are:
# dvars.png, disp_rel.png, disp_abs.png, trans.png, rot.png
# smoothness*.png plots
# ${mcfoutnorm}_std, ${mcfoutnorm}_tSNR, ${mcfoutnorm}_mean, $mask  
#   [Display image volumes as 5x5 or 6x6 mosaics, with mosaics "stacked" on top of each
#    other, and with an option to click/scroll through them].

## Other values to store in XML:
# P50


echo "MOTION_QC_MEAN_DVAR=$dvar_mean" >> $outfile
echo "MOTION_QC_DVAR_2Moment=$dvar_u2" >> $outfile
echo "MOTION_QC_DVAR_3Moment=$dvar_u3" >> $outfile
echo "MOTION_QC_DVAR_4Moment=$dvar_u4" >> $outfile
echo "MOTION_QC_DVAR_Skewness=$dvar_skew" >> $outfile
echo "MOTION_QC_DVAR_Kurtosis=$dvar_kurt" >> $outfile


abs_mean_rms=`cat ${mcfout}_abs_mean.rms`
echo "MOTION_QC_ABS_MEAN_RMS=$abs_mean_rms" >> $outfile

rel_mean_rms=`cat ${mcfout}_rel_mean.rms`
echo "MOTION_QC_REL_MEAN_RMS=$rel_mean_rms" >> $outfile



################################################################
# CREATE MONTAGE SLICES
#
################################################################

python $PATH_TO_PYTHON_SCRIPT/MakePictures/NiftiSlices.py -I $mcdir/${mcfoutnorm}_mean.nii.gz  -O $mcdir/${mcfoutnorm}_mean_snaps -S 6 -E 64 -N 36 -G 1 -T 20000 -B 0

python $PATH_TO_PYTHON_SCRIPT/MakePictures/NiftiSlices.py -I $mcdir/${mcfoutnorm}_std.nii.gz  -O $mcdir/${mcfoutnorm}_std_snaps -S 6 -E 64 -N 36 -G 1 -T 1000 -B 0

python $PATH_TO_PYTHON_SCRIPT/MakePictures/NiftiSlices.py -I $mcdir/${mcfoutnorm}_tSNR.nii.gz  -O $mcdir/${mcfoutnorm}_tSNR_snaps -S 6 -E 64 -N 36 -G 1 -T 50 -B 0

python $PATH_TO_PYTHON_SCRIPT/MakePictures/NiftiSlices.py -I $mcdir/$mask.nii.gz  -O $mcdir/${mask}_snaps -S 6 -E 64 -N 36 -G 1 -T 1 -B 0


################################################################
#  CLEANUP
#
################################################################

\rm -f ${mcfoutnorm}.nii.gz

\rm -f ${mcfout}.nii.gz