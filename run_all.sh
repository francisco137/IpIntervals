#!/bin/bash

./ip_intervals.sh --build all -c
./ip_intervals.sh --minikube -c
./ip_intervals.sh --dashboard -c
./ip_intervals.sh --start -c
./ip_intervals.sh --execute -c
./ip_intervals.sh --remove -c
./ip_intervals.sh --quit -c

