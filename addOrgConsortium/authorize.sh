export ORDERER_CA=${PWD}/../orderer/crypto-config-ca/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
export CHANNEL_NAME=mychannel
export ORDERER_ADDRESS=orderer.example.com:7050
export CORE_PEER_ADDRESS=localhost:7051
export CORE_PEER_LOCALMSPID=Org1MSP
export CORE_PEER_TLS_ENABLED=true
export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/../org1/crypto-config-ca/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=${PWD}/../org1/crypto-config-ca/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp
export FABRIC_CFG_PATH=${PWD}/../config

configtxgen -printOrg Org3MSP > org3.json

peer channel fetch config config_block.pb -o $ORDERER_ADDRESS -c $CHANNEL_NAME --tls --cafile $ORDERER_CA --ordererTLSHostnameOverride orderer.example.com

configtxlator proto_decode --input config_block.pb --type common.Block | jq .data.data[0].payload.data.config > config.json

jq -s '.[0] * {"channel_group":{"groups":{"Application":{"groups": {"Org3MSP":.[1]}}}}}' config.json org3.json > modified_config.json

configtxlator proto_encode --input config.json --type common.Config --output config.pb
configtxlator proto_encode --input modified_config.json --type common.Config --output modified_config.pb
configtxlator compute_update --channel_id $CHANNEL_NAME --original config.pb --updated modified_config.pb --output config_update.pb


configtxlator proto_decode --input config_update.pb --type common.ConfigUpdate | jq . > config_update.json
echo '{"payload":{"header":{"channel_header":{"channel_id":"mychannel", "type":2}},"data":{"config_update":'$(cat config_update.json)'}}}' | jq . > config_update_in_envelope.json

configtxlator proto_encode --input config_update_in_envelope.json --type common.Envelope --output config_update_in_envelope.pb

peer channel signconfigtx -f config_update_in_envelope.pb

peer channel update -f config_update_in_envelope.pb -c $CHANNEL_NAME -o $ORDERER_ADDRESS --tls --cafile $ORDERER_CA


export ORDERER_CA=${PWD}/../orderer/crypto-config-ca/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
export CHANNEL_NAME=mychannel
export ORDERER_ADDRESS=orderer.example.com:7050
export CORE_PEER_ADDRESS=localhost:9051
export CORE_PEER_LOCALMSPID=Org2MSP
export CORE_PEER_TLS_ENABLED=true
export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/../org2/crypto-config-ca/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=${PWD}/../org2/crypto-config-ca/peerOrganizations/org2.example.com/users/Admin@org2.example.com/msp
export FABRIC_CFG_PATH=${PWD}/../config

peer channel update -f config_update_in_envelope.pb -c $CHANNEL_NAME -o $ORDERER_ADDRESS --tls --cafile $ORDERER_CA