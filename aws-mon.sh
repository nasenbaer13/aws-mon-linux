#!/bin/bash

# Copyright (C) 2014 mooapp
#
# Licensed under the Apache License, Version 2.0 (the "License"). You may not 
# use this file except in compliance with the License. A copy of the License 
# is located at
#
#        http://www.apache.org/licenses/LICENSE-2.0
#
# or in the "LICENSE" file accompanying this file. This file is distributed 
# on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either 
# express or implied. See the License for the specific language governing 
# permissions and limitations under the License.

# TODO memory-units option
# TODO mem-used-incl-cache-buff option
# TODO from-cron option
# TODO disk-space-units option
# TODO aggregated option
# TODO auto-scaling option
# TODO disk-path input validation

# Requirement: yum install sysstat

########################################
# Initial Settings
########################################
SCRIPT_NAME=${0##*/} 
SCRIPT_VERSION=1.0 

export AWS_CLOUDWATCH_HOME=/opt/aws/apitools/mon
instanceid=`wget -q -O - http://169.254.169.254/latest/meta-data/instance-id`
azone=`wget -q -O - http://169.254.169.254/latest/meta-data/placement/availability-zone`
region=${azone/%?/}
export EC2_REGION=$region


########################################
# Usage
########################################
usage() 
{ 
    echo "Usage: $SCRIPT_NAME [options] "
    echo "Options:" 
    echo -e "\t-h|--help\tDisplays detailed usage information."
    echo -e "\t--version\tDisplays the version number."
    echo -e "\t--verify\tChecks configuration and prepares a remote call."
    echo -e "\t--verbose\tDisplays details of what the script is doing."
    echo -e "\t--debug\tDisplays information for debugging."
    echo -e "\t--aws-credential-file PATH\tProvides the location of the file containing AWS credentials. This parameter cannot be used with the --aws-access-key-id and --aws-secret-key parameters."
    echo -e "\t--aws-access-key-id VALUE\tSpecifies the AWS access key ID to use to identify the caller. Must be used together with the --aws-secret-key option. Do not use this option with the --aws-credential-file parameter."
    echo -e "\t--aws-secret-key VALUE\tSpecifies the AWS secret access key to use to sign the request to CloudWatch. Must be used together with the --aws-access-key-id option. Do not use this option with --aws-credential-file parameter."
    echo -e "\t--load-ave1\tReports load average for 1 minute in counts."
    echo -e "\t--load-ave5\tReports load average for 5 minutes in counts."
    echo -e "\t--load-ave15\tReports load average for 15 minutes in counts."
    echo -e "\t--interrupt\tReports interrupt in counts."
    echo -e "\t--context-switch\tReports context switch in counts."
    echo -e "\t--cpu-us\tReports cpu utilization (user) in percentages."
    echo -e "\t--cpu-sy\tReports cpu utilization (system) in percentages."
    echo -e "\t--cpu-id\tReports cpu utilization (idle) in percentages."
    echo -e "\t--cpu-wa\tReports cpu utilization (wait) in percentages."
    echo -e "\t--cpu-st\tReports cpu utilization (steal) in percentages."
    echo -e "\t--mem-util\tReports memory utilization in percentages."
    echo -e "\t--mem-used\tReports memory used in megabytes."
    echo -e "\t--mem-avail\tReports available memory in megabytes."
    echo -e "\t--swap-util\tReports swap utilization in percentages."
    echo -e "\t--swap-used\tReports allocated swap space in megabytes."
    echo -e "\t--swap-avail\tReports available swap space in megabytes."
    echo -e "\t--disk-path PATH\tSelects the disk by the path on which to report."
    echo -e "\t--disk-space-util\tReports disk space utilization in percentages."
    echo -e "\t--disk-space-used\tReports allocated disk space in gigabytes."
    echo -e "\t--disk-space-avail\tReports available disk space in gigabytes."
    echo -e "\t--all-items\tReports all items."
}


########################################
# Options
########################################
SHORT_OPTS="h"
LONG_OPTS="help,version,verify,verbose,debug,aws-credential-file:,aws-access-key-id:,aws-secret-key:,load-ave1,load-ave5,load-ave15,interrupt,context-switch,cpu-us,cpu-sy,cpu-id,cpu-wa,cpu-st,mem-util,mem-used,mem-avail,swap-util,swap-used,swap-avail,disk-path:,disk-space-util,disk-space-used,disk-space-avail,all-items" 

ARGS=$(getopt -s bash --options $SHORT_OPTS --longoptions $LONG_OPTS --name $SCRIPT_NAME -- "$@" ) 

VERIFY=0
VERBOSE=0
DEBUG=0
AWS_CREDENTIAL_FILE=""
AWS_ACCESS_KEY_ID=""
AWS_SECRET_KEY=""
LOAD_AVE1=0
LOAD_AVE5=0
LOAD_AVE15=0
INTERRUPT=0
CONTEXT_SWITCH=0
CPU_US=0
CPU_SY=0
CPU_ID=0
CPU_WA=0
CPU_ST=0
MEM_UTIL=0
MEM_USED=0
MEM_AVAIL=0
SWAP_UTIL=0
SWAP_USED=0
SWAP_AVAIL=0
DISK_PATH=""
DISK_SPACE_UTIL=0
DISK_SPACE_USED=0
DISK_SPACE_AVAIL=0

eval set -- "$ARGS" 
while true; do 
    case $1 in 
        # General
        -h|--help) 
            usage 
            exit 0 
            ;; 
        --version) 
            echo "$SCRIPT_VERSION" 
            ;;
        --verify)
            VERIFY=1  
            ;; 
        --verbose)
            VERBOSE=1   
            ;;
        --debug)
            DEBUG=1
            ;;
        # Credential
        --aws-credential-file)
            shift
            AWS_CREDENTIAL_FILE=$1
            ;;
        --aws-access-key-id)
            shift
            AWS_ACCESS_KEY_ID=$1
            ;;
        --aws-secret-key)
            shift
            AWS_SECRET_KEY=$1
            ;;
        # System
        --load-ave1)
            LOAD_AVE1=1
            ;;
        --load-ave5)
            LOAD_AVE5=1
            ;;
        --load-ave15)
            LOAD_AVE15=1
            ;;
        --interrupt)
            INTERRUPT=1
            ;;
        --context-switch)
            CONTEXT_SWITCH=1
            ;;
        # Cpu
        --cpu-us)
            CPU_US=1
            ;;
        --cpu-sy)
            CPU_SY=1
            ;;
        --cpu-id)
            CPU_ID=1
            ;;
        --cpu-wa)
            CPU_WA=1
            ;;
        --cpu-st)
            CPU_ST=1
            ;;
        # Memory
        --mem-util)
            MEM_UTIL=1  
            ;;
        --mem-used) 
            MEM_USED=1 
            ;;
        --mem-avail) 
            MEM_AVAIL=1 
            ;;
        --swap-util) 
            SWAP_UTIL=1 
            ;;
        --swap-used) 
            SWAP_USED=1 
            ;;
        --swap-avail)
            SWAP_AVAIL=1
            ;;
        # Disk
        --disk-path) 
            shift 
            DISK_PATH=$1
            ;; 
        --disk-space-util)
            DISK_SPACE_UTIL=1
            ;;
        --disk-space-used)
            DISK_SPACE_USED=1
            ;;
        --disk-space-avail)
            DISK_SPACE_AVAIL=1
            ;;
        --all-items)
            LOAD_AVE1=1
            LOAD_AVE5=1
            LOAD_AVE15=1
            INTERRUPT=1
            CONTEXT_SWITCH=1
            CPU_US=1
            CPU_SY=1
            CPU_ID=1
            CPU_WA=1
            CPU_ST=1
            MEM_UTIL=1
            MEM_USED=1
            MEM_AVAIL=1
            SWAP_UTIL=1
            SWAP_USED=1
            SWAP_AVAIL=1
            DISK_SPACE_UTIL=1
            DISK_SPACE_USED=1
            DISK_SPACE_AVAIL=1
            ;;
        --) 
            shift
            break 
            ;; 
        *) 
            shift
            break 
            ;; 
    esac 
    shift 
done


########################################
# Command Output
########################################
vmstat_output=`/usr/bin/vmstat`
meminfo_output=`/bin/cat /proc/meminfo`
uptime_output=`/usr/bin/uptime`
mpstat_output=`/usr/bin/mpstat`
df_output=`/bin/df -k -l -P $DISK_PATH`


########################################
# Utility Function
########################################
function getMemInfo()
{
    echo "$meminfo_output" | grep ^$1: | sed -e 's/'$1':\s*\([0-9]*\).*$/\1/'
}


########################################
# Main
########################################

# CloudWatch Command Line Interface Option
CLOUDWATCH_OPTS="--namespace \"System/Detail/Linux\" --dimensions \"InstanceId=$instanceid\""
if [ -n "$AWS_CREDENTIAL_FILE" ]; then
    CLOUDWATCH_OPTS="$CLOUDWATCH_OPTS --aws-credential-file $AWS_CREDENTIAL_FILE"
elif [ -n "$AWS_ACCESS_KEY_ID" -a -n "$AWS_SECRET_KEY" ]; then
    CLOUDWATCH_OPTS="$CLOUDWATCH_OPTS --access-key-id $AWS_ACCESS_KEY_ID --secret-key $AWS_SECRET_KEY"
else
    echo "No Credentials were provided."
    exit 1
fi

# Command Output
if [ $DEBUG -eq 1 ]; then
    echo "-----uptime-----"
    echo "$uptime_output"
    echo "-----vmstat-----"
    echo "$vmstat_output"
    echo "-----mpstat-----"
    echo "$mpstat_output"
    echo "-----/proc/meminfo-----"
    echo "$meminfo_output"
    echo "-----df-----"
    echo "$df_output"
fi

# Load Average
if [ $LOAD_AVE1 -eq 1 ]; then
    loadave1=`echo $uptime_output | tr -s ' ' | cut -d ' ' -f 10 | cut -d ',' -f 1`
    if [ $VERBOSE -eq 1 ]; then
        echo "loadave1:$loadave1"
    fi
    if [ $VERIFY -eq 0 ]; then
        /opt/aws/bin/mon-put-data --metric-name "LoadAverage1Min" --value "$loadave1" --unit "Count" $CLOUDWATCH_OPTS 
    fi
fi

if [ $LOAD_AVE5 -eq 1 ]; then
    loadave5=`echo $uptime_output | tr -s ' ' | cut -d ' ' -f 11 | cut -d ',' -f 1`
    if [ $VERBOSE -eq 1 ]; then
        echo "loadave5:$loadave5"
    fi
    if [ $VERIFY -eq 0 ]; then
        /opt/aws/bin/mon-put-data --metric-name "LoadAverage5Min" --value "$loadave5" --unit "Count" $CLOUDWATCH_OPTS
    fi
fi

if [ $LOAD_AVE15 -eq 1 ]; then
    loadave15=`echo $uptime_output | tr -s ' ' | cut -d ' ' -f 12 | cut -d ',' -f 1`
    if [ $VERBOSE -eq 1 ]; then
        echo "loadave15:$loadave15"
    fi
    if [ $VERIFY -eq 0 ]; then
        /opt/aws/bin/mon-put-data --metric-name "LoadAverage15Min" --value "$loadave15" --unit "Count" $CLOUDWATCH_OPTS
    fi
fi

# Context Switch
if [ $CONTEXT_SWITCH -eq 1 ]; then
    context_switch=`echo "$vmstat_output" | tail -1 | tr -s ' ' | cut -d ' ' -f 13`
    if [ $VERBOSE -eq 1 ]; then
        echo "context_switch:$context_switch"
    fi
    if [ $VERIFY -eq 0 ]; then
        /opt/aws/bin/mon-put-data --metric-name "ContextSwitch" --value "$context_switch" --unit "Count" $CLOUDWATCH_OPTS
    fi
fi

# Interrupt
if [ $INTERRUPT -eq 1 ]; then
    interrupt=`echo "$vmstat_output" | tail -1 | tr -s ' ' | cut -d ' ' -f 12`
    if [ $VERBOSE -eq 1 ]; then
        echo "interrupt:$interrupt"
    fi
    if [ $VERIFY -eq 0 ]; then
        /opt/aws/bin/mon-put-data --metric-name "Interrupt" --value "$interrupt" --unit "Count" $CLOUDWATCH_OPTS
    fi
fi

# Cpu
if [ $CPU_US -eq 1 ]; then
    cpu_us=`echo "$vmstat_output" | tail -1 | tr -s ' ' | cut -d ' ' -f 14`
    if [ $VERBOSE -eq 1 ]; then
        echo "cpu_us:$cpu_us"
    fi
    if [ $VERIFY -eq 0 ]; then
        /opt/aws/bin/mon-put-data --metric-name "CpuUser" --value "$cpu_us" --unit "Percent" $CLOUDWATCH_OPTS
    fi
fi

if [ $CPU_SY -eq 1 ]; then
    cpu_sy=`echo "$vmstat_output" | tail -1 | tr -s ' ' | cut -d ' ' -f 15`
    if [ $VERBOSE -eq 1 ]; then
        echo "cpu_sy:$cpu_sy"
    fi
    if [ $VERIFY -eq 0 ]; then
        /opt/aws/bin/mon-put-data --metric-name "CpuUser" --value "$cpu_sy" --unit "Percent" $CLOUDWATCH_OPTS
    fi
fi

if [ $CPU_ID -eq 1 ]; then
    cpu_id=`echo "$vmstat_output" | tail -1 | tr -s ' ' | cut -d ' ' -f 16`
    if [ $VERBOSE -eq 1 ]; then
        echo "cpu_id:$cpu_id"
    fi
    if [ $VERIFY -eq 0 ]; then
        /opt/aws/bin/mon-put-data --metric-name "CpuIdle" --value "$cpu_id" --unit "Percent" $CLOUDWATCH_OPTS
    fi
fi

if [ $CPU_WA -eq 1 ]; then
    cpu_wa=`echo "$vmstat_output" | tail -1 | tr -s ' ' | cut -d ' ' -f 17`
    if [ $VERBOSE -eq 1 ]; then
        echo "cpu_wa:$cpu_wa"
    fi
    if [ $VERIFY -eq 0 ]; then
        /opt/aws/bin/mon-put-data --metric-name "CpuWait" --value "$cpu_wa" --unit "Percent" $CLOUDWATCH_OPTS
    fi
fi

if [ $CPU_ST -eq 1 ]; then
    cpu_st=`echo "$vmstat_output" | tail -1 | tr -s ' ' | cut -d ' ' -f 18`
    if [ $VERBOSE -eq 1 ]; then
        echo "cpu_st:$cpu_st"
    fi
    if [ $VERIFY -eq 0 ]; then
        /opt/aws/bin/mon-put-data --metric-name "CpuSteal" --value "$cpu_st" --unit "Percent" $CLOUDWATCH_OPTS
    fi
fi

# Memory
mem_total=`getMemInfo "MemTotal"`
mem_free=`getMemInfo "MemFree"`
mem_cached=`getMemInfo "Cached"`
mem_buffers=`getMemInfo "Buffers"`
mem_avail=$mem_free
mem_used=`expr $mem_total - $mem_avail`
swap_total=`getMemInfo "SwapTotal"`
swap_free=`getMemInfo "SwapFree"`
swap_avail=$swap_free
swap_used=`expr $swap_total - $swap_free`

if [ $DEBUG -eq 1 ]; then
    echo "MemTotal:$mem_total"
    echo "MemFree:$mem_free"
    echo "Cached:$mem_cached"
    echo "Buffers:$mem_buffers"
    echo "SwapTotal:$swap_total"
    echo "SwapFree:$swap_free"
fi

if [ $MEM_UTIL -eq 1 -a $mem_total -gt 0 ]; then
    mem_util=`expr 100 \* $mem_used / $mem_total`
    if [ $VERBOSE -eq 1 ]; then
        echo "mem_util:$mem_util"
    fi
    if [ $VERIFY -eq 0 -a -n "$mem_util" ]; then
        /opt/aws/bin/mon-put-data --metric-name "MemoryUtilization" --value "$mem_util" --unit "Percent" $CLOUDWATCH_OPTS
    fi
fi

if [ $MEM_USED -eq 1 ]; then
    if [ $VERBOSE -eq 1 ]; then
        echo "mem_used:$mem_used"
    fi
    if [ $VERIFY -eq 0 ]; then
        /opt/aws/bin/mon-put-data --metric-name "MemoryUsed" --value "$mem_used" --unit "Kilobytes" $CLOUDWATCH_OPTS
    fi
fi

if [ $MEM_AVAIL -eq 1 ]; then
    if [ $VERBOSE -eq 1 ]; then
        echo "mem_avail:$mem_avail"
    fi
    if [ $VERIFY -eq 0 ]; then        
        /opt/aws/bin/mon-put-data --metric-name "MemoryAvailable" --value "$mem_avail" --unit "Kilobytes" $CLOUDWATCH_OPTS
    fi
fi

if [ $SWAP_UTIL -eq 1 -a $swap_total -gt 0 ]; then
    swap_util=`expr 100 \* $swap_used / $swap_total`
    if [ $VERBOSE -eq 1 ]; then
        echo "swap_util:$swap_util"
    fi
    if [ $VERIFY -eq 0 -a -n "$swap_util" ]; then
        /opt/aws/bin/mon-put-data --metric-name "SwapUtilization" --value "$swap_util" --unit "Percent" $CLOUDWATCH_OPTS
    fi
fi

if [ $SWAP_USED -eq 1 ]; then
    if [ $VERBOSE -eq 1 ]; then
        echo "swap_used:$swap_used"
    fi
    if [ $VERIFY -eq 0 ]; then
        /opt/aws/bin/mon-put-data --metric-name "SwapUsed" --value "$swap_used" --unit "Kilobytes" $CLOUDWATCH_OPTS
    fi
fi

if [ $SWAP_AVAIL -eq 1 ]; then
    if [ $VERBOSE -eq 1 ]; then
        echo "swap_avail:$swap_avail"
    fi
    if [ $VERIFY -eq 0 ]; then
        /opt/aws/bin/mon-put-data --metric-name "SwapAvailable" --value "$swap_avail" --unit "Kilobytes" $CLOUDWATCH_OPTS
    fi
fi

# Disk
disk_total=`echo "$df_output" | tail -1 | tr -s ' ' | cut -d ' ' -f 2`
disk_used=`echo "$df_output" | tail -1 | tr -s ' ' | cut -d ' ' -f 3`
disk_avail=`echo "$df_output" | tail -1 | tr -s ' ' | cut -d ' ' -f 4`

if [ $DEBUG -eq 1 ]; then
    echo "DiskTotal:$disk_total"
    echo "DiskUsed:$disk_used"
    echo "DiskAvailable:$disk_avail"
fi

if [ $DISK_SPACE_UTIL -eq 1 -a $disk_total -gt 0 ]; then
    disk_util=`expr 100 \* $disk_used / $disk_total`
    if [ $VERBOSE -eq 1 ]; then
        echo "disk_util:$disk_util"
    fi
    if [ $VERIFY -eq 0 ]; then
        /opt/aws/bin/mon-put-data --metric-name "DiskSpaceUtilization" --value "$disk_util" --unit "Percent" $CLOUDWATCH_OPTS
    fi
fi

if [ $DISK_SPACE_USED -eq 1 ]; then
    if [ $VERBOSE -eq 1 ]; then
        echo "disk_used:$disk_used"
    fi
    if [ $VERIFY -eq 0 ]; then
        /opt/aws/bin/mon-put-data --metric-name "DiskSpaceUsed" --value "$disk_used" --unit "Bytes" $CLOUDWATCH_OPTS
    fi
fi

if [ $DISK_SPACE_AVAIL -eq 1 ]; then
    if [ $VERBOSE -eq 1 ]; then
        echo "disk_avail:$disk_avail"
    fi
    if [ $VERIFY -eq 0 ]; then
        /opt/aws/bin/mon-put-data --metric-name "DiskSpaceAvailable" --value "$disk_avail" --unit "Bytes" $CLOUDWATCH_OPTS
    fi
fi
