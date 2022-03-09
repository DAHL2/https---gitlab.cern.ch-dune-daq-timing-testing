# Get config parameters:
source /users/wx21978/projects/timing/test_automation/.full_config.sh

# Source the dbt environment
cd $WORK_AREA

source dbt-env.sh
dbt-workarea-env 

if [[ $EPT_CMD = ept ]]
then
    echo -------------------------------------------------------------------------
    echo                          Applying endpoint delay
    echo -------------------------------------------------------------------------
    echo
    echo pdtbutler -c $CONNECTIONS_FILE mst $MASTER_NAME align apply-delay 2 0 0 --force
    pdtbutler -c $CONNECTIONS_FILE mst $MASTER_NAME align apply-delay 2 0 0 --force
    sleep 2s
    echo -------------------------------------------------------------------------
    echo

else

    if [[ $EPT_CMD = hsi ]]
    then
        echo No additional tests

    else
        echo -------------------------------------------------------------------------
        echo                          Applying endpoint delay
        echo -------------------------------------------------------------------------
        echo
        echo pdtbutler -c $CONNECTIONS_FILE mst $MASTER_NAME align apply-delay 2 0 0 --force
        pdtbutler -c $CONNECTIONS_FILE mst $MASTER_NAME align apply-delay 2 0 0 --force
        sleep 2s
        echo -------------------------------------------------------------------------
        echo
    fi
fi

cd -
