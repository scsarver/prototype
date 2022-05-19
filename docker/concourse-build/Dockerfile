FROM bash

RUN set -x \
  apk add --update --force glibc; \
  apk add --update --force groff; \
  apk add --update --force less; \
  apk add --update --force curl jq; \
  apk add --update --force jq; \
  which curl; \
  # install aws cli \
  curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"; \
  unzip awscliv2.zip -qq; \
  echo "=========="; \
  ls -la /aws/dist/aws; \
  ./aws/install; \
  #  /usr/local/bin/aws --version; \
  which aws; \
  ls -la /usr/local/bin/aws; \
  aws --version; \
  echo "Stopped here after finding the AWSCLI install here is complaining that it can not find '/bin/sh: aws: not found'"
  
