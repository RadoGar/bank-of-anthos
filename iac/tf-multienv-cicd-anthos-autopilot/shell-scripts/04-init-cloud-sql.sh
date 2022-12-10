# Copyright 2022 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

set -uo pipefail

echo "🚀  Starting $0"

echo '🌱  Initializing setting up development config...'
echo '🔑  Getting cluster credentials...'
gcloud container fleet memberships get-credentials development-membership
echo '🙌  Setting default container registry for development...'
/usr/local/bin/skaffold config set default-repo $REGION-docker.pkg.dev/$PROJECT_ID/bank-of-anthos

echo '🌱  Initializing staging db...'
echo '🔑  Getting cluster credentials...'
gcloud container fleet memberships get-credentials staging-membership
echo '🙌  Deploying populate-db jobs for staging...'
/usr/local/bin/skaffold config set default-repo $REGION-docker.pkg.dev/$PROJECT_ID/bank-of-anthos
/usr/local/bin/skaffold run --profile=init-db-staging --module=accounts-db
/usr/local/bin/skaffold run --profile=init-db-staging --module=ledger-db
echo '🕰  Wait for staging-db initialization to complete...'
kubectl wait --for=condition=complete job/populate-accounts-db job/populate-ledger-db -n bank-of-anthos-staging --timeout=300s

echo '🌱  Initializing production db...'
echo '🔑  Getting cluster credentials...'
gcloud container fleet memberships get-credentials production-membership
echo '🙌  Deploying populate-db jobs for staging...'
/usr/local/bin/skaffold config set default-repo $REGION-docker.pkg.dev/$PROJECT_ID/bank-of-anthos
/usr/local/bin/skaffold run --profile=init-db-production --module=accounts-db
/usr/local/bin/skaffold run --profile=init-db-production --module=ledger-db
echo '🕰  Wait for production-db initialization to complete...'
kubectl wait --for=condition=complete job/populate-accounts-db job/populate-ledger-db -n bank-of-anthos-production --timeout=300s

echo "✅  Finished $0"
