#  Modified Copyright 2019 GridCell Ltd
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

# AllenNLP Demo

This repository contains the AllenNLP demo.

Here is an example for how to manually build the Docker image and run the demo on port 8000.

```
$ export GIT_HASH=`git log -1 --pretty=format:"%H"`
$ docker build -t allennlp/demo:$GIT_HASH .
$ docker run -p 8000:8000 allennlp/demo:$GIT_HASH
```

Note that the `run` process may get killed prematurely if there is insufficient memory allocated to Docker. As of September 14, 2018, setting a memory limit of 10GB was sufficient to run the demo. See [Docker Docs](https://docs.docker.com/docker-for-mac/#advanced) for more on setting memory allocation preferences.

## Development

To run the demo for development, you will need to:

1. Create a fresh environment:

    ```
    conda create -n allennlp-demo python=3.6
    source activate allennlp-demo
    pip install -r requirements.txt
    ```

    Note that this will install the latest _released_ version of AllenNLP - to use a version which you have been working on, run `python setup.py install` in the root of your clone of allennlp.

2. Build the frontend and start a development frontend service

    ```
    ./scripts/build_demo.py
    cd demo
    npm run start
    ```

    This will start a frontend service locally, which will hot refresh when you make changes to the JS.

3. (Optional) Set up a local DB for storing permalinks.

    ```
    brew install postgresql
    pg_ctl -D /usr/local/var/postgres start
    psql -d postgres -a -f scripts/local_db_setup.sql
    export DEMO_POSTGRES_HOST=localhost
    export DEMO_POSTGRES_DBNAME=postgres
    export DEMO_POSTGRES_USER=$USER
    ```

4. Start the backend service

    ```
    ./app.py
    ```

    Normally, the backend server would manage the frontend assets as well - the JS has a special hack for if it is running on port 3000 (which it does by default if you are running the unoptimized JS using `npm run start`), it will look for the backend service at port 8000. Otherwise, it serves the backend and the frontend from the same port.
 
 # Section added by by [gridcell](https://twitter.com/gridcell_io) 
 
 # Deploying on Kubernetes (Google Kubernetes Engine)
 
 ## Preparation
 
 1. Docker builds
 
 The script `build-allennlp-image.sh` builds the local `Dockerfile`, tags the image and uploads it to the 
 [Google Cloud Container Registry](https://cloud.google.com/container-registry/docs/).
 
 
 Set the following environment variables first 
 
 ```
 export PROJECT=some_project # Google Cloud project you are working under 
 export VERSION=0.8.2 #the `VERSION` to whatever you like e.g latest or 0.8.2
 ```
 Now set `CONTAINER_REGION`, the location of the container [registry](https://cloud.google.com/container-registry/docs/pushing-and-pulling)
 
 The four options are:
 
 * `gcr.io` hosts the images in the United States, but the location may change in the future
 * `us.gcr.io` hosts the image in the United States, in a separate storage bucket from images hosted by gcr.io
 * `eu.gcr.io` hosts the images in the European Union
 * `asia.gcr.io` hosts the images in Asia
  
Example
 
```bash
export CONTAINER_REGION=us.gcr.io
```

then run it

```bash
 cd kubernetes
./build-allennlp-image.sh
```

look out for something like 
```bash
The push refers to repository [us.gcr.io/YOUR_PROJECT/allennlp]
...
DIGEST        TAGS          TIMESTAMP
XXXXXXX  0.8.2,latest  2019-03-19T15:07:01
XXXXXXX                2019-03-12T20:25:41
```


2. Kuberetes preparation
 
 The `kubernetes` folder has all the kubernetes definition files to launch allennlp on a cluster
 
 * `allennlp.yml` contains a [StatefulSet](https://kubernetes.io/docs/concepts/workloads/controllers/statefulset/) that uses persistent volumes to store downloaded models on a disk attached to the node.
  This deployment is configured with 3 node replica. 
  
  Be sure to change the file in the containers section and replace `CHANGE_ME` with the tag of your Docker image from 1. above:
   i.e. `CONTAINER_REGION/PROJECT/allennlp:VERSION` e.g. `eu.gcr.io/some_project/allennlp:0.8.2`
   **Be sure to change this to the EXACT tag you got from step 1 or else you will get errors when deploying to Kubernetes** 
  
   ```yml
   containers:
        - name: allennlp
          image:  CHANGE_ME #enter path to docker registry e.g on google cloud container registry eu.gcr.io/PROJECT_ID/allennlp:0.8.2
   ```
          
 * `al-lb-svc.yml` cretes a load balancer with a public IP address (see below)on http port 80
 * `al-ia-svc.yml` cretes a internal (to the cluster) load balancer. For example if you have a client nodejs , python etc running on your kubernetes cluster you can refer to it by `http://al-lb-svc:8000/predict/machine-comprehension`
 * `gce-standard-sc.yml` the storage class of the disks (you can change this to ssd if you like `type: pd-ssd`)    
   
  
 ## Google Kubernetes Engine GKE
 
 The AllenNLP UI and backend can be deployed to a kubernetes cluster on a given cloud platform that supports Kubernetes. Requires
 * [Google Gloud SDK](https://cloud.google.com/sdk/install)
 * [Kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/) 
 * [Minikube](https://kubernetes.io/docs/setup/minikube/) - optional if you want to test locally first
 
 1. Follow the steps [here] (https://cloud.google.com/kubernetes-engine/docs/quickstart) to learn more about GKE
 
 2. Create a GKE cluster, 50GB disk, `highmem` instances are recommended for loading and serving models. Other [instances](https://cloud.google.com/compute/docs/machine-types) are available too.
 You can also add `--preemptible` to save running costs see [here](https://cloud.google.com/kubernetes-engine/docs/how-to/preemptible-vms)  
 
 ```
 gcloud container clusters create example-cluster \
       --node-locations us-central1-a \
       --additional-zones us-central1-b,us-central1-c \
       --machine-type=n1-highmem-4 \
       --disk-size=50
       --region us-central1
   ```
 3. Get access to the cluster
 
```bash
gcloud beta container clusters get-credentials example-cluster --region us-central1 --project YOUR_PROJECT_NAME
```
4. Apply the changes

```bash
kubectl apply -f kubernetes/allennlp.yml 
kubectl apply -f kubernetes/es-ia-svc.yml 
kubectl apply -f kubernetes/es-lb-svc.yml 
kubectl apply -f kubernetes/gce-standard-sc.yml
```

5. Check deployment.

Step 4 will create the stateful set with 3 persistent volumes each with its own persistent volume claim, an internal load balancer service and external load balancer

```bash
kubectl get all
```

should return something like 
```bash
NAME             READY     STATUS    RESTARTS   AGE
pod/allennlp-0   1/1       Running   0          6m
pod/allennlp-1   1/1       Running   0          4m
pod/allennlp-2   1/1       Running   0          2m

NAME                 TYPE           CLUSTER-IP     EXTERNAL-IP      PORT(S)          AGE
service/al-ia-svc    ClusterIP      10.XX.XX.X   <none>           8000/TCP         9m
service/al-lb-svc    LoadBalancer   10.XX.XX.X   YYY.YYY.YYY.YYY   8000:31627/TCP   9m
service/kubernetes   ClusterIP      10.XX.XX.X    <none>           443/TCP          12m

NAME                        DESIRED   CURRENT   AGE
statefulset.apps/allennlp   3         3         6m

```

6. Check the API through the load balancer

Using the address  `YYY.YYY.YYY.YYY` in step 5 you can query the API using Postman or Curl 

`http://YYY.YYY.YYY.YYY:8000/predict/machine-comprehension`

With the `POST` body

```json
{
    "passage": "Robotics is an interdisciplinary branch of engineering and science that includes mechanical engineering,"
    "question": "What do robots that resemble humans attempt to do?"
}
```


which should return something like (shortend and trunctated):
```json
{
    "best_span": [
        147,
        154
    ],
    "best_span_str": "replicate walking, lifting, speech, cognition",
    "passage_question_attention": [
        [
            0.2749797999858856,
            0.04183763265609741,
            0.17196990549564362,
            0.20194320380687714,
            0.04489961266517639,
            0.02290954254567623,
            0.055871427059173584,
            0.05694901570677757,
            0.06618849188089371,
            0.06245144084095955
        ],
        [
            0.21053647994995117,
            0.11562809348106384,
            0.11758492887020111,
            0.15465371310710907,
            0.1086740493774414,
            0.02625945955514908,
            0.04414062201976776,
            0.061525385826826096,
            0.09386775642633438,
            0.0671294555068016
        ],
        [
            0.11171773821115494,
            0.11988984048366547,
            0.023860322311520576,
            0.030449630692601204,
            0.021468957886099815,
            0.009852085262537003,
            0.020644865930080414,
            0.04953836649656296,
            0.41884300112724304,
            0.19373510777950287
        ]
    ],
    "passage_tokens": [
        "Robotics",
        "is",
        "an",
        "can",
        "do",
        "."
    ],
    "question_tokens": [
        "What",
        "do",
        "?"
    ],
    "span_end_logits": [
        -6.517852306365967,
        -12.051702499389648,
        -1.8338027000427246
    ],
    "span_end_probs": [
        0.0001122089524869807,
        4.4330960236038663e-7,
        0.009583641774952412,
        0.07637327909469604,
        0.048559825867414474,
        0.01214184332638979
    ],
    "span_start_logits": [
        -5.348807334899902,
        -10.847269058227539,
        -3.811220169067383,
        -4.827718734741211
    ],
    "span_start_probs": [
        0.000004799693670065608,
        1.9645446158733648e-8,
        0.000022334650566335768,
        0.00000808201093605021
    ]
}
```