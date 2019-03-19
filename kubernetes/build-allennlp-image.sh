#  Copyright 2019 GridCell Ltd
#
#    Licensed under the Apache License, Version 2.0 (the "License");
#    you may not use this file except in compliance with the License.
#    You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS,
#    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#    See the License for the specific language governing permissions and
#    limitations under the License.

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