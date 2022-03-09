# Get config parameters:
source /users/wx21978/projects/timing/test_automation/.full_config.sh

echo #########################################################################
echo #########################################################################
echo                              Beginning tests
echo #########################################################################
echo #########################################################################
echo

/users/wx21978/projects/timing/test_automation/master_tests_1.sh >> $LOG_STORAGE_FOLDER/$LOG_NAME.log 2>&1

if [ $ENDPOINT_TEST -eq 1 ]
then
    /users/wx21978/projects/timing/test_automation/endpoint_tests_1.sh >> $LOG_STORAGE_FOLDER/$LOG_NAME.log 2>&1

    if [[ $EPT_CMD = hsi ]]
    then
        echo
    else
        /users/wx21978/projects/timing/test_automation/master_tests_2.sh >> $LOG_STORAGE_FOLDER/$LOG_NAME.log 2>&1
        
        /users/wx21978/projects/timing/test_automation/endpoint_tests_2.sh >> $LOG_STORAGE_FOLDER/$LOG_NAME.log 2>&1
    fi
fi

echo
echo
echo #########################################################################
echo #########################################################################
echo                            Analysing log file
echo #########################################################################
echo #########################################################################
echo

cd -
