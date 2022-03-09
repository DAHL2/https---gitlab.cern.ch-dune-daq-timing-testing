# Get config parameters:
source /users/wx21978/projects/timing/test_automation/.full_config.sh

# Source the dbt environment
cd $WORK_AREA

source dbt-env.sh
dbt-workarea-env 

if [[ $EPT_CMD = ept ]]
then
    echo #########################################################################
    echo                             .:ENDPNT TEST 3:.
    echo #########################################################################
    echo
    # Check endpoint state is ready (0x8)
    echo pdtbutler -c $CONNECTIONS_FILE $EPT_CMD $ENDPOINT_NAME 0 status
    pdtbutler -c $CONNECTIONS_FILE $EPT_CMD $ENDPOINT_NAME 0 status
    echo                             .:END OF TEST N:.
    echo

else

    if [[ $EPT_CMD = hsi ]]
    then
        echo No additional tests...
    else
        echo #########################################################################
        echo                             .:CRTPNT TEST 3:.
        echo #########################################################################
        echo
        # Check endpoint state is ready (0x8)
        echo pdtbutler -c $CONNECTIONS_FILE $EPT_CMD $ENDPOINT_NAME status
        pdtbutler -c $CONNECTIONS_FILE $EPT_CMD $ENDPOINT_NAME status
        sleep 10s
        echo
        # Get status again after 10s to check pulse rate
        echo pdtbutler -c $CONNECTIONS_FILE $EPT_CMD $ENDPOINT_NAME status
        pdtbutler -c $CONNECTIONS_FILE $EPT_CMD $ENDPOINT_NAME status
        echo                             .:END OF TEST N:.
        echo
    fi
fi

cd -
