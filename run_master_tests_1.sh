# Get config parameters:
source /users/wx21978/projects/timing/test_automation/.full_config.sh

echo "#########################################################################" >> $LOG_STORAGE_FOLDER/$LOG_NAME.log 2>&1
echo "#########################################################################" >> $LOG_STORAGE_FOLDER/$LOG_NAME.log 2>&1
echo "                             Beginning tests                             " >> $LOG_STORAGE_FOLDER/$LOG_NAME.log 2>&1
echo "#########################################################################" >> $LOG_STORAGE_FOLDER/$LOG_NAME.log 2>&1
echo "#########################################################################" >> $LOG_STORAGE_FOLDER/$LOG_NAME.log 2>&1
echo >> $LOG_STORAGE_FOLDER/$LOG_NAME.log 2>&1

bash /users/wx21978/projects/timing/test_automation/master_tests_1.sh >> $LOG_STORAGE_FOLDER/$LOG_NAME.log 2>&1

if [ $ENDPOINT_TEST -eq 1 ]
then
  echo Master tests have been run.
  echo Please now run the following file from the computer connected to the endpoint:
  echo /users/wx21978/projects/timing/test_automation/run_endpoint_tests_1.sh
else
  echo >> $LOG_STORAGE_FOLDER/$LOG_NAME.log 2>&1
  echo >> $LOG_STORAGE_FOLDER/$LOG_NAME.log 2>&1
  echo "#########################################################################" >> $LOG_STORAGE_FOLDER/$LOG_NAME.log 2>&1
  echo "#########################################################################" >> $LOG_STORAGE_FOLDER/$LOG_NAME.log 2>&1
  echo "                           Analysing log file                            " >> $LOG_STORAGE_FOLDER/$LOG_NAME.log 2>&1
  echo "#########################################################################" >> $LOG_STORAGE_FOLDER/$LOG_NAME.log 2>&1
  echo "#########################################################################" >> $LOG_STORAGE_FOLDER/$LOG_NAME.log 2>&1
  echo >> $LOG_STORAGE_FOLDER/$LOG_NAME.log 2>&1

  echo Created log

  source /software/wx21978/miniconda/bin/activate
  conda activate daq_tests

  python /users/wx21978/projects/timing/test_automation/check_log_file.py -f $LOG_STORAGE_FOLDER/$LOG_NAME.log --frequency $FREQ --uid_mst $MASTER_UID --uid_ept $ENDPOINT_UID | tee -a $LOG_STORAGE_FOLDER/$LOG_NAME.log

fi
