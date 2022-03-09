# Get config parameters:
source /users/wx21978/projects/timing/test_automation/.full_config.sh

# Source the dbt environment
cd $WORK_AREA

source dbt-env.sh
dbt-workarea-env 

if [ $MASTER_TEST -eq 1 ]
then
    echo -------------------------------------------------------------------------
    echo                             Setting up master
    echo -------------------------------------------------------------------------
    echo
    echo pdtbutler -c $CONNECTIONS_FILE io $MASTER_NAME reset $MST_RESET_OPTIONS
    pdtbutler -c $CONNECTIONS_FILE io $MASTER_NAME reset $MST_RESET_OPTIONS
    sleep 15s
    echo pdtbutler -c $CONNECTIONS_FILE mst $MASTER_NAME synctime 
    pdtbutler -c $CONNECTIONS_FILE mst $MASTER_NAME synctime 
    sleep 5s
    echo pdtbutler -c $CONNECTIONS_FILE mst $MASTER_NAME part 0 configure
    pdtbutler -c $CONNECTIONS_FILE mst $MASTER_NAME part 0 configure
    sleep 5s
    echo -------------------------------------------------------------------------
    echo

    echo
    echo #########################################################################
    echo                             .:MASTER TEST 1:.
    echo #########################################################################
    echo

    echo pdtbutler -c $CONNECTIONS_FILE io $MASTER_NAME clk-status
    pdtbutler -c $CONNECTIONS_FILE io $MASTER_NAME clk-status
    sleep 3s

    echo                             .:END OF TEST N:.
    echo
    if [ $SFP_TEST -eq 1 ]
    then
        echo #########################################################################
        echo                             .:MASTER TEST 2:.
        echo #########################################################################
        echo

        echo pdtbutler -c $CONNECTIONS_FILE io $MASTER_NAME sfp-status
        pdtbutler -c $CONNECTIONS_FILE io $MASTER_NAME sfp-status
        sleep 3s

        echo                             .:END OF TEST N:.
        echo
    fi
    echo #########################################################################
    echo                             .:MASTER TEST 3:.
    echo #########################################################################
    echo

    echo pdtbutler -c $CONNECTIONS_FILE mst $MASTER_NAME part 0 status
    pdtbutler -c $CONNECTIONS_FILE mst $MASTER_NAME part 0 status
    sleep 3s

    echo                             .:END OF TEST N:.
    echo

    if [ $MASTER_HSI -eq 1 ]
    then
        echo -------------------------------------------------------------------------
        echo                         Setting up HSI partition 1
        echo -------------------------------------------------------------------------
        echo
        echo pdtbutler -c $CONNECTIONS_FILE hsi $MASTER_NAME enable reset -a 1 -p 1
        pdtbutler -c $CONNECTIONS_FILE hsi $MASTER_NAME enable reset -a 1 -p 1
        sleep 5s
        echo -------------------------------------------------------------------------
        echo
        echo #########################################################################
        echo                             .:HSIMST TEST 1:.
        echo #########################################################################
        echo

        echo pdtbutler -c $CONNECTIONS_FILE hsi $MASTER_NAME status
        pdtbutler -c $CONNECTIONS_FILE hsi $MASTER_NAME status
        sleep 3s

        echo                             .:END OF TEST N:.
        echo
        echo -------------------------------------------------------------------------
        echo                         Setting up HSI partition 0
        echo -------------------------------------------------------------------------
        echo
        echo pdtbutler -c $CONNECTIONS_FILE hsi $MASTER_NAME enable reset -a 1 -p 0
        pdtbutler -c $CONNECTIONS_FILE hsi $MASTER_NAME enable reset -a 1 -p 0
        sleep 5s
        echo
        echo #########################################################################
        echo                             .:HSIMST TEST 2:.
        echo #########################################################################
        echo

        echo pdtbutler -c $CONNECTIONS_FILE hsi $MASTER_NAME status
        pdtbutler -c $CONNECTIONS_FILE hsi $MASTER_NAME status
        sleep 3s

        echo                             .:END OF TEST N:.
        echo
        echo -------------------------------------------------------------------------
        echo                           Configuring master HSI
        echo -------------------------------------------------------------------------
        echo
        export HSI_SOURCE=1
        if [ $LOOPBACK -eq 1 ]
        then
            export HSI_SOURCE=0
        fi
        echo pdtbutler -c $CONNECTIONS_FILE hsi $MASTER_NAME configure -r 1 -s $HSI_SOURCE --rate 62.5
        pdtbutler -c $CONNECTIONS_FILE hsi $MASTER_NAME configure -r 1 -s $HSI_SOURCE --rate 62.5
        sleep 5s
        echo -------------------------------------------------------------------------
        echo
        echo #########################################################################
        echo                             .:HSIMST TEST 3:.
        echo #########################################################################
        echo

        echo pdtbutler -c $CONNECTIONS_FILE hsi $MASTER_NAME status
        pdtbutler -c $CONNECTIONS_FILE hsi $MASTER_NAME status
        sleep 3s

        echo                             .:END OF TEST N:.
        echo
        echo -------------------------------------------------------------------------
        echo                               Stopping HSI
        echo -------------------------------------------------------------------------
        echo
        echo pdtbutler -c $CONNECTIONS_FILE hsi $MASTER_NAME stop
        pdtbutler -c $CONNECTIONS_FILE hsi $MASTER_NAME stop
        sleep 3s
        echo -------------------------------------------------------------------------
        echo
    fi
fi

if [ $ENDPOINT_TEST -eq 1 ]
then
    if ! [ $MASTER_TEST -eq 1 ]
    then
        echo -------------------------------------------------------------------------
        echo                            Configuring master
        echo -------------------------------------------------------------------------
        echo
        echo pdtbulter -c $CONNECTIONS_FILE io $MASTER_NAME reset $MST_RESET_OPTIONS
        pdtbulter -c $CONNECTIONS_FILE io $MASTER_NAME reset $MST_RESET_OPTIONS
        sleep 15s
        echo pdtbulter -c $CONNECTIONS_FILE mst $MASTER_NAME synctime
        pdtbulter -c $CONNECTIONS_FILE mst $MASTER_NAME synctime
        sleep 5s
        echo pdtbulter -c $CONNECTIONS_FILE mst $MASTER_NAME part 0 configure
        pdtbulter -c $CONNECTIONS_FILE mst $MASTER_NAME part 0 configure
        sleep 5s
        echo -------------------------------------------------------------------------
        echo
    fi
fi

cd -
