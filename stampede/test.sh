#!/bin/bash

set -u

ARG1="foo"
ARG2="10"

./00-controller.sh -a $ARG1 -b $ARG2
