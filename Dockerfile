FROM alpine:latest

LABEL version="1.0"

ENV KODI_START_CMD="kodi-gbm --standalone"
ENV KODI_PROC_NAME="kodi-gbm"

RUN apk update
RUN apk add kodi-gbm v4l-utils

COPY cec_monitor.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/cec_monitor.sh

COPY entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/entrypoint.sh

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
