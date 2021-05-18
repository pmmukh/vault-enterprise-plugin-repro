#!/bin/bash

while :
do
    vault login -address=http://127.0.0.1:8300 -method=userpass username=user password=password
    sleep 0.1
done
