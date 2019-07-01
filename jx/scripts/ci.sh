#!/usr/bin/env bash
set -e
set -x
set -u

export GH_USERNAME="jenkins-x-bot-test"
export GH_OWNER="cb-kubecd"

export GH_CREDS_PSW="$(jx step credential -s jenkins-x-bot-test-github)"
export GKE_SA="$(jx step credential -k bdd-credentials.json -s bdd-secret -f sa.json)"

jx step git credentials

# lets setup git
git config --global --add user.name JenkinsXBot
git config --global --add user.email jenkins-x@googlegroups.com

JX_HOME="/tmp/jxhome"
KUBECONFIG="/tmp/jxhome/config"

gcloud auth activate-service-account --key-file $GKE_SA

jx create terraform \
            -c "dev=gke" \
			--skip-login \
			-b --install-dependencies \
			--gke-service-account ${GKE_SA} \
			--local-organisation-repository . \
            --gke-zone europe-west1-c \
            --gke-machine-type n1-standard-2 \
            --gke-max-num-nodes 5 \
            --gke-min-num-nodes 2 \
            --git-username $GH_USERNAME \
            --environment-git-owner $GH_OWNER \
            --git-api-token $GH_CREDS_PSW \
            --cluster terraform-$VERSION=gke \
            --gke-project-id jenkins-x-bdd