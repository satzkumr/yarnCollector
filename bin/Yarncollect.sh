#!/bin/bash

#############################################################
# This script collects YARN related metrics
#
############################################################
# Author : Sathishkumar Manimoorthy
# Contact: mrsathishkumar12@gmail.com

#Sourcing runtime parameters

source ./runProperties
jsfile=./jstack
rmlogger=./rmlogger
metricfile=./metricfile
schedulerfile=./schedulerfile
jmapfile=./jmapfile
rmurl=`maprcli urls -name resourcemanager | grep -v url`

seconds=10				#Time interval to collect details


#Function definitions goes here

collectRM()
{
        rmpid=`ps -ef | grep resourcemanager | grep -v grep | awk '{print $2}'`
        echo "RM is running as Pid : $rmpid" >> $rmlogger
	
	echo "Collecting jmap for Resource manager: $rmpid for every $seconds" >> $rmlogger
	
	collectJmap

	#Going to infinite loop with sleep intervals to collect Jstack, application list, schduler metrics

	while(true)
	do
		
		collectJstack $rmpid
		collectRMrest
		
	done;

}


#Function collects any jstack
#Note :  This collects for single time, Please call it multiple times to get it in intervals
#usage:  collectJstack <pid>

collectJstack()
{

        pid=$1
	date=`date`
        echo "===Collecting Jstack for: $pid at $date ===" >> $jsfile
	jstack -l $pid >>$jsfile
	echo "===End of Jstack at $date ====" >> $jsfile
}



#Funciton collects jmap for the process
#Note : This funtion collects single time, Please call this function multiple times to get in intervals
#usage: collctJmap <pid>

collectJmap()
{
	pid=$1
	date=`date`
	echo "====Collecting Jmap for: $pid at $date  ====" >> rmlogger
	jmap -histo:live $pid >> $jmapfile

}

#Funciton collects RM metrics from REST API
#Note : This funtion collects single time, Please call this function multiple times to get in intervals
#Usage collctRMrest

collectRMrest()
{
	date=`date`

	echo "====Collecting RM metrics from curl at $date ====" >>$metricfile

	metricurl=`echo $rmurl/ws/v1/cluster/metrics | tr -d ' '`
	curl $metricurl >> $metricfile
	
	echo "====Collecting RM Scheduler metrics from curl at $date ====" >> $schedulerfile

	schedulerurl=`echo $rmurl/ws/v1/cluster/scheduler | tr -d ' '`

	curl $schedulerurl >> $schedulerfile

	echo "**End of collection at $date ***" >> $schedulerfile
	
	
}



#Execution starts here

if [ $# -eq 0 ];
then
	echo "Usage: Yarncollect.sh [collect target]"
	echo "      Collect target = RM for Resource Manager related Metrics"
	echo "      Colelct target = NM for Nodemanager Related metrics"
	exit 1;
fi


#Branching for collecting RM Related metrics

if [ "$1" == "RM" ];
then
	echo "Collecting $1 related params..."
	collectRM
fi


#Branching for collecting NM related Details

if [ "$1" == "NM" ];
then
	echo "Collecting $1 related params.."
	#collectNM()
fi


