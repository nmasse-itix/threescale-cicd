#!/bin/bash

# Make sure all Ansible failed tasks go to the stderr. Failed tasks usually
# output sensitive informations, by routing them to stderr we can filter
# them out.
export ANSIBLE_DISPLAY_FAILED_STDERR=yes

cd "${0%/*}" || exit 1

echo "--> Generating the Ansible inventory files..."
ansible-playbook -i /dev/null write-inventory-files.yml &>results/write-inventory-files
ret=$?
if [ "$ret" -gt 0 ]; then
    echo "--> Ansible inventory files generation FAILED !"
    exit 1
else
    echo "--> Ansible inventory files generation SUCCEEDED !"
fi

# Because of a bug in Ansible, we need to move one directory upper before running
# the playbooks. 
# 
# The bug makes the playbooks fail after the Application Plans creation/update
# with this error message:
# 
# ERROR! Unexpected Exception, this is probably a bug: expected str, bytes or os.PathLike object, not NoneType
#
cd ".." || exit 1

for environment in tests/environments/3scale-${THREESCALE_ENV:-*}; do
    for testcase in tests/test-cases/*.y*ml; do
        echo "--> Running $testcase against $environment..."
        if [ -z "$THREESCALE_VERBOSE" ] || [ "$THREESCALE_VERBOSE" == "no" ]; then
            # reduce output verbosity and make sure not to output sensitive information
            logfile="tests/results/$(basename "$environment")-$(basename "$testcase")"
            DISPLAY_SKIPPED_HOSTS=no ANSIBLE_DISPLAY_OK_HOSTS=no ansible-playbook -i "$environment" "$testcase" 2>"$logfile"
        else
            ansible-playbook -i "$environment" -v "$testcase"
        fi
        ret=$?
        if [ "$ret" -gt 0 ]; then
            echo "--> $testcase against $environment FAILED !"
            exit 1
        else
            echo "--> $testcase against $environment SUCCEEDED !"
        fi
    done
done