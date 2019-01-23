import os

"""
Very basic test to check if all the programs have the right 
syntax and compile
"""

def clean():
    os.system("rm *json *p4i *p4rt")

def run_command(cmd ,hide_output=True):
    r = os.system(cmd + (' >/dev/null 2>&1' if hide_output else ''))
    return r


def test_syntax(list_programs_to_check):
    print("Using p4test to test program syntax:")
    print
    base_cmd = "p4test {}"
    passed = 0
    for program in list_programs_to_check:
        r = run_command(base_cmd.format(program))
        print "{} : {}".format(program, "PASSED" if r == 0 else "FAILED")
        passed += (1 if r==0 else 0)

    print "{} Tests Failed".format(len(list_programs_to_check) - passed)
    print

def test_p4c_compile(list_programs_to_check):
    print("Compiling with p4c:")
    print
    base_cmd = "p4c --target bmv2 --arch v1model {}"
    passed = 0
    for program in list_programs_to_check:
        r = run_command(base_cmd.format(program))
        print "{} : {}".format(program, "PASSED" if r == 0 else "FAILED")
        passed += (1 if r == 0 else 0)

    print "{} Tests Failed".format(len(list_programs_to_check) - passed)
    print

if __name__ == "__main__":

    programs = """
    ../read_write_registers_cli/read_write.p4
    ../meter/direct_meter.p4
    ../meter/indirect_meter.p4
    ../copy_to_cpu/copy_to_cpu.p4
    ../source_routing/p4src/source_routing.p4
    ../repeater/repeater.p4
    ../ecn/ecn.p4
    ../digest_messages/digest_messages.p4
    ../heavy_hitter/heavy_hitter.p4
    ../simple_int/p4src/simple_int.p4
    ../multiqueueing/multi_queueing.p4
    ../flowlet_switching/p4src/flowlet_switching.p4
    ../resubmit_recirculate/resubmit.p4
    ../resubmit_recirculate/recirculate.p4
    ../ecmp/p4src/ecmp.p4
    ../ip_forwarding/forwarding.p4
    ../ip_forwarding_two_tables/forwarding_two_tables.p4
    ../counter/direct_counter.p4
    ../counter/indirect_counter.p4
    ../debugging_table/debugging_table.p4
    ../digest_messages/digest_messages.p4
    ../l2_learning/p4src/l2_learning_digest.p4
    ../l2_learning/p4src/l2_learning_copy_to_cpu.p4
    ../multicast/p4src/multicast.p4
    ../recirculate/p4src/recirculate.p4
    ../recirculate_and_add_header/p4src/recirculate_and_add.p4
    ../reflector/reflector.p4
    ../stateful_firewall/stateful_firewall.p4
    ../verify_checksum/verify_checksum.p4
    """

    programs_to_test = [x.strip() for x in programs.strip().split("\n")]

    test_syntax(programs_to_test)
    test_p4c_compile(programs_to_test)
    clean()
