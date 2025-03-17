package main

import (
	"bytes"
	"crypto/sha256"
	"encoding/json"
	"fmt"
	"time"

	"github.com/hyperledger/fabric-chaincode-go/shim"
	"github.com/hyperledger/fabric-protos-go/peer"
	"github.com/hyperledger/fabric/common/flogging"
	"go.mongodb.org/mongo-driver/bson/primitive"
)

// BatchContract provides functions for interacting with the batch ledger
type BatchContract struct {
}

type Batch struct {
	ID            primitive.ObjectID `json:"id"`
	BatchID       string             `json:"batchId"`
	CreatedBy     primitive.ObjectID `json:"createdBy"`
	StartDatetime string             `json:"startDate"`
	EndDatetime   string             `json:"endDate"`
	CreatedDate   string             `json:"createdAt"`
	BlockHash     string             `json:"blockHash"`
}

type BatchQueryResult struct {
	ID        string `json:"BatchID"`
	BlockHash string `json:"blockHash"`
}

var logger = flogging.MustGetLogger("BatchContractLogger")

func (s *BatchContract) Init(APIstub shim.ChaincodeStubInterface) peer.Response {
	return shim.Success(nil)
}

func (s *BatchContract) CreateBatch(APIstub shim.ChaincodeStubInterface,
	id primitive.ObjectID,
	batchId string,
	createdBy primitive.ObjectID,
	startDate string,
	endDate string,
	createdAt string) error {

	// Check if batch already exists
	if batchAsBytes, err := APIstub.GetState(batchId); err != nil {
		return fmt.Errorf("failed to check if batch exists: %v", err)
	} else if batchAsBytes != nil {
		return fmt.Errorf("batch with ID %s already exists", batchId)
	}

	// Create the Batch object
	batch := Batch{
		ID:            id,
		BatchID:       batchId,
		CreatedBy:     createdBy,
		StartDatetime: startDate,
		EndDatetime:   endDate,
		CreatedDate:   createdAt,
	}

	// Compute BlockHash (excluding BlockHash field itself)
	hash, err := computeHash(batch)
	if err != nil {
		return fmt.Errorf("failed to compute block hash: %v", err)
	}
	batch.BlockHash = hash

	// Marshal the Batch object to JSON
	batchAsBytes, err := json.Marshal(batch)
	if err != nil {
		return fmt.Errorf("failed to marshal batch data: %v", err)
	}

	// Save the Batch object to the ledger
	if err := APIstub.PutState(id.Hex(), batchAsBytes); err != nil {
		return fmt.Errorf("failed to write batch to ledger: %v", err)
	}

	return nil
}

// computeHash computes the hash of a Batch object excluding the BlockHash field
func computeHash(batch Batch) (string, error) {
	// Create a temporary struct excluding the BlockHash field
	batchWithoutBlockHash := struct {
		ID            primitive.ObjectID `json:"id"`
		BatchID       string             `json:"batchId"`
		CreatedBy     primitive.ObjectID `json:"createdBy"`
		StartDatetime string             `json:"startDate"`
		EndDatetime   string             `json:"endDate"`
		CreatedDate   string             `json:"createdAt"`
	}{
		ID:            batch.ID,
		BatchID:       batch.BatchID,
		CreatedBy:     batch.CreatedBy,
		StartDatetime: batch.StartDatetime,
		EndDatetime:   batch.EndDatetime,
		CreatedDate:   batch.CreatedDate,
	}

	var buf bytes.Buffer
	encoder := json.NewEncoder(&buf)
	encoder.SetEscapeHTML(false)
	if err := encoder.Encode(batchWithoutBlockHash); err != nil {
		return "", fmt.Errorf("failed to marshal product item for hashing: %v", err)
	}

	// Remove the trailing newline added by json.Encoder.Encode()
	batchBytes := buf.Bytes()
	if len(batchBytes) > 0 && batchBytes[len(batchBytes)-1] == '\n' {
		batchBytes = batchBytes[:len(batchBytes)-1]
	}

	// Compute the SHA256 hash
	hash := sha256.Sum256(batchBytes)
	return fmt.Sprintf("%x", hash[:]), nil

}

func (s *BatchContract) QueryBatchesByIDs(APIstub shim.ChaincodeStubInterface, IDs []primitive.ObjectID) ([]BatchQueryResult, error) {
	var results []BatchQueryResult

	// Iterate over each provided ID
	for _, ID := range IDs {
		// Retrieve the batch from the ledger using the provided ID
		batchAsBytes, err := APIstub.GetState(ID.Hex())
		if err != nil {
			return nil, fmt.Errorf("failed to read batch with ID %s: %v", ID.Hex(), err)
		}

		// Check if the batch exists
		if batchAsBytes == nil {
			// If not found, add a pending result
			results = append(results, BatchQueryResult{
				ID:        ID.Hex(),
				BlockHash: "pending",
			})
		} else {
			// Unmarshal the batch data
			var batch Batch
			err = json.Unmarshal(batchAsBytes, &batch)
			if err != nil {
				return nil, fmt.Errorf("failed to unmarshal batch with ID %s: %v", ID.Hex(), err)
			}

			// Append the batch result (ID and BlockHash)
			results = append(results, BatchQueryResult{
				ID:        batch.ID.Hex(),
				BlockHash: batch.BlockHash,
			})
		}
	}

	// Return the list of BatchQueryResults
	return results, nil
}

// * QueryBatch retrieves a batch from the world state by batchId
func (s *BatchContract) QueryBatch(APIstub shim.ChaincodeStubInterface, ID primitive.ObjectID) (*Batch, error) {
	batchAsBytes, err := APIstub.GetState(ID.Hex())
	if err != nil {
		return nil, fmt.Errorf("failed to read batch: %v", err)
	}
	if batchAsBytes == nil {
		return nil, fmt.Errorf("batch not found: %s", ID)
	}

	var batch Batch
	err = json.Unmarshal(batchAsBytes, &batch)
	if err != nil {
		return nil, fmt.Errorf("failed to unmarshal batch data: %v", err)
	}

	return &batch, nil
}

// * QueryAllBatches retrieves all batches from the world state
func (s *BatchContract) QueryAllBatches(APIstub shim.ChaincodeStubInterface) ([]Batch, error) {
	resultsIterator, err := APIstub.GetStateByRange("", "")
	if err != nil {
		return nil, fmt.Errorf("failed to get batches: %v", err)
	}
	defer resultsIterator.Close()

	var batches []Batch

	for resultsIterator.HasNext() {
		queryResponse, err := resultsIterator.Next()
		if err != nil {
			return nil, fmt.Errorf("failed to iterate results: %v", err)
		}

		var batch Batch
		err = json.Unmarshal(queryResponse.Value, &batch)
		if err != nil {
			return nil, fmt.Errorf("failed to unmarshal batch data: %v", err)
		}

		batches = append(batches, batch)
	}

	return batches, nil
}

func (s *BatchContract) EditBatch(APIstub shim.ChaincodeStubInterface,
	ID primitive.ObjectID,
	batchId string,
	startDate *string,
	endDate *string) error {

	// Retrieve the current batch from the ledger
	batch, err := s.QueryBatch(APIstub, ID)
	if err != nil {
		return fmt.Errorf("failed to retrieve batch: %s", err.Error())
	}

	// Update the batch fields
	batch.BatchID = batchId

	if startDate != nil {
		batch.StartDatetime = *startDate
	}
	if endDate != nil {
		batch.EndDatetime = *endDate
	}

	// Compute the new hash using the computeHash function
	newHash, err := computeHash(*batch) // Dereference the pointer
	if err != nil {
		return fmt.Errorf("failed to compute hash: %s", err.Error())
	}

	// Update the BlockHash with the newly generated hash
	batch.BlockHash = newHash

	// Marshal the updated batch data
	batchAsBytes, err := json.Marshal(batch)
	if err != nil {
		return fmt.Errorf("failed to marshal updated batch: %s", err.Error())
	}

	// Store the updated batch back to the ledger
	err = APIstub.PutState(ID.Hex(), batchAsBytes)
	if err != nil {
		return fmt.Errorf("failed to update batch data: %s", err.Error())
	}

	return nil
}

func (s *BatchContract) GetBatchWithHash(APIstub shim.ChaincodeStubInterface, batchIds []string) peer.Response {
	var batchHashes []map[string]interface{}

	for _, id := range batchIds {
		batchID, err := primitive.ObjectIDFromHex(id)
		if err != nil {
			// Append "pending" hash for invalid IDs
			logger.Errorf("Invalid batch ID %s: %v", id, err)
			batchHashes = append(batchHashes, map[string]interface{}{
				"BatchID":   id,
				"blockHash": "pending",
			})
			continue
		}

		batch, err := s.QueryBatch(APIstub, batchID)
		if err != nil {
			batchHashes = append(batchHashes, map[string]interface{}{
				"BatchID":   id,
				"blockHash": "pending",
			})
			continue
		}

		// Marshal the batch data to JSON
		batchBytes, err := json.Marshal(batch)
		if err != nil {
			// Append "pending" hash for marshaling errors
			logger.Errorf("Failed to marshal batch data for ID %s: %v", id, err)
			batchHashes = append(batchHashes, map[string]interface{}{
				"BatchID":   id,
				"blockHash": "pending",
			})
			continue
		}

		hash := sha256.Sum256(batchBytes)
		hashHex := fmt.Sprintf("%x", hash[:])

		batchHashes = append(batchHashes, map[string]interface{}{
			"BatchID":   batch.ID.Hex(),
			"blockHash": hashHex,
		})

	}

	batchHashesBytes, err := json.Marshal(batchHashes)
	if err != nil {
		return shim.Error(fmt.Sprintf("Failed to marshal batch hashes: %v", err))
	}

	return shim.Success(batchHashesBytes)
}

// * Invoke method handles the requests from the client and routes them to the appropriate function
func (s *BatchContract) Invoke(APIstub shim.ChaincodeStubInterface) peer.Response {
	function, args := APIstub.GetFunctionAndParameters()

	switch function {
	case "CreateBatch":
		if len(args) != 6 {
			return shim.Error("Incorrect number of arguments. Expecting 6")
		}
		ID, err := primitive.ObjectIDFromHex(args[0])
		if err != nil {
			return shim.Error(fmt.Sprintf("Invalid ID: %s", args[0]))
		}
		createdBy, err := primitive.ObjectIDFromHex(args[2])
		if err != nil {
			return shim.Error(fmt.Sprintf("Invalid createdBy: %s", args[2]))
		}

		err = s.CreateBatch(APIstub, ID, args[1], createdBy, args[3], args[4], args[5])
		if err != nil {
			return shim.Error(fmt.Sprintf("Failed to create batch: %s", err.Error()))
		}
		txID := APIstub.GetTxID()

		txTimestamp, err := APIstub.GetTxTimestamp()
		if err != nil {
			return shim.Error(fmt.Sprintf("Failed to get transaction timestamp: %v", err))
		}

		// Convert timestamp to readable format
		timestamp := time.Unix(txTimestamp.Seconds, int64(txTimestamp.Nanos)).UTC().Format(time.RFC3339)

		response := map[string]interface{}{
			"message":   "Batch created successfully",
			"txId":      txID,
			"timeStamp": timestamp,
		}

		// Marshal the response to JSON
		responseJSON, err := json.Marshal(response)
		if err != nil {
			return shim.Error(fmt.Sprintf("Failed to marshal response: %v", err))
		}

		// Return success with the JSON response
		return shim.Success(responseJSON)

	case "EditBatch":
		if len(args) < 1 || len(args) > 4 {
			return shim.Error("Incorrect number of arguments. Expecting 1 to 3")
		}

		var startDate, endDate *string

		ID, err := primitive.ObjectIDFromHex(args[0])
		if err != nil {
			return shim.Error(fmt.Sprintf("Invalid ID: %s", args[0]))
		}
		if len(args) > 1 {
			startDate = &args[2]
		}
		if len(args) > 2 {
			endDate = &args[3]
		}

		err = s.EditBatch(APIstub, ID, args[1], startDate, endDate)
		if err != nil {
			return shim.Error(fmt.Sprintf("Failed to edit batch: %s", err.Error()))
		}

		txID := APIstub.GetTxID()

		txTimestamp, err := APIstub.GetTxTimestamp()
		if err != nil {
			return shim.Error(fmt.Sprintf("Failed to get transaction timestamp: %v", err))
		}

		// Convert timestamp to readable format
		timestamp := time.Unix(txTimestamp.Seconds, int64(txTimestamp.Nanos)).UTC().Format(time.RFC3339)

		response := map[string]interface{}{
			"message":   "Batch edited successfully",
			"txId":      txID,
			"timeStamp": timestamp,
		}

		// Marshal the response to JSON
		responseJSON, err := json.Marshal(response)
		if err != nil {
			return shim.Error(fmt.Sprintf("Failed to marshal response: %v", err))
		}

		// Return success with the JSON response
		return shim.Success(responseJSON)

	case "QueryBatch":
		if len(args) != 1 {
			return shim.Error("Incorrect number of arguments. Expecting 1")
		}
		ID, err := primitive.ObjectIDFromHex(args[0])
		if err != nil {
			return shim.Error(fmt.Sprintf("Invalid ID: %s", args[0]))
		}
		batch, err := s.QueryBatch(APIstub, ID)
		if err != nil {
			return shim.Error(fmt.Sprintf("Failed to query batch: %s", err.Error()))
		}

		batchAsBytes, err := json.Marshal(batch)
		if err != nil {
			return shim.Error(fmt.Sprintf("Failed to marshal batch: %s", err.Error()))
		}

		return shim.Success(batchAsBytes)

	case "QueryBatchesByIDs":
		if len(args) < 1 {
			return shim.Error("Incorrect number of arguments. Expecting at least 1")
		}

		var IDs []primitive.ObjectID
		for _, arg := range args {
			ID, err := primitive.ObjectIDFromHex(arg)
			if err != nil {
				return shim.Error(fmt.Sprintf("Invalid ID: %s", arg))
			}
			IDs = append(IDs, ID)
		}

		// Call QueryBatchesByIDs function to return id and blockHash for each ID
		batchesResult, err := s.QueryBatchesByIDs(APIstub, IDs)
		if err != nil {
			return shim.Error(fmt.Sprintf("Failed to query batches: %s", err.Error()))
		}

		// Marshal the result (batch ID and blockHash for each) to JSON
		batchesAsBytes, err := json.Marshal(batchesResult)
		if err != nil {
			return shim.Error(fmt.Sprintf("Failed to marshal batches: %s", err.Error()))
		}

		return shim.Success(batchesAsBytes)

	case "QueryAllBatches":
		batches, err := s.QueryAllBatches(APIstub)
		if err != nil {
			return shim.Error(fmt.Sprintf("Failed to query all batches: %s", err.Error()))
		}

		batchesAsBytes, err := json.Marshal(batches)
		if err != nil {
			return shim.Error(fmt.Sprintf("Failed to marshal batches: %s", err.Error()))
		}

		return shim.Success(batchesAsBytes)
	case "GetBatchWithHash":
		if len(args) == 0 {
			return shim.Error("Incorrect number of arguments. Expecting at least one argument: IDs of Batch")
		}
		return s.GetBatchWithHash(APIstub, args)
	default:
		return shim.Error("Invalid function name")
	}
}

func main() {
	err := shim.Start(new(BatchContract))
	if err != nil {
		logger.Fatalf("Error starting Batch contract chaincode: %s", err)
	}
}
