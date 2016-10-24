#!/bin/bash
rm -rf /opt/influxdb-relay;

mkdir /opt/influxdb-relay;

export GOPATH=/opt/influxdb-relay/;
export GOROOT=/opt/go;
go get -u github.com/influxdata/influxdb-relay
