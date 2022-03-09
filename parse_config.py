import sys 
import os
import click
import datetime

f_help = "Config file to parse."

@click.command(name="Log file analysis")
@click.option("--config_file",           "-f",   help=f_help,  type=str,                     default="/users/wx21978/projects/timing/test_automation/test_config.cfg")

def parse_config_file(config_file):
    softwares = [
        'boreas',
        'chronos',
        'crt',
        'endpoint',
        'fanout',
        'ouroboros',
        'overlord'
    ]

    hardwares = [
        'pc053a',
        'pc053d',
        'pc059',
        'tlu',
        'fib'
    ]

    # boards = [
    #     'fmc', # This is the enclustra!
    #     'nexys_video'
    # ]

    print("Parsing config file...")

    cfg = open(config_file, 'r')
    full_cfg = open(os.path.dirname(os.path.realpath(__file__))+"/.full_config.sh", 'w')
    
    l = cfg.readline()

    while l:
        if not '#' in l:
            if "MASTER_BITFILE_PATH" in l:
                master_bitfile = l.rstrip().split('=')[-1]
            if "ENDPOINT_BITFILE_PATH" in l:
                endpoint_bitfile = l.rstrip().split('=')[-1]
            if "MASTER_UID" in l:
                master_uid = l.rstrip().split('=')[-1]
            if "ENDPOINT_UID" in l:
                endpoint_uid = l.rstrip().split('=')[-1]
        full_cfg.write(l)
        l = cfg.readline()
    cfg.close()
    # TODO Check all these variables have in fact been found!

    full_cfg.write('\n\n# Created variables\n')
    # Work out the software of the devices
    for sw in softwares:
        if sw in master_bitfile:
            master_software = sw
        if sw in endpoint_bitfile:
            endpoint_software = sw

    # Export the software for use in the log file name, and determine whether we have loopback
    full_cfg.write("export TEST_SOFTWARE_MASTER="+master_software+"\n")
    if master_bitfile == endpoint_bitfile:
        full_cfg.write("export TEST_SOFTWARE_ENDPOINT=loopback\n")
        full_cfg.write("export LOOPBACK=1\n")
        endpoint_uid = master_uid
    else:
        full_cfg.write("export TEST_SOFTWARE_ENDPOINT="+endpoint_software+"\n")
        full_cfg.write("export LOOPBACK=0\n")

    # Work out and export the hardware of the devices
    for hw in hardwares:
        if hw in master_bitfile:
            master_hardware = hw
            # If we're not pc053, we know we are enclustra
            if not (master_hardware == "pc053a" or master_hardware == "pc053d"):
                full_cfg.write("export TEST_HARDWARE_MASTER="+master_hardware+"\n")
            else:
                # If we are pc053, we want to check if we're on enclustra or nexys
                if 'nexys_video' in master_bitfile:
                    full_cfg.write("export TEST_HARDWARE_MASTER=nexys\n")
                else:
                    full_cfg.write("export TEST_HARDWARE_MASTER=enclustra\n")
        if hw in endpoint_bitfile:
            endpoint_hardware = hw
            if not (endpoint_hardware == "pc053a" or endpoint_hardware == "pc053d"):
                full_cfg.write("export TEST_HARDWARE_ENDPOINT="+endpoint_hardware+"\n")
            else:
                # If we are pc053, we want to check if we're on enclustra or nexys
                if 'nexys_video' in endpoint_bitfile:
                    full_cfg.write("export TEST_HARDWARE_ENDPOINT=nexys\n")
                else:
                    full_cfg.write("export TEST_HARDWARE_ENDPOINT=enclustra\n")
            

    # Work out the address table for the devices:
    master_address = get_address_table(master_software, master_hardware)
    endpoint_address = get_address_table(endpoint_software, endpoint_hardware)

    # # Work out the board the devices are on
    # if 'nexys_video' in master_bitfile:
    #     master_board = 'nexys'
    # else:
    #     master_board = 'enclustra'

    # if 'nexys_video' in endpoint_bitfile:
    #     master_board = 'nexys'
    # else:
    #     master_board = 'enclustra'
    
    # Determine whether to do HSI tests
    if master_software == 'boreas':
        full_cfg.write("export MASTER_HSI=1\n")
    else:
        full_cfg.write("export MASTER_HSI=0\n")

    # if endpoint_software == 'chronos':
    #     full_cfg.write("export ENDPNT_HSI=1\n")
    # else:
    #     full_cfg.write("export ENDPNT_HSI=0\n")

    # Determine whether to do SFP tests
    if master_hardware == 'tlu':
        full_cfg.write("export SFP_TEST=0\n")
    else:
        full_cfg.write("export SFP_TEST=1\n")
    
    # Determine whether we need to add the fanout mode option
    if master_software == 'fanout':
        full_cfg.write('export MST_RESET_OPTIONS="--fanout-mode 1"\n')
    else:
        full_cfg.write("export MST_RESET_OPTIONS=\n")

    # Determing the type of endpoint
    if endpoint_software == 'chronos':
        full_cfg.write('export EPT_CMD="hsi"\n')
    elif endpoint_software == 'crt':
        full_cfg.write('export EPT_CMD="crt"\n')
    else:
        full_cfg.write('export EPT_CMD="ept"\n')

    # Determine the frequency
    if "50_mhz" in master_bitfile:
        full_cfg.write("export FREQ=50.0\n")
    else:
        full_cfg.write("export FREQ=62.5\n")

    mst_ip, ept_ip = get_ips(master_uid, endpoint_uid)
    # TODO how to deal with case of multiple computers
    if mst_ip == '':
        print("Mac address of master: "+master_uid+", not found in ethers file. Aborted.")
        # full_cfg.write("export GOOD_CFG=0\n")
    if ept_ip == '':
        print("Mac address of endpoint: "+endpoint_uid+", not found in ethers file. Aborted.")
        # full_cfg.write("export GOOD_CFG=0\n")
    # TODO In the future this should no longer be the case, hopefully just need to remove these lines
    if master_hardware == 'fib':
        mst_ip = "192.168.121.100"

    connections_file = make_connections_file(mst_ip, ept_ip, master_address, endpoint_address)
    
    full_cfg.write("export CONNECTIONS_FILE="+connections_file+"\n")

    full_cfg.write('export MASTER_NAME="TEST_MST"\n')
    full_cfg.write('export ENDPOINT_NAME="TEST_EPT"\n')

    # # Indicate the config file is valid
    # full_cfg.write("export GOOD_CFG=1\n")
    full_cfg.close()
    return

# def make_from_connections_file(mst_ip, ept_ip, mst_address, ept_address):
    # # base_file = open(os.path.dirname(os.path.realpath(__file__))+"/base_connections.xml", 'r')
    # base_file = open("/users/wx21978/projects/timing/connections.xml", 'r')
    # new_path = os.path.dirname(os.path.realpath(__file__))+"/run_connections.xml"
    # connections = open(new_path, 'w')
    
    # l = base_file.readline()

    # while l:
    #     if "TEST_MST" in l:
    #         l = '  <connection id="TEST_MST"          uri="ipbusudp-2.0://'+mst_ip+':50001" address_table="file://${{TIMING_SHARE}}/config/etc/addrtab/v610/'+mst_address+'.xml" />\n'
    #     elif "TEST_EPT" in l:
    #         l = '  <connection id="TEST_EPT"          uri="ipbusudp-2.0://'+ept_ip+':50001" address_table="file:///${{TIMING_SHARE}}/config/etc/addrtab/v610/'+ept_address+'.xml" />\n'
    #     connections.write(l)
    #     l = base_file.readline()

    # base_file.close()
    # connections.close()

    # return new_path

def make_connections_file(mst_ip, ept_ip, mst_address, ept_address):
    file_path = os.path.dirname(os.path.realpath(__file__))+"/test_connections.xml"
    connections = open(file_path, 'w')
    
    connections.write('<?xml version="1.0" encoding="UTF-8"?>\n')
    connections.write('\n')
    connections.write('<connections>\n')
    connections.write('  <connection id="TEST_MST"          uri="ipbusudp-2.0://'+mst_ip+':50001" address_table="file://${TIMING_SHARE}/config/etc/addrtab/v610/'+mst_address+'.xml" />\n')
    connections.write('  <connection id="TEST_EPT"          uri="ipbusudp-2.0://'+ept_ip+':50001" address_table="file:///${TIMING_SHARE}/config/etc/addrtab/v610/'+ept_address+'.xml" />\n')
    connections.write('</connections>\n')

    connections.close()

    return file_path

def get_address_table(software, hardware):
    complex_softwares = [
        'boreas',
        'fanout',
        'ouroboros',
        'overlord'
    ]

    complex_hardwares = [
        'tlu',
        'fib',
        'pc059'
    ]
    
    if software in complex_softwares and hardware in complex_hardwares:
        if software == "boreas" and hardware == 'pc059':
            return software+"_fmc/top_fmc"
        else:
            return software+"_"+hardware+"/top_"+hardware
    elif software == "boreas" or software == "overlord":
        return software+"_fmc/top_fmc"
    elif software == "fanout":
        return software+"_"+hardware+"/top"
    else:
        return software+"_fmc/top"
    

def get_ips(mst_uid, ept_uid, ethers="/etc/ethers"):
    mst_formatted = format_uid(mst_uid)
    ept_formatted = format_uid(ept_uid)

    mst_ip=''
    ept_ip=''

    ips = open(ethers, 'r')

    l = ips.readline()

    while l:
        line = l.lower().rstrip().split(' ')
        mac = line[0]
        ip = line[1]
        if mac[-len(mst_formatted):] == mst_formatted:
            mst_ip = ip
        if mac[-len(ept_formatted):] == ept_formatted:
            ept_ip = ip
        l = ips.readline()

    return mst_ip, ept_ip

def format_uid(uid):
    uid_len = len(uid)
    # Split into segments length two form the right
    uid_split = [uid[-i-2:uid_len-i] for i in range(0, uid_len, 2)]
    # Reverse the order
    uid_split.reverse()
    # Join with :
    return ':'.join(uid_split).lower()

if __name__ == '__main__':
    parse_config_file()