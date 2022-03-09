# Arguments:
#   $1 - Bitfile to load
#   $2 - Mac address of the board

source /users/wx21978/projects/timing/ipbb-dev-2020g/env.sh
source /software/CAD/Xilinx/2020.2/Vivado/2020.2/settings64.sh 

# Move to a new folder to catch all the logs etc. vivado creates
cd /users/wx21978/projects/timing/test_automation/vivado


if [[ $1 = *nexys_video* ]]
then
    export COMPONENT_ID="$2:xc7a200t_0"
else
    export COMPONENT_ID="$2:xc7a35t_0"
fi


ipb-prog vivado program $COMPONENT_ID $1

cd -
