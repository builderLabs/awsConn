### AWS Connection Manager Utility Script

I decided to put together a utility script to allow me to connect to my Amazon  
EC2 instance conveniently from the command line.  While this started out as a few  
lines at first (following the very helpful AWS manuals) I soon realized that I  
may want to incorporate several commands (such as start/stop/describe) as  
input options and then perform verification checks upon establishing a  
connection.  
&emsp;  
To do these 'correctly', more or less, would require a module to store all my  
AWS-relevant configuration settings.  This, coupled with use of my own  
environment's key system parameter-argument couplings and logging utility, gives  
the appearance that the code is somewhat more bloated than it really is, but  
it works, nevertheless.  
&emsp;  
```
**Note - Some Editing Required: I highlight optional/environment-specific  
components in the script descriptions below.  
```
&emsp;  
&emsp;  
1). awsConn.pl - main script for managing connections.  
&emsp;  
&emsp;&emsp;This script imports the standard Perl modules: POSIX, File, & Time  
&emsp;&emsp;and 3 modules relevant to my own environment: FsSysVars, FsLog, and  
&emsp;&emsp;CfgAws.  The first two are responsible for setting certain  
&emsp;&emsp;environment variables and logging tasks executed in a standardized  
&emsp;&emsp;way, respectively.  These maybe either replaced or ignored so long  
&emsp;&emsp;as their associated instantiation tasks within the code body are 
&emsp;&emsp;also edited to negate or modify their use.  
&emsp;  
&emsp;&emsp;The module CfgAws, however, is crucial to the operation of this  
&emsp;&emsp;script as it keeps a record of the details pertinent to EC2  
&emsp;&emsp;instances.  These include the instance id, for example, which  
&emsp;&emsp;is of course required when attempting to connect to an AWS server.  
&emsp;  
&emsp;&emsp;Sample usage is as follows:
```
awsConn.pl --argv cmd=start
awsConn.pl --argv cmd=connect
awsConn.pl --argv cmd=describe
awsConn.pl --argv cmd=stop

```
&emsp;  
2). CfgAws.pm - module which contains configuration settings for one or more  
&emsp;  
&emsp;&emsp;AWS instances (in my case, EC2 instances).  This module contains  
&emsp;&emsp;important information like the path and filename of key  
&emsp;&emsp;authentication and authorization files such as the AWS ssh key file  
&emsp;&emsp;name and location associated with a given instance as well a set of  
&emsp;&emsp;higher level variables such as AWS status codes and definitions  
&emsp;&emsp;(gleaned from AWS manuals) and account information and certain other  
&emsp;&emsp;operation-specific file settings.  
&emsp;  
&emsp;&emsp;Conveniently, this module is structured such that different  
&emsp;&emsp;instances can be given different names in the local context (e.g.  
&emsp;&emsp;'dev' versus 'prod') corresponding to different EC2 instances with   
&emsp;&emsp;their own relative configuration settings (instance id number, etc.).  
&emsp;  
&emsp;&emsp;Unlike the other two modules, this one is required.  Obviously, the  
&emsp;&emsp;path and/or name/structure maybe modified to match your environment  
&emsp;&emsp;so long as key machine instance identifiers are passed to the  
&emsp;&emsp; awsConn.pl script.  
&emsp;  
3). sshaws.bash - wrapper for awsConn.pl.  
&emsp;  
&emsp;&emsp;Simplifies calls to awsConn.pl by allowing the user to simply type:  
&emsp;&emsp;`sshaws <task>`&emsp;&emsp;&emsp;&emsp;&emsp;[task=start/connect/describe/stop]
&emsp;  
&emsp;&emsp;A key way to effectuate such a call would be to include a function  
&emsp;&emsp;in your .bashrc profile or one of your environment profile scripts  
&emsp;&emsp;and define a function sshaws which calls sshaws.bash (or just use  
&emsp;&emsp;'shaws.bash' if you don't mind typing that much).  
&emsp;  
Hope you find these useful!  
&emsp;  
