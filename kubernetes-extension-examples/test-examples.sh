#!/bin/bash
# ---------------------------------------------------------------------------
#  Copyright (c) 2019, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
#
#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at
#
#  http://www.apache.org/licenses/LICENSE-2.0
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.

trap ctrl_c INT
trap on_error ERR

function ctrl_c() {
    printf "cancelling running tests\n"
    exit 2;
}

function on_error() {
    printf "error: unable to run tests due to error\n"
    exit 1;
 }

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

if [[ "$1" != "" ]]
then
    brew update
    # openshift-deployment test
    pushd "$SCRIPT_DIR"/examples/openshift-deployment /dev/null 2>&1 || exit
        minishift update --update-addons -v 1
        minishift version
        minishift start
        oc login -u system:admin
        oc delete project hello-api --ignore-not-found=true
        eval $(minishift docker-env)
        docker rmi 172.30.1.1:5000/hello-api/hello-service:v1.0 || true
        while read -r line
        do
            [[ $line != \$* ]] && continue
            command=${line/$ /}

            # Modify commands when needed
            if [[ $command = \ballerina* ]]
            then
                command=${command/ballerina/$1}
            elif [[ $command = \oc\ get\ pods* ]]
            then
              printf "info: sleeping for 5 seconds\n"
              sleep 5
            elif [[ $command = \curl* ]]
            then
                MINISHIFT_IP=$(minishift ip)
                command=${command/192.168.99.101/$MINISHIFT_IP}
            fi

            printf "$> %s\n" "$command"
            CMD_OUTPUT=$(${command} | tee /dev/tty)

            # Assert outputs
            if [[ $command = \curl* && $CMD_OUTPUT != "Hello john!" ]]
            then
                printf "error: cannot find curl output\n"
                exit 1;
            fi
        done < "openshift_deployment.out"

        printf "\n"
        # Clean up
        kubectl delete -f ./kubernetes
        sleep 7
        docker rmi 172.30.1.1:5000/hello-api/hello-service:v1.0
        oc delete project hello-api
        rm openshift_deployment.jar
        rm -rf docker kubernetes
        minishift stop
    popd > /dev/null 2>&1 || exit
else
    printf "error: ballerina command location needs to be passed in as an argument\n"
    exit 1
fi
