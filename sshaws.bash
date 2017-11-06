#====================================================================
function sshawsUsage() {
    echo
    echo "     $0 -c <cmd> [ OPTIONAL: -i <inst> ]"
    echo "         cmd:      command [ <start|stop|connect|describe|status> | DEFAULT: connect ]"
    echo "         inst:     instance [ <dev|prod> | DEFAULT: dev ]"
    echo
    return
}
#====================================================================


#====================================================================
function sshaws() {

# empty input options array to purge stale args from prev sessions
OPTIND=""

inst=""
cmd=""
av_inst=""
av_cmd=""

pv_inst="dev"
pv_cmd="connect"

while getopts "i:c:h" opt
do
   case $opt in
        i )  av_inst=$OPTARG;;
        c )  av_cmd=$OPTARG;
             if [[ $av_cmd == "stat" || $av_cmd == "status" ]]; then
                av_cmd="describe"
             elif [[ $av_cmd == "conn" ]]; then
                av_cmd="connect"
             fi;;
        h)  sshawsUsage;
            return;;
        * ) sshawsUsage;
            return;;
   esac
done

inst=${av_inst:-$pv_inst}
cmd=${av_cmd:-$pv_cmd}

# confirm if instance stoppage
if [ $cmd == "stop" ]; then
   read -p "Are you sure? Confirm $cmd for $inst instance (Y/y): " -n 1 -r
   echo
   if [[ ! $REPLY =~ ^[Yy]$ ]]; then
      echo "Aborting..."
      return
   fi
fi

case $cmd in
   "connect" ) pv_cmd_v="Connecting to ";;
   "start"   ) pv_cmd_v="Starting ";;
   "stop"    ) pv_cmd_v="Stopping ";;
   * )         pv_cmd_v="Checking status for ";;
esac


echo $pv_cmd_v instance: $inst ...
perl -w ${HOME}/fsbase/releases/fsprod/src/util/awsConn.pl --argv inst=$inst --argv cmd=$cmd

}
#====================================================================

