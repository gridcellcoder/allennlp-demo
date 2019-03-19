#!/usr/bin/env bash

if [[ -z "${PROJECT}" ]]; then
      echo "Please specify a Google Compute project"
fi
if [[ -z "${VERSION}" ]]; then
      echo "Please specify a version"
fi

if [[ -z "${CONTAINER_REGION}" ]]; then
      echo "Please specify a container region"
fi


export CWD=`pwd`
gcloud auth configure-docker


cd ../
docker build . -t allennlp:$VERSION
docker tag  allennlp:$VERSION $CONTAINER_REGION/$PROJECT/allennlp:$VERSION
docker push $CONTAINER_REGION/$PROJECT/allennlp:$VERSION
gcloud container images list-tags $CONTAINER_REGION/$PROJECT/allennlp
cd $CWD