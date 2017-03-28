#====================================================================
#
#  Filename:        CfgAws.pm
#  Author:          Ozan Akcin
#  Created:         02-12-2016
#  Purpose:         key parameter-argument couplings for AWS servers connectivity
#  References:      http://docs.aws.amazon.com/cli/latest/reference/ec2/start-instances.html
#                   http://docs.aws.amazon.com/cli/latest/reference/ec2/describe-instances.html
#                   http://docs.aws.amazon.com/cli/latest/reference/ec2/stop-instances.html 
#====================================================================


package FsData::CfgAws;    #---modify to match target lib path in your env

use strict;
use warnings;
use Carp;


my %awsCfg = 
(

   'awsGlobalVars'   =>      {
                                  accountNum         =>    ""
                                , configFile         =>    "$ENV{HOME}/.aws/config"
                                , credFile           =>    "$ENV{HOME}/.aws/credentials"
                                , ipFile             =>    "$ENV{HOME}/.aws/pubDNS_INSTANCE"
                               
                             },


   'awsReturnValues' =>      {
                                  0   =>   "pending"
                                , 16  =>   "running"
                                , 32  =>   "shutting-down"
                                , 48  =>   "terminated"
                                , 64  =>   "stopping"
                                , 80  =>   "stopped"
                             },

   'instances'       =>     {


           'dev'    =>      {     
                                  ami           =>  ""    #---amazon machine image
                                , description   =>  ""    
                                , instanceId    =>  ""            
                                , instanceType  =>  ""    #---e.g. 't2.micro', etc.    
                                , keyPairFile   =>  ""    #---path to AWS *.pem file (generally under ~/.ssh)
                                , keyPairName   =>  ""    #---file name of key pair given during ssh-keygen process
                                , secGroupId    =>  ""    #---security group id (from AWS instance description)
                                , vpcId         =>  ""    #---virtual private cloud 
                             },

          'prod'    =>      {

          },

   }

);


#===============================================================================
sub new
{
   my( $class )=@_;
   my $self = {};
   bless $self, $class;

   $self->_init;

   return $self;
}
#===============================================================================


#===============================================================================
sub _init
{
   my ( $self ) = @_;

   $self->{awsCfgVars} = \%awsCfg;

}
#===============================================================================
