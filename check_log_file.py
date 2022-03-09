import sys 
import os
import click

f_help = "Log file to submit."
v_help = "Frequency of the software (MHz)."
um_help = "UID of the master device."
ue_help = "UID of the endpoint device."

@click.command(name="Log file analysis")
@click.option("--log_file",              "-f",  help=f_help, type=str,                     default=os.path.dirname(os.path.realpath(__file__))+"/logs/first_test_log.log")
@click.option("--frequency",             "-v",  help=v_help, type=float,                   default=62.5)
@click.option("--uid_mst",               "-um",  help=um_help, type=str,                     default="0xd880395e1a6a")
@click.option("--uid_ept",               "-ue",  help=ue_help, type=str,                     default="0xd880395e1a6a")

def analyse_log_file (log_file, frequency, uid_mst, uid_ept):
    print("\n\n########################################\n########################################")
    print("                LOG TEST                ")
    print("########################################\n########################################\n")

    file = open(log_file, "r")

    tests = {".:MASTER TEST 1:.":master_pll_tests(frequency, uid_mst.lower()),
        ".:MASTER TEST 2:.":master_sfp_tests(),
        ".:MASTER TEST 3:.":master_timestamps_test(),
        ".:HSIMST TEST 1:.":hsi_waiting_test(),
        ".:HSIMST TEST 2:.":hsi_ready_test(),
        ".:HSIMST TEST 3:.":hsi_buffer_test(),
        ".:ENDPNT TEST 1:.":endpoint_pll_tests(frequency, uid_ept.lower()),
        ".:ENDPNT TEST 2:.":endpoint_waiting_test(),
        ".:ENDPNT TEST 3:.":endpoint_ready_test(),
        ".:CRTPNT TEST 2:.":crt_waiting_test(),
        ".:CRTPNT TEST 3:.":crt_ready_test(),
        ".:HSIEPT TEST 1:.":hsi_waiting_test(),
        ".:HSIEPT TEST 2:.":hsi_ready_test(),
        ".:HSIEPT TEST 3:.":hsi_buffer_test(),
        ".:END OF TEST N:.":dummy_test()}

    l = file.readline()

    curr_test = ".:END OF TEST N:."

    total_success = 0
    total_fail = 0
    total_unknown = 0

    error_status = 0
    error_text = []

    while l:
        error_status, error_text = find_exceptions(l, error_status, error_text)
        if l[-18:-1] in tests.keys():
            success, fail, unknown = tests[curr_test].test_end()
            total_success += success
            total_fail += fail
            total_unknown += unknown
            curr_test = l[-18:-1]
        else:
            tests[curr_test].check_line(l)
        l = file.readline()

    print("Overall:\n{} success(es)\n{} failure(s)\n{} unknown\n{} exception(s)".format(total_success, total_fail, total_unknown, int(error_status/4)))

    return

def find_exceptions(line, status, text):
    if status%4 == 3:
        print("\n\n####################\nEXCEPTION FOUND:\n####################\n")
        print(*text)
        status += 1
        text = []
    if status%4 == 2 or status%4 == 1:
        if line[:20] == "--------------------":
            status += 1
        text += [line]
    elif "Exception in user code:" in line and status%4 == 0:
        status += 1
        text += [line]
    return status, text


class log_test:
    def __init__(self):
        self.test_package_ = ""
        self.status_ = {}
        self.reqs_ = {}
        self.tests_ = {}
        self.output_text_ = {}

        self.successes = 0
        self.failures = 0
        self.unknowns = 0
        return

    def _add_test(self, test_name, test_req, test_func, output_text):
        self.status_.update({test_name:63})
        self.reqs_.update({test_name:test_req})
        self.tests_.update({test_name:test_func})
        self.output_text_.update({test_name:output_text})
        return

    def _get_last_table_entry(self, line):
        return line.split('|')[-2].strip()
    
    def check_line(self, line):
        for test_point in self.reqs_.keys():
            if self.reqs_[test_point][1:-1] in line:
                self.output_text_[test_point] += line
                self.status_[test_point] = self.tests_[test_point](line)
        return

    def test_end(self):
        for test_point in self.status_.keys():
            if self.status_[test_point] == 0:
                self.successes += 1
                print("--------------------\n")
                print("Test \""+test_point+"\" successfully passed with the following output:\n")
                print(self.output_text_[test_point])
                print()
            elif self.status_[test_point] == 1:
                self.failures += 1
                print("xxxxxxxxxxxxxxxxxxxx\n")
                print("Test \""+test_point+"\" FAILED with the following output:\n")
                print(self.output_text_[test_point])
                print()
            else:
                self.unknowns += 1
                print("oooooooooooooooooooo\n")
                print("Test \""+test_point+"\" NOT FOUND in the log file.")
        print("####################\n\n" \
            + "Test package \"" + self.test_package_ + "\" called with {} success(es), {} failure(s) and {} unknown(s).".format(self.successes, self.failures, self.unknowns) \
            + "\n\n####################\n")
        return self.successes, self.failures, self.unknowns


class dummy_test(log_test):
    def __init__(self):
        super().__init__()
        return   
    
    def test_end(self):
        return 0,0,0


class master_pll_tests(log_test):
    def __init__(self, frequency, uid):
        super().__init__()
        self.test_package_ = "Master PLL tests"

        self.freq_ = frequency
        self.uid_ = uid

        self.pll_context_ = "----------PLL state----------\n" \
                          + "+-------------------+-------+\n" \
                          + "|      Register     | Value |\n" \
                          + "+-------------------+-------+\n"

        self._add_test("uid",      "|         Board UID        |", self.uid_test,  "+--------------------------+----------------+\n")
        self._add_test("pll_freq", "PLL freq: ",                   self.freq_test, "PLL Clock frequency measurement:\n")
        self._add_test("cdr_freq", "CDR freq: ",                   self.freq_test, "")
        # self._add_test("lol",      "|        LOL        |",        self.loss_test, self.pll_context_)
        # self._add_test("los",      "|        LOS        |",        self.loss_test, self.pll_context_)
        return
    
    def uid_test(self, line):
        line_data = self._get_last_table_entry(line)
        if line_data[-len(self.uid_):] == self.uid_:
            return 0
        else:
            return 1

    def freq_test(self, line):
        line_data = round(float(line.rstrip()[10:-1]),1)
        if line_data == self.freq_*5 or line_data == self.freq_:
            return 0
        else:
            return 1
    
    def loss_test(self, line):
        line_data = self._get_last_table_entry(line)
        if line_data == '0' or line_data == '0x0':
            return 0
        else:
            return 1

class endpoint_pll_tests(master_pll_tests):
    def __init__(self, frequency, uid):
        super().__init__(frequency, uid)
        self.test_package_ = "Endpoint PLL tests"
        
        self._add_test("lol",      "|        LOL        |",        self.loss_test, self.pll_context_)
        self._add_test("los",      "|        LOS        |",        self.loss_test, self.pll_context_)
        return


class master_sfp_tests(log_test):
    def __init__(self):
        super().__init__()
        self.test_package_ = "Master SFP tests"

        self.pll_context_ = "+-------------------+-------+\n" \
                          + "|      Register     | Value |\n" \
                          + "+-------------------+-------+"

        self._add_test("temperature", "|   Temperature  |", self.gen_test(2, 30, 60),     "--------------SFP status-------------\n+----------------+------------------+\n")
        self._add_test("voltage",     "| Supply voltage |", self.gen_test(2, 2.5, 4.),    "+----------------+------------------+\n")
        self._add_test("rx_power",    "|    Rx power    |", self.gen_test(3, 200., 900.), "+----------------+------------------+\n")
        self._add_test("tx_power",    "|    Tx power    |", self.gen_test(3, 200., 900.), "+----------------+------------------+\n")
        self._add_test("current",     "|   Tx current   |", self.gen_test(3, 2., 24.),    "+----------------+------------------+\n")
        return
    
    def gen_test(self, strip, min, max):
        def test_func(line):
            line_data = float(self._get_last_table_entry(line)[:-strip])
            if line_data > min and line_data < max:
                return 0
            else:
                return 1
        return test_func

class master_timestamps_test(log_test):
    def __init__(self):
        super().__init__()
        self.test_package_ = "Master timestamp"

        self.output_context_ ="+-------------+-----------------+-----------------+\n" \
                            + "|             | Accept counters | Reject counters |\n" \
                            + "+-------------+-----------------+-----------------+\n" \
                            + "|     Cmd     |  cnts  |   hex  |  cnts  |   hex  |\n" \
                            + "+-------------+--------+--------+--------+--------+\n"

        self._add_test("timestamp", "|   TimeSync  |", self.time_sync_test, self.output_context_)    
        return    
    
    def time_sync_test (self, line):
        line_elements = line.split('|')
        line_data = []
        for ele in line_elements:
            test_ele = ele.strip()
            if test_ele.isnumeric():
                line_data += [int(test_ele)]
        
        if line_data[0] > 0 and line_data[1] == 0:
            return 0
        else:
            return 1

class endpoint_waiting_test(log_test):
    def __init__(self):
        super().__init__()
        self.test_package_ = "Endpoint waiting state"

        self.output_context_ ="--- Endpoint state ---\n" \
                            + "+------------+----------+\n" \
                            + "|  Endpoint  |    0     |\n" \
                            + "+------------+----------+\n"

        self._add_test("waiting", "| ep_stat    |", self.waiting_test, self.output_context_)    
        return    
    
    def waiting_test(self, line):
        line_data = self._get_last_table_entry(line)
        if line_data == '0x6':
            return 0
        else:
            return 1

class endpoint_ready_test(log_test):
    def __init__(self):
        super().__init__()
        self.test_package_ = "Endpoint ready state"

        self.output_context_ ="--- Endpoint state ---\n" \
                            + "+------------+----------+\n" \
                            + "|  Endpoint  |    0     |\n" \
                            + "+------------+----------+\n"

        self._add_test("ready", "| ep_stat    |", self.ready_test, self.output_context_)    
        return    
    
    def ready_test(self, line):
        line_data = self._get_last_table_entry(line)
        if line_data == '0x8':
            return 0
        else:
            return 1

class crt_waiting_test(log_test):
    def __init__(self):
        super().__init__()
        self.test_package_ = "CRT waiting state"

        self.output_context_ ="------------CRT state------------\n" \
                            + "+------------------+------------+\n"

        self._add_test("waiting", "| csr.stat.ep_stat |", self.waiting_test, self.output_context_)    
        return    
    
    def waiting_test(self, line):
        line_data = self._get_last_table_entry(line)
        if line_data == '0x6':
            return 0
        else:
            return 1

class crt_ready_test(log_test):
    def __init__(self):
        super().__init__()
        self.test_package_ = "CRT ready state"

        self.output_context_ ="------------CRT state------------\n" \
                            + "+------------------+------------+\n"

        self.pulse_count_ = None
        self.init_state_ = None

        self._add_test("ready", "| csr.stat.ep_stat |", self.ready_test, self.output_context_) 
        self._add_test("pulses", "|     pulse.cnt    |", self.pulse_test, self.output_context_)   
        return    
    
    def ready_test(self, line):
        if self.init_state_:
            line_data = self._get_last_table_entry(line)
            if line_data == '0x8' and self.init_state_ == '0x8':
                return 0
            else:
                return 1
        else:
            self.init_state_ = self._get_last_table_entry(line)
            return 63

    def pulse_test(self, line):
        if self.pulse_count_:
            pulses = int(self._get_last_table_entry(line), 16) - self.pulse_count_
            if pulses == 10 or pulses == 11:
                return 0
            else:
                return 1
        else:
            self.pulse_count_ = int(self._get_last_table_entry(line), 16)
            return 63


class hsi_waiting_test(log_test):
    def __init__(self):
        super().__init__()
        self.test_package_ = "HSI waiting state"

        self.output_context_ ="----------------------Endpoint summary---------------------\n" \
                            + "+-----------+---------------------------------------------+\n"

        self._add_test("hsi_waiting", "|  State  |", self.waiting_test, self.output_context_)    
        return    
    
    def waiting_test(self, line):
        line_data = self._get_last_table_entry(line)
        if line_data == 'Waiting for time stamp initialisation (0x7)':
            return 0
        else:
            return 1

class hsi_ready_test(log_test):
    def __init__(self):
        super().__init__()
        self.test_package_ = "HSI ready state"

        self.output_context_ ="------Endpoint summary-----\n" \
                            + "+-----------+-------------+\n"

        self._add_test("hsi_ready", "|  State  |", self.ready_test, self.output_context_)    
        return    
    
    def ready_test(self, line):
        line_data = self._get_last_table_entry(line)
        if line_data == 'Ready (0x8)':
            return 0
        else:
            return 1

class hsi_buffer_test(log_test):
    def __init__(self):
        super().__init__()
        self.test_package_ = "HSI buffer test"

        self.output_context_ ="--------HSI summary--------\n" \
                            + "+-------------------+-----+\n"

        self._add_test("hsi_buffer", "| Buffer occupancy |", self.buffer_test, self.output_context_)    
        return    
    
    def buffer_test(self, line):
        line_data = self._get_last_table_entry(line)
        if int(line_data) > 4:
            return 0
        else:
            return 1

if __name__ == '__main__':
    analyse_log_file()