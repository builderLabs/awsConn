#====================================================================
#
#  Filename:        sshaws.bash
#  Author:          Ozan Akcin
#  Created:         20161202
#  Purpose:
#  Notes:
#
#====================================================================

#!/bin/bash


awsConnMgr=${HOME}/fsbase/releases/fsprod/src/util/awsconn/awsConn.pl

task=connect
if [[ $# > 0 ]]; then
   task=$1
fi

`perl -w $awsConnMgr --argv \cmd=$task`
