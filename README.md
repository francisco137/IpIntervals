# IpIntervals

### Description

IpIntervals is a toy application which aim is perform simple Spark-Scala 
run in local `sbt` but with data exchanging with 2 containers run in turn
in Minikube.
 
The algorithm is as follows:

We have set od IP ranges (intervals) like *192.168.34.12 - 192.168.78.1*.
The algorithm cut off all sub-ranges which are common for at least 2 ranges.
The final is a set of sub-ranges which originally belonged to one range only.

The algorithm was coded as an Scala application using Spark technology.

Application runs in sbt environment locally.

Application works as follows - it:

1. generates random sequence of IP ranges,

2. save the ranges into csv files,

3. save the ranges into postgresql database,

4. search the final result three time, but takes the source ranges in three
ways: from memmory sequence, from file and from postgresql. All the result are
displayed on the screen so they can be compared.

5. The result from postgres is written into elasticsearch with timestamp as a part
of the index.

### Installation


This is Scala 11.12/Java 8 application running on Minikube and on the machine:
```
> uname -a
Linux francisco 4.19.0-14-amd64 #1 SMP Debian 4.19.171-2 (2021-01-30) x86_64 GNU/Linux
```

and full system declaration:

```
PRETTY_NAME="Debian GNU/Linux 10 (buster)"
NAME="Debian GNU/Linux"
VERSION_ID="10"
VERSION="10 (buster)"
VERSION_CODENAME=buster
ID=debian
HOME_URL="https://www.debian.org/"
SUPPORT_URL="https://www.debian.org/support"
BUG_REPORT_URL="https://bugs.debian.org/"
```

The following software have to be installed prior running the application.

```
Scala code runner version 2.11.12 -- Copyright 2002-2016, LAMP/EPFL
```

```
java version "1.8.0_91"
Java(TM) SE Runtime Environment (build 1.8.0_91-b14)
Java HotSpot(TM) 64-Bit Server VM (build 25.91-b14, mixed mode)
```

```
minikube version: v1.17.1
commit: 043bdca07e54ab6e4fc0457e3064048f34133d7e
```  
## WARNING - Minikube driver possible problems!

Please pay attention on minikube driver. The driver means type of virtualization
which is used to run minikube.

We tested only default one: the "docker"

### Running the application:

the main script to run the application is:

```
./ip_intervals.sh
```

which can be run with some options; please run it as it's written: without any option to
see help:
```
===================================================================================
 This is ip_intervals ver.0.1 (C) Waldemar C. Biernacki, 2021, All rights reserved
-----------------------------------------------------------------------------------

 Usage: ./ip_intervals.sh [options]
 ----------------------------------------------------------------------------------
 options:

 -a|--app       apply or delete specific pod, option has the form: [POD.ACTION]
 -b|--build     to pull/build docker images [elasticsearch|postgresql]
 -c|--cisza     don't ask to confirm
 -d|--dashboard to start minikube dashboard in the default browser
 -h|--help      this screen
 -l|--logs      to display minikube pod log file for one of the applications
 -m|--minikube  to start minikube (first time could be long)
 -q|--quit      to quit minikube
 -r|--remove    to remove all from minikube (pods, services, etc)
 -s|--start     to start all deployment on minikube (pods, services, etc)
 -v|--driver    to add minikube driver when minikube starts (default 'docker')
 -x|--execute   execute SCALA application for defined environment
===================================================================================
```

The process of downloading and building postgresql and elasticsearch docker images,
then load them properly into minikube and run the application is quite complex,
so although we tried our best to make it easy it could be quite possible
to overlooked something. 

However it is quite possible, that all the stuff you can run with one command:

```
./run_all.sh
```
this script is aimed to:
 
- download necessary docker images,
- build proper images,
- open minikube
- upload the images into minikube vm
- start the images as minikube containers,
- open minikube dashboard in your default browser
- run the application,
- remove the deployment from minikube
- close minikube

