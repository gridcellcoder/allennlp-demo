#    Modifications Copyright 2019 GridCell Ltd
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

# This Dockerfile is used to serve the AllenNLP demo.

FROM allennlp/commit:31af01e0db7ac401b6c4923d5badd7de2691d6a2
LABEL maintainer="allennlp-contact@allenai.org"

WORKDIR /stage/allennlp

# Use cache busting to install and upgrade https://docs.docker.com/develop/develop-images/dockerfile_best-practices/
RUN apt-get -y update && apt-get -y upgrade

# Install Java.
RUN echo "deb http://http.debian.net/debian jessie-backports main" >>/etc/apt/sources.list
RUN apt-get update && apt-get install -y -t jessie-backports openjdk-8-jdk


# Install npm early so layer is cached when mucking with the demo
RUN curl -sL https://deb.nodesource.com/setup_8.x | bash - && apt-get install -y nodejs

# Install postgres binary
RUN pip install psycopg2-binary
RUN pip install sentry-sdk==0.7.1

# Download spacy model
RUN spacy download en_core_web_sm

COPY scripts/ scripts/
COPY server/models.py server/models.py

# Now install and build the demo
COPY demo/ demo/
RUN ./scripts/build_demo.py

COPY tests/ tests/
COPY app.py app.py
COPY server/ server/

RUN pytest tests/

# Optional argument to set an environment variable with the Git SHA
ARG SOURCE_COMMIT
ENV ALLENNLP_DEMO_SOURCE_COMMIT $SOURCE_COMMIT

EXPOSE 8000

ENV ALLENNLP_DEMO_DIRECTORY /stage/allennlp/demo

ENTRYPOINT ["./app.py"]
