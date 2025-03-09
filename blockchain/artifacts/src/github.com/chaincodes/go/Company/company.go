package main

import (
	"bytes"
	"crypto/sha256"
	"encoding/json"
	"fmt"
	"strconv"
	"time"

	"github.com/hyperledger/fabric-chaincode-go/shim"
	"github.com/hyperledger/fabric-protos-go/peer"
	"github.com/hyperledger/fabric/common/flogging"
	"go.mongodb.org/mongo-driver/bson/primitive"
)

// SmartContract1 provides functions for interacting with the ledger
type SmartContract1 struct {
}

type Address struct {
	Zip         int    `json:"zip"`
	City        string `json:"city"`
	Country     string `json:"country"`
	AddressLine string `json:"addressLine"`
}

type Company struct {
	ID          primitive.ObjectID `json:"id"`
	Address     Address            `json:"address"`
	FirstName   string             `json:"firstName"`
	LastName    string             `json:"lastName"`
	Email       string             `json:"email"`
	Password    string             `json:"password"`
	PhoneNumber string             `json:"phoneNumber"`
	UserType    string             `json:"userType"`
	CompanyName string             `json:"companyName"`
	Status      string             `json:"status"`
	ProfilePic  string             `json:"profilePic"`
	Remarks     string             `json:"remarks"`
	CreatedAt   string             `json:"createdAt"`
	UpdatedAt   string             `json:"updatedAt"`
	BlockHash   string             `json:"blockHash"`
}

type CompanyQueryResult struct {
	ID          string `json:"id"`
	CompanyName string `json:"companyName"`
	BlockHash   string `json:"blockHash"`
}

var logger = flogging.MustGetLogger("SmartContract1Logger")

// * Init initializes the smart contract
func (s *SmartContract1) Init(APIstub shim.ChaincodeStubInterface) peer.Response {
	return shim.Success(nil)
}

func (s *SmartContract1) ChangeCompanyStatus(APIstub shim.ChaincodeStubInterface, ID primitive.ObjectID, newStatus string) error {
	if newStatus != "enabled" && newStatus != "disabled" {
		return fmt.Errorf("invalid status. Valid values are 'enabled' or 'disabled'")
	}

	companyAsBytes, err := APIstub.GetState(ID.Hex())
	if err != nil {
		return fmt.Errorf("failed to read company: %v", err)
	}
	if companyAsBytes == nil {
		return fmt.Errorf("company not found with ID: %s", ID)
	}

	var company Company
	err = json.Unmarshal(companyAsBytes, &company)
	if err != nil {
		return fmt.Errorf("failed to unmarshal company data: %v", err)
	}

	if company.Status == newStatus {
		return fmt.Errorf("company already in the desired status: %s", newStatus)
	}

	company.Status = newStatus

	updatedCompanyAsBytes, err := json.Marshal(company)
	if err != nil {
		return fmt.Errorf("failed to marshal updated company data: %v", err)
	}

	err = APIstub.PutState(ID.Hex(), updatedCompanyAsBytes)
	if err != nil {
		return fmt.Errorf("failed to update company status: %v", err)
	}

	return nil
}

// * CreateCompany creates a new company on the ledger
func (s *SmartContract1) CreateCompany(APIstub shim.ChaincodeStubInterface,
	id primitive.ObjectID,
	companyName string,
	zip int,
	city string,
	country string,
	addressLine string,
	status string,
	remarks string,
	profilePic string,
	firstName string,
	lastName string,
	email string,
	password string,
	phoneNumber string,
	userType string,
	createdAt string,
	updatedAt string) error {

	companyAsBytes, err := APIstub.GetState(id.Hex())
	if err != nil {
		return fmt.Errorf("failed to check if company exists: %v", err)
	}

	var company Company
	if companyAsBytes != nil {
		err = json.Unmarshal(companyAsBytes, &company)
		if err != nil {
			return fmt.Errorf("failed to unmarshal existing company data: %v", err)
		}

		company.Status = status
		company.Remarks = remarks
		company.UpdatedAt = updatedAt
	} else {
		company = Company{
			ID: id,
			Address: Address{
				Zip:         zip,
				City:        city,
				Country:     country,
				AddressLine: addressLine,
			},
			FirstName:   firstName,
			LastName:    lastName,
			Email:       email,
			Password:    password,
			PhoneNumber: phoneNumber,
			UserType:    userType,
			CompanyName: companyName,
			Status:      status,
			ProfilePic:  profilePic,
			Remarks:     remarks,
			CreatedAt:   createdAt,
			UpdatedAt:   updatedAt,
		}
	}

	// Compute the hash for the company
	hashHex, err := computeHash(company)
	if err != nil {
		return fmt.Errorf("failed to compute company hash: %v", err)
	}

	company.BlockHash = hashHex

	companyAsBytes, err = json.Marshal(company)
	if err != nil {
		return fmt.Errorf("failed to marshal company with hash: %v", err)
	}

	err = APIstub.PutState(id.Hex(), companyAsBytes)
	if err != nil {
		return fmt.Errorf("failed to create or update company: %v", err)
	}

	err = APIstub.PutState(companyName, companyAsBytes)
	if err != nil {
		return fmt.Errorf("failed to save company name index: %v", err)
	}

	return nil
}

func computeHash(company Company) (string, error) {
	// Create a temporary struct excluding the BlockHash field
	companyWithoutBlockHash := struct {
		ID          string   `json:"id"`
		Address     Address  `json:"address"`
		FirstName   string   `json:"firstName"`
		LastName    string   `json:"lastName"`
		Email       string   `json:"email"`
		Password    string   `json:"password"`
		PhoneNumber string   `json:"phoneNumber"`
		UserType    string   `json:"userType"`
		CompanyName string   `json:"companyName"`
		Status      string   `json:"status"`
		ProfilePic  string   `json:"profilePic"`
		Remarks     string   `json:"remarks"`
		CreatedAt   string   `json:"createdAt"`
	}{
		ID:          company.ID.Hex(),
		Address:     company.Address,
		FirstName:   company.FirstName,
		LastName:    company.LastName,
		Email:       company.Email,
		Password:    company.Password,
		PhoneNumber: company.PhoneNumber,
		UserType:    company.UserType,
		CompanyName: company.CompanyName,
		Status:      company.Status,
		ProfilePic:  company.ProfilePic,
		Remarks:     company.Remarks,
		CreatedAt:   company.CreatedAt,
	}

	var buf bytes.Buffer
	encoder := json.NewEncoder(&buf)
	encoder.SetEscapeHTML(false)
	if err := encoder.Encode(companyWithoutBlockHash); err != nil {
		return "", fmt.Errorf("failed to marshal product item for hashing: %v", err)
	}

	// Remove the trailing newline added by json.Encoder.Encode()
	companyBytes := buf.Bytes()
	if len(companyBytes) > 0 && companyBytes[len(companyBytes)-1] == '\n' {
		companyBytes = companyBytes[:len(companyBytes)-1]
	}

	// Compute the SHA256 hash
	hash := sha256.Sum256(companyBytes)
	return fmt.Sprintf("%x", hash[:]), nil
}

func (s *SmartContract1) QueryCompaniesByIDs(APIstub shim.ChaincodeStubInterface, IDs []primitive.ObjectID) ([]CompanyQueryResult, error) {
	var results []CompanyQueryResult

	// Iterate over each provided ID
	for _, ID := range IDs {
		// Retrieve the batch from the ledger using the provided ID
		companyAsBytes, err := APIstub.GetState(ID.Hex())
		if err != nil {
			return nil, fmt.Errorf("failed to read batch with ID %s: %v", ID.Hex(), err)
		}

		// Check if the batch exists
		if companyAsBytes == nil {
			// If not found, add a pending result
			results = append(results, CompanyQueryResult{
				ID:          ID.Hex(),
				CompanyName: "Unknown",
				BlockHash:   "pending",
			})
		} else {
			// Unmarshal the batch data
			var company Company
			err = json.Unmarshal(companyAsBytes, &company)
			if err != nil {
				return nil, fmt.Errorf("failed to unmarshal batch with ID %s: %v", ID.Hex(), err)
			}

			// Append the batch result (ID and BlockHash)
			results = append(results, CompanyQueryResult{
				ID:          company.ID.Hex(),
				CompanyName: company.CompanyName,
				BlockHash:   company.BlockHash,
			})
		}
	}

	// Return the list of CompanyQueryResults
	return results, nil
}

// * QueryCompany retrieves a company from the world state
func (s *SmartContract1) QueryCompany(APIstub shim.ChaincodeStubInterface, companyID primitive.ObjectID) (*Company, error) {
	companyAsBytes, err := APIstub.GetState(companyID.Hex())
	if err != nil {
		return nil, fmt.Errorf("failed to read company: %v", err)
	}
	if companyAsBytes == nil {
		return nil, fmt.Errorf("company not found with ID: %s", companyID)
	}

	var company Company
	err = json.Unmarshal(companyAsBytes, &company)
	if err != nil {
		return nil, fmt.Errorf("failed to unmarshal company data: %v", err)
	}

	return &company, nil
}

// * GetCompanyWithHash retrieves a company and generates a SHA-256 hash of the data
func (s *SmartContract1) GetCompaniesWithHashes(APIstub shim.ChaincodeStubInterface, ids []string) peer.Response {
	var companyHashes []map[string]interface{}

	for _, id := range ids {
		companyID, err := primitive.ObjectIDFromHex(id)
		if err != nil {
			return shim.Error(fmt.Sprintf("Invalid company ID format: %s. Error: %v", id, err))
		}

		company, err := s.QueryCompany(APIstub, companyID)
		if err != nil {
			// If company not found, mark as pending
			companyHash := map[string]interface{}{
				"id":          companyID.Hex(),
				"companyName": "Pending",
				"blockHash":   "Pending",
			}
			companyHashes = append(companyHashes, companyHash)
			continue
		}

		companyBytes, err := json.Marshal(company)
		if err != nil {
			return shim.Error(fmt.Sprintf("Failed to marshal Company data for %s: %v", companyID.Hex(), err))
		}

		hash := sha256.New()
		hash.Write(companyBytes)
		hashBytes := hash.Sum(nil)
		hashHex := fmt.Sprintf("%x", hashBytes)

		companyHash := map[string]interface{}{
			"id":          company.ID.Hex(),
			"companyName": company.CompanyName,
			"blockHash":   hashHex,
		}

		companyHashes = append(companyHashes, companyHash)
	}

	responseBytes, err := json.Marshal(companyHashes)
	if err != nil {
		return shim.Error(fmt.Sprintf("Failed to marshal response: %v", err))
	}

	return shim.Success(responseBytes)
}

// * QueryAllCompanies retrieves all companies from the world state
func (s *SmartContract1) QueryAllCompanies(APIstub shim.ChaincodeStubInterface) ([]Company, error) {
	resultsIterator, err := APIstub.GetStateByRange("", "")
	if err != nil {
		return nil, fmt.Errorf("failed to get company data: %v", err)
	}
	defer resultsIterator.Close()

	var companies []Company

	for resultsIterator.HasNext() {
		queryResponse, err := resultsIterator.Next()
		if err != nil {
			return nil, fmt.Errorf("failed to iterate results: %v", err)
		}

		var company Company
		err = json.Unmarshal(queryResponse.Value, &company)
		if err != nil {
			return nil, fmt.Errorf("failed to unmarshal company data: %v", err)
		}

		companies = append(companies, company)
	}

	return companies, nil
}

// * DeleteCompany deletes a company from the world state
func (s *SmartContract1) DeleteCompany(APIstub shim.ChaincodeStubInterface, ID primitive.ObjectID) error {
	company, err := s.QueryCompany(APIstub, ID)
	if err != nil {
		return fmt.Errorf("failed to find company: %v", err)
	}
	if company == nil {
		return fmt.Errorf("company not found: %s", ID)
	}

	err = APIstub.DelState(ID.Hex())
	if err != nil {
		return fmt.Errorf("failed to delete company: %v", err)
	}

	return nil
}

func (s *SmartContract1) EditCompany(APIstub shim.ChaincodeStubInterface,
	ID primitive.ObjectID,
	companyName string,
	zip int,
	city string,
	country string,
	addressLine string,
	firstName string,
	lastName string,
	email string,
	phoneNumber string,
	userType string,
	updatedAt string) error {

	companyAsBytes, err := APIstub.GetState(ID.Hex())
	if err != nil {
		return fmt.Errorf("failed to read company: %v", err)
	}
	if companyAsBytes == nil {
		return fmt.Errorf("company not found: %s", ID)
	}

	var company Company
	err = json.Unmarshal(companyAsBytes, &company)
	if err != nil {
		return fmt.Errorf("failed to unmarshal company data: %v", err)
	}

	company.CompanyName = companyName
	company.Address.Zip = zip
	company.Address.City = city
	company.Address.Country = country
	company.Address.AddressLine = addressLine
	company.FirstName = firstName
	company.LastName = lastName
	company.Email = email
	company.PhoneNumber = phoneNumber
	company.UserType = userType
	company.UpdatedAt = updatedAt

	newHash, err := computeHash(company)
	if err != nil {
		return fmt.Errorf("failed to compute hash for updated company: %v", err)
	}

	company.BlockHash = newHash

	updatedCompanyAsBytes, err := json.Marshal(company)
	if err != nil {
		return fmt.Errorf("failed to marshal updated company data: %v", err)
	}

	err = APIstub.PutState(ID.Hex(), updatedCompanyAsBytes)
	if err != nil {
		return fmt.Errorf("failed to update company: %v", err)
	}

	return nil
}

func (s *SmartContract1) EditCompanyProfile(
	APIstub shim.ChaincodeStubInterface,
	ID primitive.ObjectID,
	profilePic string,
	firstName string,
	lastName string,
	email string,
	phoneNumber string,
	companyName string,
	zip int,
	city string,
	country string,
	addressLine string,
	updatedAt string) error {

	companyAsBytes, err := APIstub.GetState(ID.Hex())
	if err != nil {
		return fmt.Errorf("failed to read company: %v", err)
	}
	if companyAsBytes == nil {
		return fmt.Errorf("company not found: %s", ID)
	}

	var company Company
	err = json.Unmarshal(companyAsBytes, &company)
	if err != nil {
		return fmt.Errorf("failed to unmarshal company data: %v", err)
	}

	if profilePic != "" {
		company.ProfilePic = profilePic
	}
	if firstName != "" {
		company.FirstName = firstName
	}
	if lastName != "" {
		company.LastName = lastName
	}
	if email != "" {
		company.Email = email
	}
	if phoneNumber != "" {
		company.PhoneNumber = phoneNumber
	}
	if companyName != "" {
		company.CompanyName = companyName
	}
	if zip != 0 {
		company.Address.Zip = zip
	}
	if city != "" {
		company.Address.City = city
	}
	if country != "" {
		company.Address.Country = country
	}
	if addressLine != "" {
		company.Address.AddressLine = addressLine
	}
	if updatedAt != "" {
		company.UpdatedAt = updatedAt
	}

	newHash, err := computeHash(company)
	if err != nil {
		return fmt.Errorf("failed to compute hash for updated company: %v", err)
	}

	company.BlockHash = newHash

	updatedCompanyAsBytes, err := json.Marshal(company)
	if err != nil {
		return fmt.Errorf("failed to marshal updated company data: %v", err)
	}

	// Store the updated company back into the ledger
	err = APIstub.PutState(ID.Hex(), updatedCompanyAsBytes)
	if err != nil {
		return fmt.Errorf("failed to update company: %v", err)
	}

	return nil
}

func (s *SmartContract1) EditCompanyPassword(
	APIstub shim.ChaincodeStubInterface,
	ID primitive.ObjectID,
	newPassword string,
	updatedAt string) error {

	// Check if the new password is empty
	if newPassword == "" {
		return fmt.Errorf("password cannot be empty")
	}

	// Retrieve the company data from the ledger
	companyAsBytes, err := APIstub.GetState(ID.Hex())
	if err != nil {
		return fmt.Errorf("failed to read company: %v", err)
	}
	if companyAsBytes == nil {
		return fmt.Errorf("company not found: %s", ID)
	}

	// Unmarshal the retrieved company data
	var company Company
	err = json.Unmarshal(companyAsBytes, &company)
	if err != nil {
		return fmt.Errorf("failed to unmarshal company data: %v", err)
	}

	// Update the password field
	company.Password = newPassword
	company.UpdatedAt = updatedAt

	newHash, err := computeHash(company)
	if err != nil {
		return fmt.Errorf("failed to compute hash for updated company: %v", err)
	}

	// Update the BlockHash with the new hash
	company.BlockHash = newHash

	// Marshal the updated company data
	updatedCompanyAsBytes, err := json.Marshal(company)
	if err != nil {
		return fmt.Errorf("failed to marshal updated company data: %v", err)
	}

	// Save the updated company data back to the ledger
	err = APIstub.PutState(ID.Hex(), updatedCompanyAsBytes)
	if err != nil {
		return fmt.Errorf("failed to update company: %v", err)
	}

	return nil
}

func (s *SmartContract1) GetHistoryForAllAssetsOfCompany(stub shim.ChaincodeStubInterface) peer.Response {
	companies, err := s.QueryAllCompanies(stub)
	if err != nil {
		return shim.Error(fmt.Sprintf("Failed to query companies: %v", err))
	}

	var buffer bytes.Buffer
	buffer.WriteString("[")

	bArrayMemberAlreadyWritten := false
	for _, company := range companies {
		id := company.ID
		companyName := company.CompanyName

		resultsIterator, err := stub.GetHistoryForKey(id.Hex())
		if err != nil {
			return shim.Error(fmt.Sprintf("Failed to get history for company %s: %v", id, err))
		}
		defer resultsIterator.Close()

		for resultsIterator.HasNext() {
			response, err := resultsIterator.Next()
			if err != nil {
				return shim.Error(fmt.Sprintf("Failed to get next history record: %v", err))
			}

			// Add a comma before array members, suppress it for the first array member
			if bArrayMemberAlreadyWritten == true {
				buffer.WriteString(",")
			}

			buffer.WriteString("{\"CompanyName\":")
			buffer.WriteString("\"")
			buffer.WriteString(companyName)
			buffer.WriteString("\"")

			buffer.WriteString(", \"TxId\":")
			buffer.WriteString("\"")
			buffer.WriteString(response.TxId)
			buffer.WriteString("\"")

			buffer.WriteString(", \"Value\":")
			if response.IsDelete {
				buffer.WriteString("null")
			} else {
				buffer.WriteString(string(response.Value))
			}

			buffer.WriteString(", \"Timestamp\":")
			buffer.WriteString("\"")
			buffer.WriteString(time.Unix(response.Timestamp.Seconds, int64(response.Timestamp.Nanos)).String())
			buffer.WriteString("\"")

			buffer.WriteString(", \"IsDelete\":")
			buffer.WriteString("\"")
			buffer.WriteString(strconv.FormatBool(response.IsDelete))
			buffer.WriteString("\"")

			buffer.WriteString("}")
			bArrayMemberAlreadyWritten = true
		}
	}

	buffer.WriteString("]")

	fmt.Printf("- GetHistoryForAllAssetsOfCompany returning:\n%s\n", buffer.String())
	return shim.Success(buffer.Bytes())
}

// * Invoke : Method for invoking smart contract functions
func (s *SmartContract1) Invoke(APIstub shim.ChaincodeStubInterface) peer.Response {
	function, args := APIstub.GetFunctionAndParameters()

	logger.Infof("Function name is: %s", function)
	logger.Infof("Args length is: %d", len(args))
	switch function {
	case "CreateCompany":
		if len(args) != 17 {
			return shim.Error("Incorrect number of arguments. Expecting 17")
		}
		ID, err := primitive.ObjectIDFromHex(args[0])
		if err != nil {
			return shim.Error(fmt.Sprintf("Invalid ID: %s", args[0]))
		}

		zip, err := strconv.Atoi(args[2])
		if err != nil {
			return shim.Error("Failed to convert zip to int: " + err.Error())
		}

		

		err = s.CreateCompany(APIstub, ID, args[1], zip, args[3], args[4], args[5], args[6], args[7], args[8], args[9], args[10], args[11], args[12], args[13], args[14], args[15], args[16])
		if err != nil {
			return shim.Error(fmt.Sprintf("Failed to create company: %v", err))
		}

		txID := APIstub.GetTxID()

		txTimestamp, err := APIstub.GetTxTimestamp()
		if err != nil {
			return shim.Error(fmt.Sprintf("Failed to get transaction timestamp: %v", err))
		}

		// Convert timestamp to readable format
		timestamp := time.Unix(txTimestamp.Seconds, int64(txTimestamp.Nanos)).UTC().Format(time.RFC3339)

		response := map[string]interface{}{
			"message":   "Company created successfully",
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

	case "QueryCompany":
		if len(args) != 1 {
			return shim.Error("Incorrect number of arguments. Expecting 1")
		}
		ID, err := primitive.ObjectIDFromHex(args[0])
		if err != nil {
			return shim.Error(fmt.Sprintf("Invalid ID: %s", args[0]))
		}
		company, err := s.QueryCompany(APIstub, ID)
		if err != nil {
			return shim.Error(err.Error())
		}

		companyAsBytes, _ := json.Marshal(company)
		return shim.Success(companyAsBytes)

	case "QueryCompaniesByIDs":
		if len(args) < 1 {
			return shim.Error("Incorrect number of arguments. Expecting at least 1 (array of IDs in JSON format)")
		}

		// Unmarshal the array of IDs
		var ids []primitive.ObjectID
		for _, arg := range args {
			ID, err := primitive.ObjectIDFromHex(arg)
			if err != nil {
				return shim.Error(fmt.Sprintf("Invalid ID: %s", arg))
			}
			ids = append(ids, ID)
		}

		// Query companies by their IDs
		results, err := s.QueryCompaniesByIDs(APIstub, ids)
		if err != nil {
			return shim.Error(fmt.Sprintf("Failed to query companies by IDs: %v", err))
		}

		// Marshal the results back to JSON
		resultsAsBytes, err := json.Marshal(results)
		if err != nil {
			return shim.Error(fmt.Sprintf("Failed to marshal query results: %v", err))
		}

		return shim.Success(resultsAsBytes)

	case "QueryAllCompanies":
		if len(args) != 0 {
			return shim.Error("Incorrect number of arguments. Expecting 0")
		}

		companies, err := s.QueryAllCompanies(APIstub)
		if err != nil {
			return shim.Error(err.Error())
		}

		companiesAsBytes, _ := json.Marshal(companies)
		return shim.Success(companiesAsBytes)

	case "DeleteCompany":
		if len(args) != 1 {
			return shim.Error("Incorrect number of arguments. Expecting 1")
		}
		ID, err := primitive.ObjectIDFromHex(args[0])
		if err != nil {
			return shim.Error(fmt.Sprintf("Invalid ID: %s", ID))
		}
		err = s.DeleteCompany(APIstub, ID)

		if err != nil {
			return shim.Error(err.Error())
		}

		txID := APIstub.GetTxID()

		txTimestamp, err := APIstub.GetTxTimestamp()
		if err != nil {
			return shim.Error(fmt.Sprintf("Failed to get transaction timestamp: %v", err))
		}

		// Convert timestamp to readable format
		timestamp := time.Unix(txTimestamp.Seconds, int64(txTimestamp.Nanos)).UTC().Format(time.RFC3339)

		response := map[string]interface{}{
			"message":   "Company deleted successfully",
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

	case "ChangeCompanyStatus":
		if len(args) != 2 {
			return shim.Error("Incorrect number of arguments. Expecting 2")
		}
		ID, err := primitive.ObjectIDFromHex(args[0])
		if err != nil {
			return shim.Error(fmt.Sprintf("Invalid ID: %s", args[0]))
		}
		err = s.ChangeCompanyStatus(APIstub, ID, args[1])
		if err != nil {
			return shim.Error(err.Error())
		}
		return shim.Success([]byte("Company status changed successfully"))

	case "GetCompanyWithHash":
		if len(args) == 0 {
			return shim.Error("Incorrect number of arguments. Expecting at least one argument: IDs of companies.")
		}

		return s.GetCompaniesWithHashes(APIstub, args)

	case "EditCompany":
		if len(args) < 2 || len(args) > 13 {
			return shim.Error("Incorrect number of arguments. Expecting 2 to 12.")
		}
		ID, err := primitive.ObjectIDFromHex(args[0])
		if err != nil {
			return shim.Error(fmt.Sprintf("Invalid ID: %s", args[0]))
		}

		companyName := args[1]

		var zip int
		if len(args) > 2 && args[2] != "" {
			z, err := strconv.Atoi(args[2])
			if err != nil {
				return shim.Error("Failed to convert zip to int: " + err.Error())
			}
			zip = z
		}

		city, country, addressLine, firstName, lastName, email, phoneNumber, userType, updatedAt := "", "", "", "", "", "", "", "", ""
		

		if len(args) > 3 && args[3] != "" {
			city = args[3]
		}
		if len(args) > 4 && args[4] != "" {
			country = args[4]
		}
		if len(args) > 5 && args[5] != "" {
			addressLine = args[5]
		}
		if len(args) > 6 && args[6] != "" {
			firstName = args[6]
		}
		if len(args) > 7 && args[7] != "" {
			lastName = args[7]
		}
		if len(args) > 8 && args[8] != "" {
			email = args[8]
		}
		if len(args) > 9 && args[9] != "" {
			phoneNumber = args[9]
		}
		if len(args) > 10 && args[10] != "" {
			userType = args[10]
		}
		if len(args) > 11 && args[11] != "" {
			updatedAt = args[11]
		}

		err = s.EditCompany(APIstub, ID, companyName, zip, city, country, addressLine, firstName, lastName, email, phoneNumber, userType, updatedAt)
		if err != nil {
			return shim.Error(err.Error())
		}

		txID := APIstub.GetTxID()

		txTimestamp, err := APIstub.GetTxTimestamp()
		if err != nil {
			return shim.Error(fmt.Sprintf("Failed to get transaction timestamp: %v", err))
		}

		// Convert timestamp to readable format
		timestamp := time.Unix(txTimestamp.Seconds, int64(txTimestamp.Nanos)).UTC().Format(time.RFC3339)

		response := map[string]interface{}{
			"message":   "Company edited successfully",
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

	case "EditCompanyProfile":
		if len(args) < 2 || len(args) > 12 {
			return shim.Error("Incorrect number of arguments. Expecting 2 to 11.")
		}
		ID, err := primitive.ObjectIDFromHex(args[0])
		if err != nil {
			return shim.Error(fmt.Sprintf("Invalid ID: %s", args[0]))
		}

		var profilePic, updatedAt, firstName, lastName, email, phoneNumber, companyName, city, country, addressLine string
		var zip int

		if len(args) > 1 && args[1] != "" {
			profilePic = args[1]
		}
		if len(args) > 2 && args[2] != "" {
			firstName = args[2]
		}
		if len(args) > 3 && args[3] != "" {
			lastName = args[3]
		}
		if len(args) > 4 && args[4] != "" {
			email = args[4]
		}
		if len(args) > 5 && args[5] != "" {
			phoneNumber = args[5]
		}
		if len(args) > 6 && args[6] != "" {
			companyName = args[6]
		}
		if len(args) > 7 && args[7] != "" {
			z, err := strconv.Atoi(args[7])
			if err != nil {
				return shim.Error("Failed to convert zip to int: " + err.Error())
			}
			zip = z
		}
		if len(args) > 8 && args[8] != "" {
			city = args[8]
		}
		if len(args) > 9 && args[9] != "" {
			country = args[9]
		}
		if len(args) > 10 && args[10] != "" {
			addressLine = args[10]
		}
		if len(args) > 11 && args[11] != "" {
			updatedAt = args[11]
		}

		err = s.EditCompanyProfile(APIstub, ID, profilePic, firstName, lastName, email, phoneNumber, companyName, zip, city, country, addressLine, updatedAt)
		if err != nil {
			return shim.Error(err.Error())
		}

		txID := APIstub.GetTxID()

		txTimestamp, err := APIstub.GetTxTimestamp()
		if err != nil {
			return shim.Error(fmt.Sprintf("Failed to get transaction timestamp: %v", err))
		}

		// Convert timestamp to readable format
		timestamp := time.Unix(txTimestamp.Seconds, int64(txTimestamp.Nanos)).UTC().Format(time.RFC3339)

		response := map[string]interface{}{
			"message":   "Company profile edited successfully",
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

	case "EditCompanyPassword":
		if len(args) != 3 {
			return shim.Error("Incorrect number of arguments. Expecting 2.")
		}
		ID, err := primitive.ObjectIDFromHex(args[0])
		if err != nil {
			return shim.Error(fmt.Sprintf("Invalid ID: %s", args[0]))
		}

		newPassword := args[1]
		updatedAt := args[2]
		err = s.EditCompanyPassword(APIstub, ID, newPassword, updatedAt)
		if err != nil {
			return shim.Error(err.Error())
		}

		txID := APIstub.GetTxID()

		txTimestamp, err := APIstub.GetTxTimestamp()
		if err != nil {
			return shim.Error(fmt.Sprintf("Failed to get transaction timestamp: %v", err))
		}

		// Convert timestamp to readable format
		timestamp := time.Unix(txTimestamp.Seconds, int64(txTimestamp.Nanos)).UTC().Format(time.RFC3339)

		response := map[string]interface{}{
			"message":   "Company password edited successfully",
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

	case "GetHistoryForAllAssetsOfCompany":
		return s.GetHistoryForAllAssetsOfCompany(APIstub)
	default:
		return shim.Error("Invalid function name. Must be one of 'CreateCompany', 'QueryCompany', 'ChangeCompanyStatus', 'EditCompany', 'EditCompanyPassword', 'QueryAllCompanies', or 'DeleteCompany'")
	}
}

func main() {
	err := shim.Start(new(SmartContract1))
	if err != nil {
		logger.Errorf("Error starting SmartContract1 chaincode: %s", err)
	}
}
