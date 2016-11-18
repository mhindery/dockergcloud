# DockerGcloud
This is a lightweight container starting from docker, installing the Gcloud SDK and the kubectl gcloud component. It is used specifically in a Gitlab CI setup running docker-in-docker (*dind*) and building + deploying to GCloud GCE with Kubernetes.

The default docker image used in the Gitlab example has no Gcloud SDK installed. The official full-blown [Google cloud-sdk image](https://hub.docker.com/r/google/cloud-sdk/) doesn't work as base image for *dind* and is a few hundred MB large. The image I based this on is [cwt114/alpine-gcloud](https://hub.docker.com/r/cwt114/alpine-gcloud/) which also doesn't start from a clean docker image. Hence this custom one.

## Gitlab CI example:

The following is a basic example of a *.gitlab-ci.yml* file with 2 stages: push and deploy. It uses the docker-in-docker setup following the [Gitlab docs](https://docs.gitlab.com/ce/ci/docker/using_docker_build.html#use-docker-in-docker-executor). The push stage will build your custom docker image (needs a Dockerfile of course), tag it with its commit hash, authenticate with gcloud using a service account, and push the image to you registry. You need to set the GOOGLE_SA_JSON environment variable in your GitLab project variables, with as its value your Google Service Account json content. The deploy stage will deploy that image to a Kubernetes cluster on GCE (also needs some environment variables).

```
image: mhindery/dockergcloud
services:
  - docker:dind

variables:
  DOCKER_DRIVER: overlay
  IMAGE_TAG: <your_gcr_url>:$CI_BUILD_REF

stages:
  - push
  - deploy

push:
  stage: push
  only:
    - master
    - staging
  script:
    - docker build -t $IMAGE_TAG .
    - echo $GOOGLE_SA_JSON >> /tmp/google_sa.json
    - gcloud auth activate-service-account --key-file /tmp/google_sa.json
    - gcloud docker push $IMAGE_TAG

deploy:
  stage: deploy
  only:
    - staging
  dependencies:
    - push
  script:
    - echo $GOOGLE_SA_JSON >> /tmp/google_sa.json
    - export GOOGLE_APPLICATION_CREDENTIALS=/tmp/google_sa.json
    - gcloud auth activate-service-account --key-file /tmp/google_sa.json
    - gcloud container clusters get-credentials $GCLOUD_CLUSTER --project $GCLOUD_PROJECT --zone $GCLOUD_ZONE
    - kubectl set image deployment/<deployment_name> <container_name>=$IMAGE_TAG
```
