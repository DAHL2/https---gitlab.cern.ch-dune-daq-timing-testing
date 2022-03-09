# Get config parameters:
source /users/wx21978/projects/timing/test_automation/.full_config.sh

# Source the dbt environment
cd $WORK_AREA

source dbt-env.sh
dbt-workarea-env 

if [ $LOOPBACK -eq 0 ]
then
    echo -------------------------------------------------------------------------
    echo                            Resetting endpoint
    echo -------------------------------------------------------------------------
    echo
    echo pdtbutler -c $CONNECTIONS_FILE io $ENDPOINT_NAME reset
    pdtbutler -c $CONNECTIONS_FILE io $ENDPOINT_NAME reset
    sleep 2s
    echo -------------------------------------------------------------------------
    echo

    echo #########################################################################
    echo                             .:ENDPNT TEST 1:.
    echo #########################################################################
    echo
    # Check the PLL status of the endpoint
    echo pdtbutler -c $CONNECTIONS_FILE io $ENDPOINT_NAME clk-status
    pdtbutler -c $CONNECTIONS_FILE io $ENDPOINT_NAME clk-status
    sleep 3s
    echo                             .:END OF TEST N:.
    echo
fi

if [[ $EPT_CMD = ept ]]
then
    echo -------------------------------------------------------------------------
    echo                            Setting up endpoint
    echo -------------------------------------------------------------------------
    echo
    echo pdtbutler -c $CONNECTIONS_FILE $EPT_CMD $ENDPOINT_NAME 0 enable -a 2
    pdtbutler -c $CONNECTIONS_FILE $EPT_CMD $ENDPOINT_NAME 0 enable -a 2
    sleep 2s
    echo -------------------------------------------------------------------------
    echo

    echo #########################################################################
    echo                             .:ENDPNT TEST 2:.
    echo #########################################################################
    echo
    # Check endpoint state is waiting for delay (0x6)
    echo pdtbutler -c $CONNECTIONS_FILE $EPT_CMD $ENDPOINT_NAME 0 status
    pdtbutler -c $CONNECTIONS_FILE $EPT_CMD $ENDPOINT_NAME 0 status
    sleep 2s
    echo                             .:END OF TEST N:.
    echo


else

    if [[ $EPT_CMD = hsi ]]
    then
        echo -------------------------------------------------------------------------
            echo                         Setting up HSI partition 1
            echo -------------------------------------------------------------------------
            echo
            echo pdtbutler -c $CONNECTIONS_FILE hsi $ENDPOINT_NAME enable reset -a 1 -p 1
            pdtbutler -c $CONNECTIONS_FILE hsi $ENDPOINT_NAME enable reset -a 1 -p 1
            sleep 5s
            echo -------------------------------------------------------------------------
            echo
            echo #########################################################################
            echo                             .:HSIEPT TEST 1:.
            echo #########################################################################
            echo

            echo pdtbutler -c $CONNECTIONS_FILE hsi $ENDPOINT_NAME status
            pdtbutler -c $CONNECTIONS_FILE hsi $ENDPOINT_NAME status
            sleep 3s

            echo                             .:END OF TEST N:.
            echo
            echo -------------------------------------------------------------------------
            echo                         Setting up HSI partition 0
            echo -------------------------------------------------------------------------
            echo
            echo pdtbutler -c $CONNECTIONS_FILE hsi $ENDPOINT_NAME enable reset -a 1 -p 0
            pdtbutler -c $CONNECTIONS_FILE hsi $ENDPOINT_NAME enable reset -a 1 -p 0
            sleep 5s
            echo
            echo #########################################################################
            echo                             .:HSIEPT TEST 2:.
            echo #########################################################################
            echo

            echo pdtbutler -c $CONNECTIONS_FILE hsi $ENDPOINT_NAME status
            pdtbutler -c $CONNECTIONS_FILE hsi $ENDPOINT_NAME status
            sleep 3s

            echo                             .:END OF TEST N:.
            echo
            echo -------------------------------------------------------------------------
            echo                          Configuring endpoint HSI
            echo -------------------------------------------------------------------------
            echo
            export HSI_SOURCE=1
            if [ $LOOPBACK -eq 1 ]
            then
                export HSI_SOURCE=0
            fi
            echo pdtbutler -c $CONNECTIONS_FILE hsi $ENDPOINT_NAME configure -r 1 -s $HSI_SOURCE --rate 62.5
            pdtbutler -c $CONNECTIONS_FILE hsi $ENDPOINT_NAME configure -r 1 -s $HSI_SOURCE --rate 62.5
            sleep 5s
            echo -------------------------------------------------------------------------
            echo
            echo #########################################################################
            echo                             .:HSIEPT TEST 3:.
            echo #########################################################################
            echo

            echo pdtbutler -c $CONNECTIONS_FILE hsi $ENDPOINT_NAME status
            pdtbutler -c $CONNECTIONS_FILE hsi $ENDPOINT_NAME status
            sleep 3s

            echo                             .:END OF TEST N:.
            echo
            echo -------------------------------------------------------------------------
            echo                               Stopping HSI
            echo -------------------------------------------------------------------------
            echo
            echo pdtbutler -c $CONNECTIONS_FILE hsi $ENDPOINT_NAME stop
            pdtbutler -c $CONNECTIONS_FILE hsi $ENDPOINT_NAME stop
            echo -------------------------------------------------------------------------
            echo
    else
        echo -------------------------------------------------------------------------
        echo                            Setting up endpoint
        echo -------------------------------------------------------------------------
        echo
        echo pdtbutler -c $CONNECTIONS_FILE $EPT_CMD $ENDPOINT_NAME configure 0 TimeSync
        pdtbutler -c $CONNECTIONS_FILE $EPT_CMD $ENDPOINT_NAME configure 0 TimeSync
        sleep 2s
        echo -------------------------------------------------------------------------
        echo

        echo #########################################################################
        echo                             .:CRTPNT TEST 2:.
        echo #########################################################################
        echo
        # Check endpoint state is waiting for delay (0x6)
        echo pdtbutler -c $CONNECTIONS_FILE $EPT_CMD $ENDPOINT_NAME status
        pdtbutler -c $CONNECTIONS_FILE $EPT_CMD $ENDPOINT_NAME status
        sleep 2s
        echo                             .:END OF TEST N:.
        echo

    fi
fi

cd -
