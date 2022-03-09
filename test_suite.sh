# Arguments:
# - $1 Config file to use

export AUTO_COMPLETE='false'
export MULTI_COMPUTERS=0
while getopts 'ynm' opt; do
  case $opt in
    y)
      export AUTO_COMPLETE='y';;
    n)
      export AUTO_COMPLETE='N';;
    m)
      export MULTI_COMPUTERS=1;;
  esac  
done
shift $(($OPTIND - 1))

# Source python
source /software/wx21978/miniconda/bin/activate
conda activate daq_tests

# Get the config parameters and source the created file
python /users/wx21978/projects/timing/test_automation/parse_config.py -f $1

source /users/wx21978/projects/timing/test_automation/.full_config.sh

if [[ $TEST_HARDWARE_MASTER = 'fib' ]]
then
  echo
  echo Programming the fib cannot be scripted.
  echo Please ensure you have correctly programmed the fib with the expected bitfile:
  echo $MASTER_BITFILE_PATH
  read -p "Then confirm with [y] to continue or [n] to abort: " yesno
  case $yesno in
    [Yy]* )
      echo Continuing... ;;
    [Nn]* )
      echo Aborting.
      exit 2;;
    * )
      echo Please confirm with [y/n]:;;
  esac
else
  echo Downloading bitfile from $MASTER_BITFILE_PATH
  echo

  wget -P $TEMP_STORAGE_FOLDER/mst/ $MASTER_BITFILE_PATH
  tar -xzf $TEMP_STORAGE_FOLDER/mst/*.tgz -C $TEMP_STORAGE_FOLDER/mst/
  rm $TEMP_STORAGE_FOLDER/mst/*.tgz

  export BITFILE=$TEMP_STORAGE_FOLDER/mst/*/*.bit

  echo
  echo Loading $BITFILE...
  echo

  if [[] $AUTO_COMPLETE = 'false' ]]
  then
    /users/wx21978/projects/timing/test_automation/load_bitfile.sh $BITFILE $MASTER_JTAG
  else
    echo $AUTO_COMPLETE | /users/wx21978/projects/timing/test_automation/load_bitfile.sh $BITFILE $MASTER_JTAG
  fi

  echo
  echo Loaded bitfile
  echo
fi

if [ $LOOPBACK -eq 0 ]
then
  echo -----------------------------------------------------------
  echo Loading endpoint bitfile...
  echo
  echo Downloading bitfile from $ENDPOINT_BITFILE_PATH
  echo
  
  wget -P $TEMP_STORAGE_FOLDER/edpt/ $ENDPOINT_BITFILE_PATH
  tar -xzf $TEMP_STORAGE_FOLDER/edpt/*.tgz -C $TEMP_STORAGE_FOLDER/edpt/
  rm $TEMP_STORAGE_FOLDER/edpt/*.tgz
  
  echo $TEMP_STORAGE_FOLDER/edpt/*/*.bit

  export BITFILE=$TEMP_STORAGE_FOLDER/edpt/*/*.bit
  
  echo
  echo Loading $BITFILE...
  echo
  
  if [[ $AUTO_COMPLETE = 'false' ]]
  then
    /users/wx21978/projects/timing/test_automation/load_bitfile.sh $BITFILE $ENDPOINT_JTAG
  else
    echo $AUTO_COMPLETE | /users/wx21978/projects/timing/test_automation/load_bitfile.sh $BITFILE $ENDPOINT_JTAG
  fi
  
  echo
  echo Loaded endpoint bitfile
  echo
fi

rm -r $TEMP_STORAGE_FOLDER/*

echo -----------------------------------------------------------
sleep 5s
echo
echo Creating test log
echo

CURRENT_DATE=$( date +'%Y-%m-%d_%H-%M' )
export LOG_NAME=${TEST_TAG}_${TEST_SOFTWARE_MASTER}-${TEST_HARDWARE_MASTER}_${TEST_SOFTWARE_ENDPOINT}-${TEST_HARDWARE_ENDPOINT}_${FREQ}-mhz_${CURRENT_DATE}

echo "export LOG_NAME=${LOG_NAME}" >> /users/wx21978/projects/timing/test_automation/.full_config.sh

cp /users/wx21978/projects/timing/test_automation/.full_config.sh $LOG_STORAGE_FOLDER/$LOG_NAME.log

if [ $MULTI_COMPUTERS -eq 0 ]
then
  /users/wx21978/projects/timing/test_automation/run_tests.sh >> $LOG_STORAGE_FOLDER/$LOG_NAME.log 2>&1

  echo Created log

  python /users/wx21978/projects/timing/test_automation/check_log_file.py -f $LOG_STORAGE_FOLDER/$LOG_NAME.log --frequency $FREQ --uid_mst $MASTER_UID --uid_ept $ENDPOINT_UID | tee -a $LOG_STORAGE_FOLDER/$LOG_NAME.log

else
  echo
  echo You have specified that the devices must be accessed from multiple computers.
  echo The following files must be run from the corresponding computers in this order:
  echo /users/wx21978/projects/timing/test_automation/run_master_tests_1.sh
  if [ $ENDPOINT_TEST -eq 1 ]
  then
    echo /users/wx21978/projects/timing/test_automation/run_endpoint_tests_1.sh
    if ! [[ $EPT_CMD = 'hsi' ]]
    then
      echo /users/wx21978/projects/timing/test_automation/run_master_tests_2.sh
      echo /users/wx21978/projects/timing/test_automation/run_endpoint_tests_2.sh
    fi
  fi
  echo
  echo Please run the following file now from the computer connected to the master device:
  echo /users/wx21978/projects/timing/test_automation/run_master_tests_1.sh

fi
