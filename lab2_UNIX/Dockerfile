FROM alpine:latest

RUN apk add --no-cache util-linux dos2unix

COPY run.sh /usr/local/bin/run.sh

RUN dos2unix /usr/local/bin/run.sh

RUN chmod +x /usr/local/bin/run.sh

ENTRYPOINT ["/usr/local/bin/run.sh"]
