echo "Checking for and deleting .tar.gz files in the current directory..."
find . -type f -name "*.tar.gz" -exec rm -f {} \;
echo "All .tar.gz files have been deleted."

echo "Removing log.txt file"
LOG_BLOCK_PATH="log.txt"

# Check if the file exists and delete it
if [ -f "$LOG_BLOCK_PATH" ]; then
    rm -f "$LOG_BLOCK_PATH"
    echo "Removed log.txt."
else
    echo "No log.txt file found to remove."
fi

echo "Removing channel.block file from ../channel-artifacts/..."
CHANNEL_BLOCK_PATH="../channel-artifacts/mychannel.block"

# Check if the file exists and delete it
if [ -f "$CHANNEL_BLOCK_PATH" ]; then
    rm -f "$CHANNEL_BLOCK_PATH"
    echo "Removed channel.block file."
else
    echo "No channel.block file found to remove."
fi

echo "Removing all Docker containers..."
docker rm -f $(docker ps -a -q)

cd ../artifacts/channel/create-certificate-with-ca/

sleep 5

docker-compose up -d

sleep 5

./create-certificate-with-ca.sh

sleep 5 

cd .. && ./create-artifacts.sh

sleep 5 

cd ../

sleep 5

docker-compose up -d 

sleep 5

cd ../scripts

sleep 5 

./createChannel.sh

sleep 3

./deployChaincode_2.sh 