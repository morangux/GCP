#!/bin/bash
#Please make sure to run this script as ROOT or with ROOT permissions
#Add the env you wish to delete in INSTNACES list. 
#Script will remove the vm, vpc, firewall-rules and release its public IP.

NC='\033[0m'
YELLOW='\033[0;33m'
GREEN='\033[0;32m'
RED='\033[0;31m'

REGIONS=("us-east1" "us-central1" "asia-east1")
ZONES=("us-east1-d" "us-central1-c" "asia-east1-a" "us-central1-a")
INSTANCES=( "demo" )
# INSTANCES=$(gcloud compute instances list | awk '{print$1}' | cut -d '-' -f 1 | uniq | sed '1d') #get all instances of a project


function delete-instance {
    for instance in ${INSTANCES[@]}
    do
        for zone in ${ZONES[@]}
        do
            gcloud compute instances delete "${instance}-master" "${instance}-worker-cpu*" "${instance}-worker-gpu-1" "${instance}-worker-gpu-2" --zone=${zone} -q 2>/dev/null
            if [ $? == 0 ]
            then
                echo -e "${GREEN}instance ${instance} has been deleted for zone ${zone}!${NC}"
            else
                echo -e "${RED}instance ${instance} failed to delete for zone ${zone}!${NC}"
            fi
        done
    done
}
function delete-vpc {
    for vpc in ${INSTANCES[@]}
    do
        for region in ${REGIONS[@]}
        do
            gcloud compute networks subnets delete "${vpc}" --region=${region} --quiet 2>/dev/null
            if [ $? == 0 ]
            then
                echo -e "${GREEN}vpc ${vpc} has been deleted for zone ${region}!${NC}"
            else 
                echo -e "${RED}vpc ${vpc} failed to delete for zone ${region}!${NC}"
            fi
        done
    done
}

function delete-firewall-rule {
    for firewall in ${INSTANCES[@]}
    do
        gcloud compute firewall-rules delete "${firewall}"-allow-outbound --quiet 2>/dev/null
        gcloud compute firewall-rules delete "${firewall}"-allow-api-server --quiet 2>/dev/null
        gcloud compute firewall-rules delete "${firewall}"-allow-internal-k8s --quiet 2>/dev/null
        if [ $? == 0 ]
        then
            echo -e "${GREEN}firewall ${firewall} has been deleted!${NC}"
        else
            echo -e "${RED}firewall ${firewall} failed to delete!${NC}"
        fi

    done
}

function release-public-ip {
    for instance in ${INSTANCES[@]}
    do
        for region in ${REGIONS[@]}
        do
            gcloud compute addresses delete "${instance}-master" --region=${region} -q 2>/dev/null
            if [ $? == 0 ]
            then
                echo -e "${GREEN}public ip ${instance}-master has been released for region ${region}!${NC}"
            else 
                echo -e "${RED}public ip ${instance}-master failed to release for region ${region}!${NC}"
            fi
        done

    done
}

function remove-dns-record {
    gcloud config set project run-ai-lab
    RECORDS=$(gcloud dns record-sets list --zone=run-ai-com | awk '{print$1}' | sed '1d')
    for record in ${RECORDS[@]}
    do
        echo -e "${YELLOW}Do you wish to remove ${record}${NC}(y/n)?"
        read answer
        if [ "${answer}" == "y" ]
        then
            gcloud dns record-sets delete "${record}" --type=A --zone=run-ai-com
            if [ $? == 0 ]
            then
                echo -e "${GREEN}A record ${record} deleted!${NC}"
            else 
                echo -e "${RED}A record ${record} failed delete!${NC}"
            fi
        fi
    done

}
###START HERE###
echo -e "${YELLOW}Please provide project id${NC}"
read project_id
gcloud config set project $project_id
delete-instance
delete-vpc
delete-firewall-rule
release-public-ip
remove-dns-record
