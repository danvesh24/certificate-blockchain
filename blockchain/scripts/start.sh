
docker-compose -f ../artifacts/channel/create-certificate-with-ca/docker-compose.yaml up -d

sleep 3

cd ../artifacts/channel/create-certificate-with-ca

sleep 2

./create-certificate-with-ca.sh

cd .. && ./create-artifacts.sh

cd ..

docker-compose -f ../artifacts/docker-compose.yaml up -d

cd ../scripts

./createChannel.sh

sleep 3

./deployChaincode_2.sh 