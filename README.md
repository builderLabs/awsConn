### AWS Connection Manager Utility Script

I decided to put together a utility script to allow me to connect to my Amazon  
EC2 instance conveniently from the command line.  While this started out as a few  
lines at first (following the very helpful AWS manuals) I soon realized that I  
may want to incorporate several commands (such as start/stop/describe) as  
input options and then perform verification checks upon establishing a  
connection.  
  
To do these 'correctly', more or less, would require a module to store all my  
AWS-relevant configuration settings.  This, coupled with use of my own  
environment's key system parameter-argument couplings and logging utility, gives  
the appearance that the code is somewhat more bloated than it really is, but  
it works, nevertheless.  
  
```
**Note - Some Editing Required: I highlight optional/environment-specific  
components in the script descriptions below.  
```
  
  
**1). awsConn.pl** - main script for managing connections.  
  
This script imports the standard Perl modules: POSIX, File, & Time  
and 3 modules relevant to my own environment: FsSysVars, FsLog, and  
CfgAws.  The first two are responsible for setting certain  
environment variables and logging tasks executed in a standardized  
way, respectively.  These maybe either replaced or ignored so long  
as their associated instantiation tasks within the code body are  
also edited to negate or modify their use.  
  
The module CfgAws, however, is crucial to the operation of this  
script as it keeps a record of the details pertinent to EC2  
instances.  These include the instance id, for example, which  
is of course required when attempting to connect to an AWS server.  
  
Sample usage is as follows:
```
awsConn.pl --argv cmd=start
awsConn.pl --argv cmd=connect
awsConn.pl --argv cmd=describe
awsConn.pl --argv cmd=stop

```
  
**2). CfgAws.pm** - module which contains configuration settings for one or more  
  
AWS instances (in my case, EC2 instances).  This module contains  
important information like the path and filename of key  
authentication and authorization files such as the AWS ssh key file  
name and location associated with a given instance as well a set of  
higher level variables such as AWS status codes and definitions  
(gleaned from AWS manuals) and account information and certain other  
operation-specific file settings.  
  
Conveniently, this module is structured such that different  
instances can be given different names in the local context (e.g.  
'dev' versus 'prod') corresponding to different EC2 instances with   
their own relative configuration settings (instance id number, etc.).  
  
Unlike the other two modules, this one is required.  Obviously, the  
path and/or name/structure maybe modified to match your environment  
so long as key machine instance identifiers are passed to the  
 awsConn.pl script.  
  
**3). sshaws.bash** - wrapper for awsConn.pl.  
  
Simplifies calls to awsConn.pl by allowing the user to simply type:  
```
sshaws -i <instanceName> -c <command>
```
where:  
**instanceName**:      an instance name parameter specified in the  
  configurations module with associated connection  and other descriptive  
  details.  
  **command**:             choose from start/stop/describe/connect  
  
A key way to effectuate such a call would be to include a function  
in your .bashrc profile or one of your environment profile scripts  
and define a function sshaws which calls sshaws.bash (or just use  
'shaws.bash' if you don't mind typing that much).  
  
Hope you find these useful!  
  
