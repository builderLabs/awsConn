#====================================================================
#
#  Filename:        awsConn.pl
#  Author:          Ozan Akcin
#  Created:         20161202
#  Purpose:         manages AWS server connections
#  Last Modified:
#
#====================================================================
#!/usr/bin/perl


use strict;
use warnings;

use POSIX;
use File::Path;
use File::Basename;
use Time::Local;
use FsData::FsSysVars;  #---env-specific key-value pairings (replace/ignore)
use FsData::FsLog;      #---env-specific logging utility (replace/ignore)
use Util::CfgAws;


my ( $fsVars, $fsLog, $svcTag, $appName );

my ( $defInst, $defCmd, $defUser, $startSleep, $stopSleep, @chkParam );

#---general settings-------------------------------------------------

#---job definition:
$svcTag  = 'AWS';
$appName = 'AWS_CONNECTION_MANAGER';

#---task-specific:
$defInst = 'dev';
$defCmd  = 'connect';
$defUser = $ENV{USER};
$startSleep = 20;
$stopSleep  = 60;

@chkParam = ( 
                 'OwnerId'
               , 'PublicIpAddress'
               , 'VpcId'
               , 'ImageId'
               , 'KeyName'
               , 'GroupId'
               , 'InstanceType'
            );


#--------------------------------------------------------------------


#==============================================================================       
sub setTaskDef
{

   my ( $program, $ymd, $HHMMSS, $dtStampLocal );
   my ($logRoot, $logFile, $taskArgs, $fsTaskDef );

   $dtStampLocal   =  strftime("%Y%m%d %H%M%S", localtime);
   $program      =  basename($0);
   $program      =~ s/\.\w*//;
   $ymd          =  substr($dtStampLocal,0,8);
   $HHMMSS       =  substr($dtStampLocal,-6);
   $logRoot      = "$program.".$HHMMSS;

   $taskArgs    =   {
                         appName        =>   $appName
                       , processName    =>   $appName
                       , logRoot        =>   $logRoot
                    };

   $fsTaskDef    =  {
                         SERVICE_TAG    => "${svcTag}"
                    };

   $fsVars  = new FsData::FsSysVars($taskArgs, $fsTaskDef);

   $logFile = defined($fsVars->getArgv('logFile'))
            ? $fsVars->getArgv('logFile')
            : $fsVars->getFsVar('FSDATA_LOG_DIR')
            . '/' . $ymd
            . '/' . $fsVars->getFsVar('SERVICE_TAG')
            . '/' . $fsVars->getArgv('logRoot')
   ;

   $fsLog   = new FsData::FsLog( $fsVars->getFsVars, $logFile );

   $fsVars->setArgv('YYYYMMDD',$ymd);
   $fsVars->setArgv('HHMMSS',$HHMMSS);

   #---print invocation to logFile:
   $fsLog->print("***START***");
   $fsLog->print(`ps -o args -C perl | grep $0 | tr -d '\n'`)

}
#==============================================================================  


#==============================================================================
sub initArgs
{

   #---future instances need to be coded for here, including if not 'current'

   my ( $fsLog, $fsVars ) = @_;

   $fsLog->print("Initializing arguments...");

   my ( $workDir, $inst, $cmd, $user, $awsCfg );

   $workDir = defined($fsVars->getArgv('workDir'))
            ? $fsVars->getArgv('workDir')
            : $fsVars->getFsVar('FSDATA_OUTPUT_DIR')
            . '/' . $svcTag
            . '/' . 'tmp_' . $$
   ;

   $inst = defined($fsVars->getArgv('inst'))
         ? $fsVars->getArgv('inst')
         : $defInst
   ;

   $cmd = defined($fsVars->getArgv('cmd'))
           ? $fsVars->getArgv('cmd')
           : $defCmd
   ;

   $user = defined($fsVars->getArgv('user'))
         ? $fsVars->getArgv('user')
         : $defUser
   ;
   $user = 'oakcin' if ( $user eq 'akcinoz' );

   $awsCfg = new FsData::CfgAws;

   mkpath($workDir) if ( ! -d $workDir && $cmd eq 'start' );

   $fsVars->setArgv('workDir',$workDir);
   $fsVars->setArgv('inst',$inst);
   $fsVars->setArgv('cmd',$cmd);
   $fsVars->setArgv('user',$user);
   $fsVars->setArgv('awsCfg', $awsCfg);
}
#==============================================================================


#==============================================================================
sub awsConnect
{
   my ( $fsLog, $fsVars ) = @_;

   my ( %awsCfg, $user, $inst, $instanceId, $keyPairFile, $ipFile, $invFile, $awsIp, $cmdString );

   $fsLog->print("Reading configurations for connection to AWS server...");

   $user   = $fsVars->getArgv('user');
   $inst   = $fsVars->getArgv('inst');
   %awsCfg = %{$fsVars->getArgv('awsCfg')};
   %awsCfg = %{$awsCfg{awsCfgVars}};
  
   $ipFile  = $awsCfg{awsGlobalVars}->{ipFile};
   $ipFile  =~ s/INSTANCE/$inst/g;   
   ($invFile = $ipFile) =~ s/pubDNS/invalid/g;

   $fsLog->die("ERROR: invalid IP/log-on control file: $invFile detected...") if ( -f $invFile );
   $fsLog->die("ERROR: no IP file detected - try starting remote AWS server for: $inst first.") if ( ! -f $ipFile );

   $keyPairFile  = $awsCfg{instances}->{$inst}->{keyPairFile};
   $instanceId   = $awsCfg{instances}->{$inst}->{instanceId};

   open ( my $fh, $ipFile ) or $fsLog->die("Cannot open: $ipFile");
   { $awsIp = <$fh>; }
   close($fh);
   chomp $awsIp;

   $cmdString  = "ssh -q -oUserKnownHostsFile=/dev/null -oStrictHostKeyChecking=no ";
   $cmdString .= "-i KEYPAIRFILE USER\@AWSIP";

   $cmdString =~ s/KEYPAIRFILE/$keyPairFile/g;
   $cmdString =~ s/USER/$user/g;
   $cmdString =~ s/AWSIP/$awsIp/g;

   $fsLog->print("Connecting to AWS instance id: $instanceId...bye!");
   $fsLog->print("$cmdString");

   exec ("$cmdString");

   #---> check existence of valid file in ~/.aws/ first, raiseerror if not there.

}
#==============================================================================


#==============================================================================
sub getLocParam
{
   my ( $fsLog, $fsVars ) = @_;

   my ( $inst, %awsCfg, %locParam );

   $inst = $fsVars->getArgv('inst');

   %awsCfg = %{$fsVars->getArgv('awsCfg')};
   %awsCfg = %{$awsCfg{awsCfgVars}};

   $fsLog->print("Collating local connection parameters for server: $inst...");

   $locParam{'InstanceType'} = $awsCfg{instances}->{$inst}->{instanceType};
   $locParam{'VpcId'}        = $awsCfg{instances}->{$inst}->{vpcId};
   $locParam{'OwnerId'}      = $awsCfg{awsGlobalVars}->{accountNum};
   $locParam{'KeyName'}      = $awsCfg{instances}->{$inst}->{keyPairName};
   $locParam{'ImageId'}      = $awsCfg{instances}->{$inst}->{ami};
   $locParam{'GroupId'}      = $awsCfg{instances}->{$inst}->{secGroupId};
   
   $fsVars->setArgv('locParam',\%locParam);

}
#==============================================================================


#==============================================================================
sub awsAuthenticate
{
   my ( $fsLog, $fsVars ) = @_;

   getRemParam($fsLog, $fsVars);
   getLocParam($fsLog, $fsVars);

   my ( %awsCfg, %locParam, %remParam, $valid, $inst, $instanceId, $ipFile, $invFile );

   %awsCfg  = %{$fsVars->getArgv('awsCfg')};
   %awsCfg  = %{$awsCfg{awsCfgVars}};
   $ipFile  = $awsCfg{awsGlobalVars}->{ipFile};
   $inst    = $fsVars->getArgv('inst');
   $instanceId = $awsCfg{instances}->{$inst}->{instanceId};
   $ipFile  =~ s/INSTANCE/$inst/g;
   ($invFile = $ipFile) =~ s/pubDNS/invalid/g;
   $valid   = 0;

   $fsLog->print("Comparing remote and local AWS parameter settings...");

   %locParam = %{$fsVars->getArgv('locParam')};
   %remParam = %{$fsVars->getArgv('remParam')};

   #---compare parameters and log differences
   foreach my $skey ( keys %remParam ) {
      next if ( $skey eq 'PublicIpAddress' );
      if ( $locParam{$skey} ne $remParam{$skey} ) {
         $fsLog->print("Parameter mismatch - $skey: $locParam{$skey} (loc) v. $remParam{$skey} (rem)");      
         $valid++;
      } else {
         $fsLog->print("Validated $skey: $locParam{$skey} (loc) and $remParam{$skey} (rem)");
      }  
   }

   if ( $valid > 0 ) {
       $fsLog->print("Generating invalid ip-logon file...");
       $fsLog->print("System(bash -c \"touch $invFile\")");
       my $sysMsg = `bash -c \"touch $invFile\"`; 
       $fsLog->die($sysMsg) if ($sysMsg);
       $fsLog->die("ERROR: One or more settings do not match..see $fsLog->{_logFile} for details...");
   }

   $fsLog->print("Expected remote and local settings verified - updating ip file for inst: $inst...");
   unlink $ipFile if ( -f $ipFile );

   open my $out, '>', $ipFile;
   print $out $remParam{PublicIpAddress};
   close($out);

}
#==============================================================================


#==============================================================================
sub awsDescribe
{
   my ( $fsLog, $fsVars ) = @_;
 
   my ( %awsCfg, $inst, $instanceId );
   my ( $cmdStringRoot, $cmdStringCode, $cmdStringState, $cmdStringIP, $remState, $remCode, $awsIp);

   $inst = $fsVars->getArgv('inst');

   %awsCfg = %{$fsVars->getArgv('awsCfg')};
   %awsCfg = %{$awsCfg{awsCfgVars}};
 
   $instanceId = $awsCfg{instances}->{$inst}->{instanceId};

   $cmdStringRoot = "aws ec2 describe-instances --instance-ids $instanceId";
   $cmdStringCode = $cmdStringRoot." --query 'Reservations[0].Instances[0].State.Code'"; 
   $cmdStringState = $cmdStringRoot." --query 'Reservations[0].Instances[0].State.Name'";

   $fsLog->print("Checking AWS status code...");
   $fsLog->print("System('$cmdStringCode')");
   $remCode = `bash -c \"$cmdStringCode\"`;

   $fsLog->print("Checking AWS status name...");
   $fsLog->print("System('$cmdStringState')");
   $remState = `bash -c \"$cmdStringState\"`;

   chomp $remCode;
   chomp $remState;
   $remState =~ s/\"//g;
   $remState =~ s/\'//g; 

   if ( ! defined($remCode) || ! defined($remState) ){
      $fsLog->die("Error in ascertaining one or more state descriptive variables: 'Code', 'Name'");
   } 

   if ( ! defined($awsCfg{awsReturnValues}->{$remCode}) ) {
      $fsLog->print("Unable to verify returned status code: $remCode");
      $fsLog->die("No such code recorded in module/library.");
   }

   if ( $awsCfg{awsReturnValues}->{$remCode} ne $remState ) {
      $fsLog->print("Unable to verify returned status: $remState for code: $remCode.");
      $fsLog->die("Regsitered status for code: $remCode is: ".$awsCfg{awsReturnValues}->{$remCode});
   }

   my $status = "Verified AWS server instance: $inst ($instanceId) "
                ." returned status: $remState ($remCode) ";

   if ( $remCode == 16 ) {
       $cmdStringIP = $cmdStringRoot." --query 'Reservations[0].Instances[0].PublicIpAddress'";
       $fsLog->print("Checking AWS IP address...");
       $fsLog->print("System('$cmdStringIP')");
       $awsIp = `bash -c \"$cmdStringIP\"`;
       $status .= "on ip address: $awsIp";
   }

   $fsLog->print($status);
   print $status."\n";

}
#==============================================================================


#==============================================================================
sub getRemParam
{
   my ( $fsLog, $fsVars ) = @_;
 
   my ( $workDir, $outFile, %awsCfg, $inst, $instanceId, $cmdString, $response );
   my ( %remParam, $remState, $remCode, $awsIp );

   $workDir = $fsVars->getArgv('workDir');
   $inst = $fsVars->getArgv('inst');
   $outFile = $workDir.'/aws_response';

   %awsCfg = %{$fsVars->getArgv('awsCfg')};
   %awsCfg = %{$awsCfg{awsCfgVars}};
 
   $instanceId = $awsCfg{instances}->{$inst}->{instanceId};

   $fsLog->print("Checking AWS server response...");

   $cmdString  = "aws ec2 describe-instances --instance-ids $instanceId ";
   $response = `bash -c \"$cmdString\"`; 

   $fsLog->print("$response");
   $response =~ s/\,/\n/g;
   $response =~ s/\"//g;

   open my $out, '>', $outFile;
   print $out $response;
   close($out);

   open (my $fh, $outFile);
   while(<$fh>){
      chomp;
      $_ =~ s/\s//g;
      my ( $param, $arg ) = split /\:/, $_;
      next if ( ! defined($param) );
      if ( $param eq 'PublicIpAddress' ) {
         $awsIp = $arg;
         $fsVars->setArgv('awsIp',$awsIp);
      }
      if ( grep { $chkParam[$_] eq $param } 0 ..$#chkParam ) {
         $remParam{$param} = $arg;
      }
   } 

   $fsVars->setArgv('remParam',\%remParam);

}
#==============================================================================


#==============================================================================
sub awsStart
{
   my ( $fsLog, $fsVars ) = @_;
   
   my ( %awsCfg, $inst, $instance, $instanceId, $cmdString, $response );

   $inst = $fsVars->getArgv('inst');

   $fsLog->print("Reading configurations to start AWS server...");

   %awsCfg = %{$fsVars->getArgv('awsCfg')};
   %awsCfg = %{$awsCfg{awsCfgVars}};
  
   $instanceId = $awsCfg{instances}->{$inst}->{instanceId};

   $cmdString = "aws ec2 start-instances --instance-ids $instanceId";

   $fsLog->print("Sending start command to remote AWS server instance: $instanceId...");
   $fsLog->print("$cmdString");

   $response = `bash -c \"$cmdString\"`;

   $fsLog->print("AWS Response: $response...");

   sleep($startSleep);
   awsDescribe( $fsLog, $fsVars );
   awsAuthenticate( $fsLog, $fsVars ); 

}
#==============================================================================


#==============================================================================
sub awsStop
{
   my ( $fsLog, $fsVars ) = @_;
   
   my ( %awsCfg, $inst, $instanceId, $cmdString, $response, $ipFile );

   $inst = $fsVars->getArgv('inst');

   $fsLog->print("Reading configurations to stop AWS server...");

   %awsCfg = %{$fsVars->getArgv('awsCfg')};
   %awsCfg = %{$awsCfg{awsCfgVars}};

   $ipFile  = $awsCfg{awsGlobalVars}->{ipFile};
   $inst    = $fsVars->getArgv('inst');
   $instanceId = $awsCfg{instances}->{$inst}->{instanceId};
   $ipFile  =~ s/INSTANCE/$inst/g;

   $cmdString = "aws ec2 stop-instances --instance-ids $instanceId";

   $fsLog->print("Sending stop command to remote AWS server instance: $instanceId...");
   $fsLog->print("$cmdString");

   $response = `bash -c \"$cmdString\"`;

   $fsLog->print("AWS Response: $response...");

   sleep($stopSleep);
   awsDescribe( $fsLog, $fsVars );

   $fsLog->print("Removing ip file: $ipFile...");
   unlink $ipFile if ( -f $ipFile );

}
#==============================================================================


#==============================================================================
sub awsConnManager
{
   my ( $fsLog, $fsVars) = @_;

   my $cmd = $fsVars->getArgv('cmd');

   if ( $cmd eq 'connect' ) {

      awsConnect($fsLog, $fsVars);

   } elsif ( $cmd eq 'start' ) {

      awsStart($fsLog, $fsVars);

   } elsif ( $cmd eq 'describe' ) {
     
      awsDescribe( $fsLog , $fsVars);

   } elsif ( $cmd eq 'stop' ) {

      awsStop($fsLog, $fsVars);  

   } else {

      $fsLog->die("Unrecognized command: $cmd...");

   }

}
#==============================================================================


#==============================================================================
sub cleanWork
{
   my ($fsLog, $fsVars) = @_;

   $fsLog->print("Cleaning up...");

   my $workDir = $fsVars->getArgv('workDir');
   if ( -d $workDir ) {
      $fsLog->print("Removing work directory: $workDir");
      $fsLog->print("System('rm -r $workDir')");
      my $sysMsg = `bash -c \"rm -r $workDir\"`;
      if ( $sysMsg ) {
         $fsLog->print("Unexpected return encountered trying to remove: $workDir...");
         $fsLog->die("SYSMSG: $sysMsg");
      }
   }

1;
}
#==============================================================================


exit(main());


#==============================================================================
sub main
{

setTaskDef;
initArgs($fsLog, $fsVars);
awsConnManager($fsLog,$fsVars);
cleanWork($fsLog, $fsVars);
$fsLog->print("***DONE***");

}
#==============================================================================
