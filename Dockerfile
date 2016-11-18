FROM docker:latest
MAINTAINER Mathieu Hinderyckx "mathieu.hinderyckx@gmail.com"

ENV GCLOUD_SDK_VERSION=135.0.0
ENV GCLOUD_SDK_URL=https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-sdk-${GCLOUD_SDK_VERSION}-linux-x86_64.tar.gz

RUN apk add --update python
RUN apk add curl openssl \
 && mkdir /opt && cd /opt \
 && wget -q -O - $GCLOUD_SDK_URL |tar zxf - \
 && /bin/sh -l -c "echo Y | /opt/google-cloud-sdk/install.sh && exit" \
 && /bin/sh -l -c "echo Y | /opt/google-cloud-sdk/bin/gcloud components install kubectl && exit" \\
 && rm -rf /opt/google-cloud-sdk/.install/.backup

ENV PATH="/opt/google-cloud-sdk/bin:${PATH}"

WORKDIR /root
