#!/bin/bash

#############################################################
# This script collects YARN related metrics
#
############################################################
# Author : Sathishkumar Manimoorthy
# Contact: mrsathishkumar12@gmail.com

#Sourcing runtime parameters

source ./runProperties
rundate=`date +%Y-%m-%d:%H:%M`

#Preparing execution
outdir="collectout_$rundate$1"
mkdir -p ./$outdir

jsfile=./$outdir/jstack
rmlogger=./$outdir/rmlogger
metricfile=./$outdir/metricfile
schedulerfile=./$outdir/schedulerfile
jmapfile=./$outdir/jmapfile
jmxfile=./$outdir/jmxfile
applist=./$outdir/runningapps
jmapdump=./$outdir/jmapdump_RM.hprof

seconds=10				#Time interval to collect details


#getting Active RM URL 
rmurl=`maprcli urls -name resourcemanager | grep -v url`


#Function definitions goes here

#Header function which calls other functions to collect other metrics on RM

collectRM()
{
        rmpid=`ps -ef | grep resourcemanager | grep -v grep | awk '{print $2}'`
        echo "RM is running as Pid : $rmpid" >> $rmlogger
	
	echo "Collecting jmap for Resource manager: $rmpid for every $seconds seconds" >> $rmlogger
	
	collectJmap $rmpid

	#Going to infinite loop with sleep intervals to collect Jstack, application list, schduler metrics

	while(true)
	do
		
		collectJstack $rmpid
		collectRMrest
		collectApps
		echo "Sleeping for $seconds secs for next collect ..."
		sleep $seconds	
	done;

}


#Header function which calls other functions to collect other metrics on NM

collectNM()
{
	nmpid=`ps -ef | grep nodemanager | grep -v grep | awk '{print $2}'`
	echo "NM is running as Pid : $nmpid"
	while(true)
        do

                collectJstack $nmpid
                collectRMrest
                collectApps
                echo "Sleeping for $seconds secs for next collect ..."
                sleep $seconds
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
	echo "====Collecting Jmap for: $pid at $date  ====" >> $jmapfile
	jmap -histo:live $pid >> $jmapfile
	echo "Jmap collection done ..."
	echo "====Collecting Jmap dump for $pid at $date ==="
	jmap -dump:format=b,file=$jmapdump $pid
	echo "Jmap dump  collection done ..."
}

#Funciton collects RM metrics from REST API
#Note : This funtion collects single time, Please call this function multiple times to get in intervals
#Usage collctRMrest

collectRMrest()
{
	date=`date`

	echo "====Collecting RM metrics from curl at $date ====" >>$metricfile

	metricurl=`echo $rmurl/ws/v1/cluster/metrics | tr -d ' '`
	curl $metricurl >> $metricfile  2>/dev/null
	
	echo "====Collecting RM Scheduler metrics from curl at $date ====" >> $schedulerfile

	schedulerurl=`echo $rmurl/ws/v1/cluster/scheduler | tr -d ' '`

	curl $schedulerurl >> $schedulerfile 2>/dev/null

	echo "====Collecting JMX for RM at $date ====" >> $jmxfile

	jmxurl=`echo $rmurl/jmx | tr -d ' '` 
	
	curl $jmxurl >> $jmxfile 2>/dev/null

	echo "**End of collection at $date ***" >> $schedulerfile
	
	
}


#Funciton collects applications running at given point of time
#Note : This funtion collects single time, Please call this function multiple times to get in intervals
#Usage collectApps

collectApps()
{
	date=`date`
	echo "==== Collecting Yarn appls at $date =====" >> $applist
	yarn application -list >> $applist 2>/dev/null

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
	collectNM
fi


