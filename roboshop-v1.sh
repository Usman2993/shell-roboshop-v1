#!/bin/bash

ami_id="ami-0055977a6e828a4f4"
instance_type="t3.micro"
domain_name="usdaws92s.store"
hosted_zone_id="Z008324910L7ZOOUSXMNQ"

for instance in $@
do
    echo "crecating instance: ${instance}"
done