package main

import (
	"bytes"
	"crypto/sha256"
	"encoding/json"
	"fmt"
	"time"

	"github.com/hyperledger/fabric-chaincode-go/shim"
	"github.com/hyperledger/fabric-protos-go/peer"
	"go.mongodb.org/mongo-driver/bson/primitive"
)

// Address represents the user's address details.
type Address struct {
	Zip         int    `json:"zip"`
	City        string `json:"city"`
	Country     string `json:"country"`
	AddressLine string `json:"addressLine"`
}

// User represents the updated user schema without refreshToken or password reset fields.
type User struct {
	ID                  primitive.ObjectID `json:"id"`
	FirstName           string             `json:"firstName"`
	LastName            string             `json:"lastName"`
	Email               string             `json:"email"`
	Password            string             `json:"password"`
	PhoneNumber         string             `json:"phoneNumber"`
	UserType            string             `json:"userType"`    // default: "company"
	CompanyName         string             `json:"companyName"`
	Address             Address            `json:"address"`
	Status              string             `json:"status"`      // e.g. pending, verified, declined, enabled
	ProfilePic          string             `json:"profilePic"`
	Remarks             string             `json:"remarks"`
	BlockChainTimeStamp string             `json:"blockChainTimeStamp"`
	BlockHash           string             `json:"blockHash"`
}

// UserQueryResult is used for returning ID and block hash for a user.
type UserQueryResult struct {
	ID        string `json:"id"`
	BlockHash string `json:"blockHash"`
}

// UserContract defines the chaincode structure.
type UserContract struct{}

// Init is called during chaincode instantiation to initialize any data.
func (uc *UserContract) Init(APIstub shim.ChaincodeStubInterface) peer.Response {
	return shim.Success(nil)
}

// computeUserHash computes a SHA256 hash of the user's data (excluding BlockHash).
func computeUserHash(user User) (string, error) {
	// Create a temporary struct that excludes BlockHash.
	userWithoutHash := struct {
		ID                  primitive.ObjectID `json:"id"`
		FirstName           string             `json:"firstName"`
		LastName            string             `json:"lastName"`
		Email               string             `json:"email"`
		Password            string             `json:"password"`
		PhoneNumber         string             `json:"phoneNumber"`
		UserType            string             `json:"userType"`
		CompanyName         string             `json:"companyName"`
		Address             Address            `json:"address"`
		Status              string             `json:"status"`
		ProfilePic          string             `json:"profilePic"`
		Remarks             string             `json:"remarks"`
		BlockChainTimeStamp string             `json:"blockChainTimeStamp"`
	}{
		ID:                  user.ID,
		FirstName:           user.FirstName,
		LastName:            user.LastName,
		Email:               user.Email,
		Password:            user.Password,
		PhoneNumber:         user.PhoneNumber,
		UserType:            user.UserType,
		CompanyName:         user.CompanyName,
		Address:             user.Address,
		Status:              user.Status,
		ProfilePic:          user.ProfilePic,
		Remarks:             user.Remarks,
		BlockChainTimeStamp: user.BlockChainTimeStamp,
	}

	var buf bytes.Buffer
	encoder := json.NewEncoder(&buf)
	encoder.SetEscapeHTML(false)
	if err := encoder.Encode(userWithoutHash); err != nil {
		return "", fmt.Errorf("failed to encode user for hashing: %v", err)
	}

	userBytes := buf.Bytes()
	// Remove the trailing newline added by encoder.Encode()
	if len(userBytes) > 0 && userBytes[len(userBytes)-1] == '\n' {
		userBytes = userBytes[:len(userBytes)-1]
	}

	hash := sha256.Sum256(userBytes)
	return fmt.Sprintf("%x", hash[:]), nil
}

// CreateUser creates a new user on the ledger.
// Expected arguments:
// [0]  ID (hex string for ObjectID)
// [1]  firstName
// [2]  lastName
// [3]  email
// [4]  password
// [5]  phoneNumber
// [6]  userType
// [7]  companyName
// [8]  address (JSON string)
// [9]  status
// [10] profilePic
// [11] remarks
func (uc *UserContract) CreateUser(APIstub shim.ChaincodeStubInterface,
	id primitive.ObjectID,
	firstName string,
	lastName string,
	email string,
	password string,
	phoneNumber string,
	userType string,
	companyName string,
	address Address,
	status string,
	profilePic string,
	remarks string) peer.Response {

	// Build the User object.
	user := User{
		ID:          id,
		FirstName:   firstName,
		LastName:    lastName,
		Email:       email,
		Password:    password,
		PhoneNumber: phoneNumber,
		UserType:    userType,
		CompanyName: companyName,
		Address:     address,
		Status:      status,
		ProfilePic:  profilePic,
		Remarks:     remarks,
	}

	// Set the blockchain timestamp.
	txTime, err := APIstub.GetTxTimestamp()
	if err != nil {
		return shim.Error(fmt.Sprintf("Failed to get transaction timestamp: %v", err))
	}
	user.BlockChainTimeStamp = time.Unix(txTime.Seconds, int64(txTime.Nanos)).UTC().Format(time.RFC3339)

	// Compute the user hash.
	hash, err := computeUserHash(user)
	if err != nil {
		return shim.Error(fmt.Sprintf("Failed to compute user hash: %v", err))
	}
	user.BlockHash = hash

	// Marshal and store the user object.
	userAsBytes, err := json.Marshal(user)
	if err != nil {
		return shim.Error(fmt.Sprintf("Failed to marshal user: %s", err))
	}
	if err := APIstub.PutState(id.Hex(), userAsBytes); err != nil {
		return shim.Error(fmt.Sprintf("Failed to create user: %s", err))
	}

	return shim.Success([]byte("User created successfully!!"))
}

// QueryUser retrieves a user from the ledger using the user's ID.
func (uc *UserContract) QueryUser(APIstub shim.ChaincodeStubInterface, ID primitive.ObjectID) (*User, error) {
	userAsBytes, err := APIstub.GetState(ID.Hex())
	if err != nil {
		return nil, fmt.Errorf("Failed to get user: %s", err)
	}
	if userAsBytes == nil {
		return nil, fmt.Errorf("User not found: %s", ID.Hex())
	}

	var user User
	if err := json.Unmarshal(userAsBytes, &user); err != nil {
		return nil, fmt.Errorf("Failed to unmarshal user: %s", err)
	}
	return &user, nil
}

// QueryUsersByIDs retrieves multiple users and returns their ID and BlockHash.
func (uc *UserContract) QueryUsersByIDs(APIstub shim.ChaincodeStubInterface, IDs []primitive.ObjectID) ([]UserQueryResult, error) {
	var results []UserQueryResult
	for _, id := range IDs {
		userAsBytes, err := APIstub.GetState(id.Hex())
		if err != nil {
			return nil, fmt.Errorf("failed to read user with ID %s: %v", id.Hex(), err)
		}
		if userAsBytes == nil {
			results = append(results, UserQueryResult{
				ID:        id.Hex(),
				BlockHash: "pending",
			})
		} else {
			var user User
			if err := json.Unmarshal(userAsBytes, &user); err != nil {
				return nil, fmt.Errorf("failed to unmarshal user with ID %s: %v", id.Hex(), err)
			}
			results = append(results, UserQueryResult{
				ID:        user.ID.Hex(),
				BlockHash: user.BlockHash,
			})
		}
	}
	return results, nil
}

// EditUser updates the details of an existing user.
// Expected arguments (in the same order as CreateUser):
// [0]  ID (hex string)
// [1]  firstName
// [2]  lastName
// [3]  email
// [4]  password
// [5]  phoneNumber
// [6]  userType
// [7]  companyName
// [8]  address (JSON string)
// [9]  status
// [10] profilePic
// [11] remarks
func (uc *UserContract) EditUser(APIstub shim.ChaincodeStubInterface,
	ID primitive.ObjectID,
	firstName string,
	lastName string,
	email string,
	password string,
	phoneNumber string,
	userType string,
	companyName string,
	address Address,
	status string,
	profilePic string,
	remarks string) peer.Response {

	user, err := uc.QueryUser(APIstub, ID)
	if err != nil {
		return shim.Error(fmt.Sprintf("User not found: %s", err))
	}

	// Update the user's fields.
	user.FirstName = firstName
	user.LastName = lastName
	user.Email = email
	user.Password = password
	user.PhoneNumber = phoneNumber
	user.UserType = userType
	user.CompanyName = companyName
	user.Address = address
	user.Status = status
	user.ProfilePic = profilePic
	user.Remarks = remarks

	// Optionally update the blockchain timestamp.
	txTime, err := APIstub.GetTxTimestamp()
	if err == nil {
		user.BlockChainTimeStamp = time.Unix(txTime.Seconds, int64(txTime.Nanos)).UTC().Format(time.RFC3339)
	}

	// Recompute the hash.
	newHash, err := computeUserHash(*user)
	if err != nil {
		return shim.Error(fmt.Sprintf("Failed to compute hash: %s", err))
	}
	user.BlockHash = newHash

	// Marshal and update the user on the ledger.
	userAsBytes, err := json.Marshal(user)
	if err != nil {
		return shim.Error(fmt.Sprintf("Failed to marshal updated user: %s", err))
	}
	if err := APIstub.PutState(ID.Hex(), userAsBytes); err != nil {
		return shim.Error(fmt.Sprintf("Failed to update user: %s", err))
	}

	return shim.Success([]byte("User updated successfully"))
}

// func (uc *UserContract) QueryUsersByIDs(APIstub shim.ChaincodeStubInterface, IDs []primitive.ObjectID) ([]UserQueryResult, error) {
// 	var results []UserQueryResult

// 	// Iterate over each provided ID
// 	for _, ID := range IDs {
// 		// Retrieve the user from the ledger using the provided ID
// 		userAsBytes, err := APIstub.GetState(ID.Hex())
// 		if err != nil {
// 			return nil, fmt.Errorf("failed to read user with ID %s: %v", ID.Hex(), err)
// 		}

// 		// Check if the user exists
// 		if userAsBytes == nil {
// 			// If not found, add a pending result
// 			results = append(results, UserQueryResult{
// 				ID:        ID.Hex(),
// 				BlockHash: "pending",
// 			})
// 		} else {
// 			// Unmarshal the user data
// 			var user User
// 			err = json.Unmarshal(userAsBytes, &user)
// 			if err != nil {
// 				return nil, fmt.Errorf("failed to unmarshal user with ID %s: %v", ID.Hex(), err)
// 			}

// 			// Append the user result (ID and BlockHash)
// 			results = append(results, UserQueryResult{
// 				ID:        user.ID.Hex(),
// 				BlockHash: user.BlockHash,
// 			})
// 		}
// 	}

// 	// Return the list of BatchQueryResults
// 	return results, nil
// }

// GetUserWithHash retrieves one or more users and returns new hash info for each.
func (uc *UserContract) GetUserWithHash(APIstub shim.ChaincodeStubInterface, IDs []string) peer.Response {
	var userHashes []map[string]interface{}
	for _, idStr := range IDs {
		id, err := primitive.ObjectIDFromHex(idStr)
		if err != nil {
			userHashes = append(userHashes, map[string]interface{}{
				"id":        idStr,
				"blockHash": "invalid-id",
			})
			continue
		}

		user, err := uc.QueryUser(APIstub, id)
		if err != nil {
			userHashes = append(userHashes, map[string]interface{}{
				"id":        id.Hex(),
				"blockHash": "not-found",
			})
			continue
		}

		userBytes, err := json.Marshal(user)
		if err != nil {
			userHashes = append(userHashes, map[string]interface{}{
				"id":        id.Hex(),
				"blockHash": "marshal-error",
			})
			continue
		}

		hash := sha256.New()
		hash.Write(userBytes)
		hashBytes := hash.Sum(nil)
		hashHex := fmt.Sprintf("%x", hashBytes)

		userHashes = append(userHashes, map[string]interface{}{
			"id":        id.Hex(),
			"blockHash": hashHex,
		})
	}

	responseBytes, err := json.Marshal(userHashes)
	if err != nil {
		return shim.Error(fmt.Sprintf("Failed to marshal response: %v", err))
	}

	return shim.Success(responseBytes)
}

// Invoke routes function calls to the appropriate handler.
func (uc *UserContract) Invoke(APIstub shim.ChaincodeStubInterface) peer.Response {
	function, args := APIstub.GetFunctionAndParameters()

	switch function {
	case "CreateUser":
		if len(args) != 12 {
			return shim.Error("Incorrect number of arguments. Expecting 12")
		}
		id, err := primitive.ObjectIDFromHex(args[0])
		if err != nil {
			return shim.Error(fmt.Sprintf("Invalid ID: %s", args[0]))
		}
		// Parse address from JSON.
		var address Address
		if err := json.Unmarshal([]byte(args[8]), &address); err != nil {
			return shim.Error(fmt.Sprintf("Invalid address JSON: %s", err.Error()))
		}
		response := uc.CreateUser(APIstub, id, args[1], args[2], args[3], args[4],
			args[5], args[6], args[7], address, args[9], args[10], args[11])
		if response.Status != shim.OK {
			return response
		}
		txID := APIstub.GetTxID()
		txTimestamp, err := APIstub.GetTxTimestamp()
		if err != nil {
			return shim.Error(fmt.Sprintf("Failed to get transaction timestamp: %v", err))
		}
		timestamp := time.Unix(txTimestamp.Seconds, int64(txTimestamp.Nanos)).UTC().Format(time.RFC3339)
		responseData := map[string]interface{}{
			"message":   "User created successfully",
			"txId":      txID,
			"timeStamp": timestamp,
		}
		responseJSON, err := json.Marshal(responseData)
		if err != nil {
			return shim.Error(fmt.Sprintf("Failed to marshal response: %v", err))
		}
		return shim.Success(responseJSON)

	case "EditUser":
		if len(args) != 12 {
			return shim.Error("Incorrect number of arguments. Expecting 12")
		}
		id, err := primitive.ObjectIDFromHex(args[0])
		if err != nil {
			return shim.Error(fmt.Sprintf("Invalid ID: %s", args[0]))
		}
		var address Address
		if err := json.Unmarshal([]byte(args[8]), &address); err != nil {
			return shim.Error(fmt.Sprintf("Invalid address JSON: %s", err.Error()))
		}
		response := uc.EditUser(APIstub, id, args[1], args[2], args[3], args[4],
			args[5], args[6], args[7], address, args[9], args[10], args[11])
		if response.Status != shim.OK {
			return response
		}
		txID := APIstub.GetTxID()
		txTimestamp, err := APIstub.GetTxTimestamp()
		if err != nil {
			return shim.Error(fmt.Sprintf("Failed to get transaction timestamp: %v", err))
		}
		timestamp := time.Unix(txTimestamp.Seconds, int64(txTimestamp.Nanos)).UTC().Format(time.RFC3339)
		responseData := map[string]interface{}{
			"message":   "User updated successfully",
			"txId":      txID,
			"timeStamp": timestamp,
		}
		responseJSON, err := json.Marshal(responseData)
		if err != nil {
			return shim.Error(fmt.Sprintf("Failed to marshal response: %v", err))
		}
		return shim.Success(responseJSON)
	
	case "QueryUsersByIDs":
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

		// Call QueryUsersByIDs function to return id and blockHash for each ID
		usersResult, err := uc.QueryUsersByIDs(APIstub, IDs)
		if err != nil {
			return shim.Error(fmt.Sprintf("Failed to query users: %s", err.Error()))
		}

		// Marshal the result (user ID and blockHash for each) to JSON
		usersAsBytes, err := json.Marshal(usersResult)
		if err != nil {
			return shim.Error(fmt.Sprintf("Failed to marshal users: %s", err.Error()))
		}

		return shim.Success(usersAsBytes)

	case "QueryUser":
		if len(args) != 1 {
			return shim.Error("Incorrect number of arguments. Expecting 1")
		}
		id, err := primitive.ObjectIDFromHex(args[0])
		if err != nil {
			return shim.Error(fmt.Sprintf("Invalid ID: %s", args[0]))
		}
		user, err := uc.QueryUser(APIstub, id)
		if err != nil {
			return shim.Error(fmt.Sprintf("Failed to query user: %s", err))
		}
		userAsBytes, err := json.Marshal(user)
		if err != nil {
			return shim.Error(fmt.Sprintf("Failed to marshal user data: %s", err))
		}
		return shim.Success(userAsBytes)

	case "GetUserWithHash":
		if len(args) < 1 {
			return shim.Error("Incorrect number of arguments. Expecting at least 1")
		}
		return uc.GetUserWithHash(APIstub, args)

	default:
		return shim.Error("Invalid function name")
	}
}

func main() {
	err := shim.Start(new(UserContract))
	if err != nil {
		fmt.Printf("Error starting User contract: %s", err)
	}
}
