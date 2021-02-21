#!/bin/bash
################################################################################
# This is ip_intervals.sh, (c) Waldemar C. Biernacki, 2021
# Author: waldemar.c.biernacki@gmail.com
# License: bsd
################################################################################
APP_NAME="ip_intervals"
APP_VERS="0.1"
APP_OWNER="Waldemar C. Biernacki"
APP_RIGHTS="All rights reserved"

ROOT_DIR=$(cd "$(dirname "$0")" ; pwd -P)
cd $ROOT_DIR

APPS=(postgresql elasticsearch)

export image_elasticsearch="docker.elastic.co/elasticsearch/elasticsearch:7.11.0"
export image_postgresql="francisco_ipintervals:1.0"
export version_postgresql="11"

export PG_VERSION=11
export PG_BASE="francisco"
export PG_USER="francisco"
export PG_PASS="nieznanehaslo"

DRIVER="docker"

################################################################################
#  S C R I P T   F U N C T I O N S
#-------------------------------------------------------------------------------
# In the script the ANSI colors are used: https://en.wikipedia.org/wiki/ANSI_escape_code#3-bit_and_4-bit
# There are 8 colors from 30 to 37 in 2 forms: normal and bold.
# Function show_info uses only foreground colors, technically they are written using escaping.
show_info()
{
  if [ $2 -lt 0 ] ; then
    printf "\033[$3m$1\033[0m"
  else
    printf "\033[$3m$1\033[0m"
    exit $2
  fi
}

confirm_or_quit()
{
  if [ "$CISZA" != "yes" ] ; then
    show_info "$1 by writing " -1 "37;0"
    show_info "yes " -1 "33;1"
    show_info "and pressing Enter: " -1 "37;0" ; read OK ; printf "\n"
    if [ "$OK" != "yes" ] ; then
      show_info "user resigned, quitting\n\n" 1 "31;1"
    fi
  fi
}

show_header()
{
  show_info "===================================================================================\n" -1 "37;1"
  show_info " This is $APP_NAME ver.$APP_VERS (C) $APP_OWNER, 2021, $APP_RIGHTS\n"                  -1 "37;1"
  show_info "-----------------------------------------------------------------------------------\n" -1 "37;1"
  echo ""
}

show_help()
{
  printf " Usage: $0 [options]\n"
  printf " ----------------------------------------------------------------------------------\n"
  printf " options:\n"
  printf "\n"
  printf " -a|--app       apply or delete specific pod, option has the form: [POD.ACTION]\n"
  printf " -b|--build     to pull/build docker images [elasticsearch|postgresql]\n"
  printf " -c|--cisza     don't ask to confirm\n"
  printf " -d|--dashboard to start minikube dashboard in the default browser\n"
  printf " -h|--help      this screen\n"
  printf " -l|--logs      to display minikube pod log file for one of the applications\n"
  printf " -m|--minikube  to start minikube (first time could be long)\n"
  printf " -q|--quit      to quit minikube\n"
  printf " -r|--remove    to remove all from minikube (pods, services, etc)\n"
  printf " -s|--start     to start all deployment on minikube (pods, services, etc)\n"
  printf " -v|--driver    to add minikube driver when minikube starts (default '%s')\n" "$DRIVER"
  printf " -x|--execute   execute SCALA application for defined environment\n"
  printf "===================================================================================\n"
  printf "\n"
}

is_minikube_running()
{
  status=`minikube status | grep host: | awk '{print $2}'`
  if [ "$status" = "Running" ] && [ "$1" != "yes" ] ; then
    show_info "Minikube appears running! Quitting.\n\n" 1 "31;1"
  fi

  if [ "$status" != "Running" ] && [ "$1" = "yes" ] ; then
    show_info "Minikube appears not running! Quitting.\n\n" 1 "31;1"
  fi
}

wait_for_minikube()
{
  RUNNING=0
  while [ "$RUNNING" != "1" ]
  do
    if [ "`minikube status | grep host: | awk '{print $2}'`" = "Running" ]; then
      RUNNING=1
    fi
    sleep 1
  done
}

check_if_docker_images_are_created()
{
  absent_images=""
  for APP in ${APPS[*]}
  do
    image="image_${APP}"
    res=`docker image ls "${!image}" -aq`
    if [ "$res" == "" ] ; then absent_images="$absent_images;${!image}" ; fi
  done

  if [ "$absent_images" != "" ] ; then
    final_info=`echo "$absent_images" | sed 's/;/\n   /g'`
    show_info "\nNot found the following docker images:   $final_info\n" -1 "31;1"
    show_info "\nUse option -b for creating\n\n"                          1 "30;0"
  fi
}

upload_image()
{
  app="$1"
  image="image_${app}"
  docker save --output $ROOT_DIR/tar/$app.tar "${!image}"
  minikube ssh "docker load --input $ROOT_DIR/tar/$app.tar"
  if [ "$?" != "0" ] ; then
#    unlink $ROOT_DIR/tar/$app.tar
    show_info "error during uploading images to minikube, quitting\n\n" $? "31;1"
  fi
#  unlink $ROOT_DIR/tar/$app.tar
}

create_basic_folders()
{
  for dir in \
    "data"
  do
    minikube ssh "sudo mkdir -p $dir"
  done

  # *** WARNING ***
  # It could be necessary to give more permissions (777) to some directories:
  for dir in \
    "data"
  do
    minikube ssh "sudo chmod -R 777 $dir"
  done

}

################################################################################

show_header

if [ "$1" = "" ] ; then HELP="yes" ; fi

################################################################################
#  C O M M A N D L I N E   A R G U M E N T S
#-------------------------------------------------------------------------------

TMP_FILE="/tmp/_${USER}_error"
options=`getopt -o a:b:cdhl:mqrsv:x --long app:,build:,cisza,dashboard,help,logs:,minikube,quit,remove,start,driver:,execute -n "$0" -- "$@" 2>$TMP_FILE`
if [ $? -ne 0 ]; then
  error=`cat $TMP_FILE`
  show_header
  show_info "Argument parsing problem: " -1 "31"
  show_info "$error\n\n" 1 "1;31"
fi

eval set -- $options
while true ; do
    case "$1" in
        -a|--app)       APP_NAMEDIR="$2"     ; shift 2 ;;
        -b|--build)     IMAGE="$2"           ; shift 2 ;;
        -c|--cisza)     CISZA="yes"          ; shift 1 ;;
        -d|--dashboard) DASHBOARD="yes"      ; shift 1 ;;
        -h|--help)      HELP="yes"           ; shift 1 ;;
        -l|--logs)      LOGS="$2"            ; shift 2 ;;
        -m|--minikube)  MINIKUBE="begin"     ; shift 1 ;;
        -q|--quit)      MINIKUBE="end"       ; shift 1 ;;
        -r|--remove)    DEPLOYMENT="end"     ; shift 1 ;;
        -s|--start)     DEPLOYMENT="begin"   ; shift 1 ;;
        -v|--driver)    DRIVER="$2"          ; shift 2 ;;
        -x|--execute)   SCALA="yes"          ; shift 1 ;;
        --) shift ; break ;;
        *)
        show_info "Argument parsing error: " -1   "31"
        show_info "$1\n\n"                    1 "1;31"
    esac
done

################################################################################
#  H E L P
#-------------------------------------------------------------------------------

if [ "$HELP" = "yes" ] ; then
  show_help
fi

################################################################################

if [ "$IMAGE" != "" ] ; then
  show_info "B U I L D I N G   D O C K E R   I M A G E S\n\n" -1 "37;1"

  apps=""
  if [ "$IMAGE" = "elasticsearch" ] || [ "$IMAGE" = "e" ] ; then apps=("elasticsearch") ; fi
  if [ "$IMAGE" = "postgresql"    ] || [ "$IMAGE" = "p" ] ; then apps=("postgresql")    ; fi
  if [ "$IMAGE" = "all"           ] || [ "$IMAGE" = "a" ] ; then apps=$APPS             ; fi

  for app in ${apps[*]}
  do
    show_info "-----------------------------------------------------------------------\n" -1 "31;0"
    show_info "building image for $app:\n" -1 "32;1"
    cd ./services/$app || exit 1
    ./docker_build.sh
    echo ""
  done

  if [ "$apps" = "" ] ; then
    show_info "Wrong arguments for building docker image ($IMAGE)!\n"        -1 "31;1"
    show_info "    Accepted one of: [elasticsearch|postgresql] or [e|p]\n\n"  1 "30;0"
  fi

  exit 0
fi

################################################################################

check_if_docker_images_are_created

################################################################################

if [ "$MINIKUBE" = "begin" ] ; then
  show_info " S T A R T I N G   M I N I K U B E\n\n" -1 "37;1"
  is_minikube_running no

  port_ranges="1-65535"
  show_info "minikube ports ranges to open: $port_ranges\n" -1 "37;0"

  echo " ROOT_DIR = ${ROOT_DIR}"
  echo " DRIVER   = ${DRIVER}"
  echo ""
  confirm_or_quit "Confirm starting minikube"

  minikube config set memory 8192
  minikube config set cpus 2

  # starting minikube
  minikube start \
    --driver="$DRIVER" \
    --extra-config="apiserver.service-node-port-range=$port_ranges" \
    --docker-opt="default-ulimit=memlock=-1:-1" \
    --docker-opt="default-ulimit=nofile=65536:65536"

  wait_for_minikube

  minikube ssh 'sudo -s sysctl -w vm.max_map_count=262144'
fi

################################################################################

if [ "$MINIKUBE" = "end" ] ; then
  show_info " S T O P P I N G   M I N I K U B E\n\n" -1 "37;1"
  is_minikube_running yes

  confirm_or_quit "Confirm stopping minikube"
  minikube stop
  exit 0
fi

################################################################################

if [ "$DEPLOYMENT" = "begin" ] ; then
  show_info " S T A R T I N G   D E P L O Y M E N T\n\n" -1 "37;1"
  is_minikube_running yes

  confirm_or_quit "Confirm running all deployment"
  minikube mount "${ROOT_DIR}/tar:${ROOT_DIR}/tar" &
  create_basic_folders
  for APP in ${APPS[*]}
  do
    show_info "-----------------------------------------------------------------------\n" -1 "31;0"
    show_info "starting $APP:\n" -1 "32;1"
    upload_image $APP
    envsubst < "services/$APP/$APP.yaml" | kubectl apply -f -
    echo ""
  done
fi

################################################################################

if [ "$APP_NAMEDIR" != "" ] ; then
  show_info "P E R F O R M I N G   D E P L O Y M E N T   O P E R A T I O N\n\n" -1 "37;1"
  is_minikube_running yes

  create_basic_folders

  APP_NAME=${APP_NAMEDIR%.*}
  APP_OPER=${APP_NAMEDIR#*.}

  app=""
  if [ "$APP_NAME" = "elasticsearch" ] || [ "$APP_NAME" = "e" ] ; then app="elasticsearch" ; fi
  if [ "$APP_NAME" = "postgresql"    ] || [ "$APP_NAME" = "p" ] ; then app="postgresql"    ; fi
  ope=""
  if [ "$APP_OPER" = "apply"         ] || [ "$APP_OPER" = "a" ] ; then ope="apply"         ; fi
  if [ "$APP_OPER" = "delete"        ] || [ "$APP_OPER" = "d" ] ; then ope="delete"        ; fi

  if [ "$app" != "" ] && [ "$ope" != "" ] ; then
    create_basic_folders
    if [ "$ope" = "apply" ] ; then
      show_info "applying $app to minikube, please wait...\n" -1 "32;1"
      upload_image $app
      envsubst < "services/$app/$app.yaml" | kubectl $ope -f -
    else
      show_info "deleting $app from minikube, please wait...\n" -1 "31;1"
      envsubst < "services/$app/$app.yaml" | kubectl $ope -f -
    fi
  else
    show_info "Wrong arguments for application operation ($APP_NAME-$APP_DIR)!\n\n"         -1 "31;1"
    show_info "Accepted form:\n"                                                            -1 "37;0"
    show_info "    -a application.operation\n"                                              -1 "33;1"
    show_info "where:\n"                                                                    -1 "37;0"
    show_info "    application - one of [elasticsearch|postgresql] or [e|p]\n"              -1 "37;0"
    show_info "    operation   - one of [apply|delete]             or [a|d]\n\n"             1 "37;0"
  fi

fi

################################################################################

if [ "$DEPLOYMENT" = "end" ] ; then
  show_info " R E M O V I N G   D E P L O Y M E N T\n\n" -1 "37;1"
  is_minikube_running yes

  confirm_or_quit "Confirm removing all deployments from minikube"
  for APP in ${APPS[*]}
  do
    show_info "-----------------------------------------------------------------------\n" -1 "31;0"
    show_info "removing $APP:\n" -1 "31;1"
    kubectl delete -f "services/$APP/$APP.yaml"
    echo ""
  done
fi

################################################################################

if [ "$DASHBOARD" = "yes" ] ; then
  show_info " S T A R T I N G   M I N I K U B E   D A S H B O A R D\n\n" -1 "37;1"
  is_minikube_running yes

  show_info " please wait..." -1 "30;0"
  ( minikube dashboard 2>/dev/null ) &
  sleep 2
fi

################################################################################

if [ "$SCALA" = "yes" ] ; then
  show_info " S T A R T I N G   S P A R K   S C A L A   A P P L I C A T I O N\n\n" -1 "37;1"
  is_minikube_running yes
  MINIKUBE_IP="$(minikube ip)"

  sbt 'compile'
  sbt "run ${MINIKUBE_IP}"
fi

################################################################################

if [ "$LOGS" != "" ] ; then
  show_info " D I S P L A Y I N G   M I N I K U B E   P O D   L O G\n\n" -1 "37;1"
  is_minikube_running yes

  PODS=`kubectl get pods | grep "$LOGS" | awk '{print $1}'`

  if [ "$?" != "0" ] ; then
    show_info "Cannot get log for the pod =~ /$LOGS/, maybe try again?\n\n" 1 "31;1"
  fi

  if [ "$PODS" == "" ] ; then
    show_info "Cannot find pod by '| grep $LOGS'\n\n" 1 "31;1"
  fi

  for POD in $PODS
  do
    show_info "===================================================================\n" -1 "33;1"
    show_info "| Log for pod '$POD'\n" -1 "33;1"
    show_info "-------------------------------------------------------------------\n" -1 "33;1"
    kubectl logs $POD
  done
  show_info "===================================================================\n" -1 "33;1"
  echo ""
  exit 0
fi

################################################################################

if [ "`minikube status | grep host: | awk '{print $2}'`" = "Running" ]; then
  MINIKUBE_IP="$(minikube ip)"
  show_info "\nminikube ip = $MINIKUBE_IP\n" -1 "37;1"
fi

show_info "\n__END__\n\n" -1 "37;1"
