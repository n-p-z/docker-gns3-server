FROM alpine:3.20.2

# Install the magic wrapper.
COPY dependencies.json /tmp/dependencies.json
COPY ./CiscoIOUKeygen.py /CiscoIOUKeygen.py
COPY ./start.sh /start.sh
COPY ./config.ini /config.ini
COPY ./requirements.txt /requirements.txt



RUN mkdir /data && \
    apk add --no-cache --virtual=build-dependencies jq gcc python3-dev musl-dev linux-headers \
    && jq -r 'to_entries | .[] | .key + "=" + .value' /tmp/dependencies.json | xargs apk add --no-cache \
    && pip install -r /requirements.txt --break-system-packages \
    && apk del --purge build-dependencies
RUN python3.5 -m pip install CiscoIOUKeygen.py

CMD [ "/start.sh" ]

# workaround for https://github.com/GNS3/gns3-server/issues/2367
RUN ln -s /bin/busybox /usr/lib/python*/site-packages/gns3server/compute/docker/resources/bin

WORKDIR /data

VOLUME ["/data"]
