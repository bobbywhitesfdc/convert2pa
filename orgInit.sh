#!/bin/bash
# Exit on error!
set -euxo pipefail
#create scratch org
sfdx force:org:create -f config/project-scratch-def.json -s -a CVT2PA username=convert@example.org --durationdays 28
sf project deploy start
sf org open
