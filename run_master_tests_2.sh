# Get config parameters:
source /users/wx21978/projects/timing/test_automation/.full_config.sh

bash /users/wx21978/projects/timing/test_automation/master_tests_2.sh >> $LOG_STORAGE_FOLDER/$LOG_NAME.log 2>&1

echo Delay has now been applied to the master.
echo Please now run the following file from the computer connected to the endpoint:
echo /users/wx21978/projects/timing/test_automation/run_endpoint_tests_2.sh
