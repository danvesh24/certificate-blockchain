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

var logger = flogging.MustGetLogger("CertificateContractLogger")

// CertificateContract provides functions for interacting with the ledger for Certificates
type CertificateContract struct{}

// Certificate represents the certificate schema
type Certificate struct {
	ID                      primitive.ObjectID      `json:"id"`
	CertificateName         string                  `json:"contactPerson"`
	CertificateDescription  string                  `json:"certificateDescription"`
	CertificateRefNum       int                     `json:"certificateRefNum"`
	Email                   string                  `json:"email"`
	CompanyName             string                  `json:"companyName"`
	CertificateStatus       string                  `json:"certificateStatus"`
	CertificateManufacturer CertificateManufacturer `json:"certificateManufacturer"`
	Phone                   int                     `json:"phone"`
	CertificateValidDate    string                  `json:"certificateValidDate"`
	Slug                    string                  `json:"slug"`
	CertificateImages       []CertificateImages     `json:"certificateImages"`
	CertificateWebLink      string                  `json:"certificateWebLink"`
	CreatedAt               string                  `json:"createdAt"`
	CertificateIssueDate    string                  `json:"certificateIssueDate"`
	QrUrl                   string                  `json:"qrUrl"`
	BlockHash               string                  `json:"blockHash"`
}

// CertificateManufacturer represents the certificate manufacturer information
type CertificateManufacturer struct {
	ID          primitive.ObjectID `json:"_id"`
	CompanyName string             `json:"companyName"`
}

type CertificateImages struct {
	FilePath  string             `json:"filePath"`
	ImageHash string             `json:"imageHash"`
	ID        primitive.ObjectID `json:"_id"`
}

// CertificateQueryResult is used for returning certificate hash details when queried by IDs
type CertificateQueryResult struct {
	ID        string `json:"id"`
	BlockHash string `json:"blockHash"`
}

// Init initializes the chaincode
func (cc *CertificateContract) Init(APIstub shim.ChaincodeStubInterface) peer.Response {
	return shim.Success(nil)
}

// CreateCertificate creates a new certificate on the ledger
func (cc *CertificateContract) CreateCertificate(APIstub shim.ChaincodeStubInterface,
	id primitive.ObjectID,
	certificateName string,
	certificateDescription string,
	certificateRefNum int,
	email string,
	companyName string,
	certificateStatus string,
	certificateManufacturer CertificateManufacturer,
	phone int,
	certificateValidDate string,
	slug string,
	certificateImages []CertificateImages,
	certificateWebLink string,
	createdAt string,
	certificateIssueDate string,
	qrUrl string,
) error {

	// Check if certificate already exists using the certificate'cc ID as key
	certificateAsBytes, err := APIstub.GetState(id.Hex())
	if err != nil {
		return fmt.Errorf("failed to check if certificate exists: %v", err)
	}
	if certificateAsBytes != nil {
		return fmt.Errorf("certificate with ID %cc already exists", id.Hex())
	}

	if certificateValidDate == "" {
		return fmt.Errorf("certificateValidDate must be provided")
	}

	certificate := Certificate{
		ID:                      id,
		CertificateName:         certificateName,
		CertificateDescription:  certificateDescription,
		CertificateRefNum:       certificateRefNum,
		Email:                   email,
		CompanyName:             companyName,
		CertificateStatus:       certificateStatus,
		CertificateManufacturer: certificateManufacturer,
		Phone:                   phone,
		CertificateValidDate:    certificateValidDate,
		Slug:                    slug,
		CertificateImages:       certificateImages,
		CertificateWebLink:      certificateWebLink,
		CreatedAt:               createdAt,
		CertificateIssueDate:    certificateIssueDate,
		QrUrl:                   qrUrl,
	}

	hash, err := computeCertificateHash(certificate)
	if err != nil {
		return fmt.Errorf("failed to compute certificate hash: %v", err)
	}
	certificate.BlockHash = hash

	certificateAsBytes, err = json.Marshal(certificate)
	if err != nil {
		return fmt.Errorf("failed to marshal certificate data: %v", err)
	}

	err = APIstub.PutState(id.Hex(), certificateAsBytes)
	if err != nil {
		return fmt.Errorf("failed to create certificate: %v", err)
	}

	return nil
}

// computeCertificateHash computes a SHA256 hash of the certificate data (excluding BlockHash)
func computeCertificateHash(certificate Certificate) (string, error) {
	// Create a temporary struct excluding the BlockHash field
	certificateWithoutHash := struct {
		ID                      primitive.ObjectID      `json:"id"`
		CertificateName         string                  `json:"contactPerson"`
		CertificateDescription  string                  `json:"certificateDescription"`
		CertificateRefNum       int                     `json:"certificateRefNum"`
		Email                   string                  `json:"email"`
		CompanyName             string                  `json:"companyName"`
		CertificateStatus       string                  `json:"certificateStatus"`
		CertificateManufacturer CertificateManufacturer `json:"certificateManufacturer"`
		Phone                   int                     `json:"phone"`
		CertificateValidDate    string                  `json:"certificateValidDate"`
		Slug                    string                  `json:"slug"`
		CertificateImages       []CertificateImages     `json:"certificateImages"`
		CertificateWebLink      string                  `json:"certificateWebLink"`
		CreatedAt               string                  `json:"createdAt"`
		CertificateIssueDate    string                  `json:"certificateIssueDate"`
		QrUrl                   string                  `json:"qrUrl"`
	}{
		ID:                      certificate.ID,
		CertificateName:         certificate.CertificateName,
		CertificateDescription:  certificate.CertificateDescription,
		CertificateRefNum:       certificate.CertificateRefNum,
		Email:                   certificate.Email,
		CompanyName:             certificate.CompanyName,
		CertificateStatus:       certificate.CertificateStatus,
		CertificateManufacturer: certificate.CertificateManufacturer,
		Phone:                   certificate.Phone,
		CertificateValidDate:    certificate.CertificateValidDate,
		Slug:                    certificate.Slug,
		CertificateImages:       certificate.CertificateImages,
		CertificateWebLink:      certificate.CertificateWebLink,
		CreatedAt:               certificate.CreatedAt,
		CertificateIssueDate:    certificate.CertificateIssueDate,
		QrUrl:                   certificate.QrUrl,
	}

	var buf bytes.Buffer
	encoder := json.NewEncoder(&buf)
	encoder.SetEscapeHTML(false)
	if err := encoder.Encode(certificateWithoutHash); err != nil {
		return "", fmt.Errorf("failed to marshal certificate for hashing: %v", err)
	}

	certificateBytes := buf.Bytes()
	// Remove the trailing newline added by encoder.Encode()
	if len(certificateBytes) > 0 && certificateBytes[len(certificateBytes)-1] == '\n' {
		certificateBytes = certificateBytes[:len(certificateBytes)-1]
	}

	hash := sha256.Sum256(certificateBytes)
	return fmt.Sprintf("%x", hash[:]), nil
}

// QueryCertificate retrieves a certificate from the ledger using its ID
func (cc *CertificateContract) QueryCertificate(APIstub shim.ChaincodeStubInterface, id primitive.ObjectID) (*Certificate, error) {
	certificateAsBytes, err := APIstub.GetState(id.Hex())
	if err != nil {
		return nil, fmt.Errorf("failed to read certificate: %v", err)
	}
	if certificateAsBytes == nil {
		return nil, fmt.Errorf("certificate not found: %cc", id.Hex())
	}

	var certificate Certificate
	err = json.Unmarshal(certificateAsBytes, &certificate)
	if err != nil {
		return nil, fmt.Errorf("failed to unmarshal certificate data: %v", err)
	}

	return &certificate, nil
}

// QueryAllCertificates retrieves all certificates from the ledger
func (cc *CertificateContract) QueryAllCertificates(APIstub shim.ChaincodeStubInterface) ([]Certificate, error) {
	resultsIterator, err := APIstub.GetStateByRange("", "")
	if err != nil {
		return nil, fmt.Errorf("failed to get certificates: %v", err)
	}
	defer resultsIterator.Close()

	var certificates []Certificate

	for resultsIterator.HasNext() {
		queryResponse, err := resultsIterator.Next()
		if err != nil {
			return nil, fmt.Errorf("failed to iterate results: %v", err)
		}

		var certificate Certificate
		err = json.Unmarshal(queryResponse.Value, &certificate)
		if err != nil {
			return nil, fmt.Errorf("failed to unmarshal certificate data: %v", err)
		}

		certificates = append(certificates, certificate)
	}

	return certificates, nil
}

// EditCertificate updates the details of an existing certificate on the ledger
func (cc *CertificateContract) EditCertificate(APIstub shim.ChaincodeStubInterface,
	id primitive.ObjectID,
	certificateName string,
	certificateDescription string,
	certificateRefNum int,
	email string,
	companyName string,
	certificateStatus string,
	certificateManufacturer CertificateManufacturer,
	phone int,
	certificateValidDate string,
	slug string,
	certificateImages []CertificateImages,
	certificateWebLink string,
	createdAt string,
	certificateIssueDate string,
	qrUrl string,
) error {

	certificate, err := cc.QueryCertificate(APIstub, id)
	if err != nil {
		return fmt.Errorf("failed to retrieve certificate: %v", err)
	}

	certificate.CertificateName = certificateName
	certificate.CertificateDescription = certificateDescription
	certificate.CertificateRefNum = certificateRefNum
	certificate.Email = email
	certificate.CompanyName = companyName
	certificate.CertificateStatus = certificateStatus
	certificate.CertificateManufacturer = certificateManufacturer
	certificate.Phone = phone
	certificate.CertificateValidDate = certificateValidDate
	certificate.Slug = slug
	certificate.CertificateImages = certificateImages
	certificate.CertificateWebLink = certificateWebLink
	certificate.CreatedAt = createdAt
	certificate.CertificateIssueDate = certificateIssueDate
	certificate.QrUrl = qrUrl

	newHash, err := computeCertificateHash(*certificate)
	if err != nil {
		return fmt.Errorf("failed to compute hash: %v", err)
	}
	certificate.BlockHash = newHash

	certificateAsBytes, err := json.Marshal(certificate)
	if err != nil {
		return fmt.Errorf("failed to marshal updated certificate data: %v", err)
	}

	err = APIstub.PutState(id.Hex(), certificateAsBytes)
	if err != nil {
		return fmt.Errorf("failed to update certificate data: %v", err)
	}

	return nil
}

// ChangeCertificateStatus updates the status of an existing certificate on the ledger
func (cc *CertificateContract) ChangeCertificateStatus(APIstub shim.ChaincodeStubInterface, id primitive.ObjectID, newStatus string) error {
	// Valid statuses: "pending", "completed", or "cancelled"
	if newStatus != "pending" && newStatus != "completed" && newStatus != "cancelled" {
		return fmt.Errorf("invalid status. Valid values are 'pending', 'completed', or 'cancelled'")
	}

	certificate, err := cc.QueryCertificate(APIstub, id)
	if err != nil {
		return fmt.Errorf("certificate not found: %cc", id.Hex())
	}

	if certificate.CertificateStatus == newStatus {
		return fmt.Errorf("certificate is already in the desired status: %cc", newStatus)
	}

	certificate.CertificateStatus = newStatus

	newHash, err := computeCertificateHash(*certificate)
	if err != nil {
		return fmt.Errorf("failed to compute certificate hash: %v", err)
	}
	certificate.BlockHash = newHash

	certificateAsBytes, err := json.Marshal(certificate)
	if err != nil {
		return fmt.Errorf("failed to marshal updated certificate data: %v", err)
	}

	err = APIstub.PutState(id.Hex(), certificateAsBytes)
	if err != nil {
		return fmt.Errorf("failed to update certificate status: %v", err)
	}

	return nil
}

// GetCertificateWithHash retrieves certificates by their IDs and returns their block hash information
func (cc *CertificateContract) GetCertificateWithHashes(APIstub shim.ChaincodeStubInterface, ids []string) peer.Response {
	var certificateHashes []map[string]interface{}

	for _, idStr := range ids {
		id, err := primitive.ObjectIDFromHex(idStr)
		if err != nil {
			return shim.Error(fmt.Sprintf("Invalid certificate ID: %cc", idStr))
		}
		certificate, err := cc.QueryCertificate(APIstub, id)
		if err != nil {
			// If not found, mark as pending
			certificateHashes = append(certificateHashes, map[string]interface{}{
				"id":        id.Hex(),
				"blockHash": "pending",
			})
			continue
		}

		certificateBytes, err := json.Marshal(certificate)
		if err != nil {
			return shim.Error(fmt.Sprintf("Failed to marshal certificate data for ID %cc: %v", id.Hex(), err))
		}

		hash := sha256.New()
		hash.Write(certificateBytes)
		hashBytes := hash.Sum(nil)
		hashHex := fmt.Sprintf("%x", hashBytes)

		response := map[string]interface{}{
			"CertificateId":   certificate.ID.Hex(),
			"CertificateName": certificate.CertificateName,
			"blockHash":       hashHex,
		}

		certificateHashes = append(certificateHashes, response)
	}

	responseBytes, err := json.Marshal(certificateHashes)
	if err != nil {
		return shim.Error(fmt.Sprintf("Failed to marshal response: %v", err))
	}

	return shim.Success(responseBytes)
}

func (cc *CertificateContract) QueryCertificatesByIDs(APIstub shim.ChaincodeStubInterface, IDs []primitive.ObjectID) ([]CertificateQueryResult, error) {
	var results []CertificateQueryResult

	// Iterate over each provided ID
	for _, ID := range IDs {
		// Retrieve the certificate from the ledger using the provided ID
		certificateAsBytes, err := APIstub.GetState(ID.Hex())
		if err != nil {
			return nil, fmt.Errorf("failed to read certificate with ID %cc: %v", ID.Hex(), err)
		}

		// Check if the certificate exists
		if certificateAsBytes == nil {
			// If not found, add a pending result
			results = append(results, CertificateQueryResult{
				ID:        ID.Hex(),
				BlockHash: "pending",
			})
		} else {
			// Unmarshal the user data
			var certificate Certificate
			err = json.Unmarshal(certificateAsBytes, &certificate)
			if err != nil {
				return nil, fmt.Errorf("failed to unmarshal certificate with ID %cc: %v", ID.Hex(), err)
			}

			// Append the certificate result (ID and BlockHash)
			results = append(results, CertificateQueryResult{
				ID:        certificate.ID.Hex(),
				BlockHash: certificate.BlockHash,
			})
		}
	}

	// Return the list of BatchQueryResults
	return results, nil
}

// Invoke routes function calls to the appropriate handler
func (cc *CertificateContract) Invoke(APIstub shim.ChaincodeStubInterface) peer.Response {
	function, args := APIstub.GetFunctionAndParameters()

	switch function {
	case "CreateCertificate":
		if len(args) != 16 {
			return shim.Error("Incorrect number of arguments. Expecting 16")
		}

		// Parse certificateRefNum
		certificateRefNum, err := strconv.Atoi(args[3])
		if err != nil {
			return shim.Error(fmt.Sprintf("Invalid certificateRefNum: %cc", args[3]))
		}

		// Parse ID
		id, err := primitive.ObjectIDFromHex(args[0])
		if err != nil {
			return shim.Error(fmt.Sprintf("Invalid ID: %cc", args[0]))
		}

		// Parse phone
		phone, err := strconv.Atoi(args[8])
		if err != nil {
			return shim.Error(fmt.Sprintf("Invalid phone: %cc", args[8]))
		}

		// Parse certificateImages
		var certificateImages []CertificateImages
		err = json.Unmarshal([]byte(args[11]), &certificateImages)
		if err != nil {
			return shim.Error(fmt.Sprintf("Invalid certificateImages JSON: %cc", args[11]))
		}

		// Parse CertificateManufacturer
		var certificateManufacturer CertificateManufacturer
		err = json.Unmarshal([]byte(args[7]), &certificateManufacturer)
		if err != nil {
			return shim.Error(fmt.Sprintf("Invalid certificateManufacturer JSON: %cc", args[7]))
		}

		err = cc.CreateCertificate(
			APIstub,
			id,
			args[1],
			args[2],
			certificateRefNum,
			args[4],
			args[5],
			args[6],
			certificateManufacturer,
			phone,
			args[9],
			args[10],
			certificateImages,
			args[12],
			args[13],
			args[14],
			args[15],
		)
		if err != nil {
			return shim.Error(fmt.Sprintf("Failed to create certificate: %cc", err.Error()))
		}

		txID := APIstub.GetTxID()
		txTimestamp, err := APIstub.GetTxTimestamp()
		if err != nil {
			return shim.Error(fmt.Sprintf("Failed to get transaction timestamp: %v", err))
		}
		timestamp := time.Unix(txTimestamp.Seconds, int64(txTimestamp.Nanos)).UTC().Format(time.RFC3339)
		response := map[string]interface{}{
			"message":   "Certificate created successfully",
			"txId":      txID,
			"timeStamp": timestamp,
		}
		responseJSON, err := json.Marshal(response)
		if err != nil {
			return shim.Error(fmt.Sprintf("Failed to marshal response: %v", err))
		}
		return shim.Success(responseJSON)

	case "EditCertificate":
		if len(args) != 16 {
			return shim.Error("Incorrect number of arguments. Expecting 16")
		}

		// Parse certificateRefNum
		certificateRefNum, err := strconv.Atoi(args[3])
		if err != nil {
			return shim.Error(fmt.Sprintf("Invalid certificateRefNum: %cc", args[3]))
		}

		// Parse ID
		id, err := primitive.ObjectIDFromHex(args[0])
		if err != nil {
			return shim.Error(fmt.Sprintf("Invalid ID: %cc", args[0]))
		}

		// Parse phone
		phone, err := strconv.Atoi(args[8])
		if err != nil {
			return shim.Error(fmt.Sprintf("Invalid phone: %cc", args[8]))
		}

		// Parse certificateImages
		var certificateImages []CertificateImages
		err = json.Unmarshal([]byte(args[11]), &certificateImages)
		if err != nil {
			return shim.Error(fmt.Sprintf("Invalid certificateImages JSON: %cc", args[11]))
		}

		// Parse CertificateManufacturer
		var certificateManufacturer CertificateManufacturer
		err = json.Unmarshal([]byte(args[7]), &certificateManufacturer)
		if err != nil {
			return shim.Error(fmt.Sprintf("Invalid certificateManufacturer JSON: %cc", args[7]))
		}

		err = cc.EditCertificate(
			APIstub,
			id,
			args[1],
			args[2],
			certificateRefNum,
			args[4],
			args[5],
			args[6],
			certificateManufacturer,
			phone,
			args[9],
			args[10],
			certificateImages,
			args[12],
			args[13],
			args[14],
			args[15],
		)
		if err != nil {
			return shim.Error(fmt.Sprintf("Failed to edit certificate: %cc", err.Error()))
		}

		txID := APIstub.GetTxID()
		txTimestamp, err := APIstub.GetTxTimestamp()
		if err != nil {
			return shim.Error(fmt.Sprintf("Failed to get transaction timestamp: %v", err))
		}
		timestamp := time.Unix(txTimestamp.Seconds, int64(txTimestamp.Nanos)).UTC().Format(time.RFC3339)
		response := map[string]interface{}{
			"message":   "Certificate edited successfully",
			"txId":      txID,
			"timeStamp": timestamp,
		}
		responseJSON, err := json.Marshal(response)
		if err != nil {
			return shim.Error(fmt.Sprintf("Failed to marshal response: %v", err))
		}
		return shim.Success(responseJSON)

	case "QueryCertificatesByIDs":
		if len(args) < 1 {
			return shim.Error("Incorrect number of arguments. Expecting at least 1")
		}

		var IDs []primitive.ObjectID
		for _, arg := range args {
			ID, err := primitive.ObjectIDFromHex(arg)
			if err != nil {
				return shim.Error(fmt.Sprintf("Invalid ID: %cc", arg))
			}
			IDs = append(IDs, ID)
		}

		// Call QueryCertificatesByIDs function to return id and blockHash for each ID
		certificatesResult, err := cc.QueryCertificatesByIDs(APIstub, IDs)
		if err != nil {
			return shim.Error(fmt.Sprintf("Failed to query certificates: %c", err.Error()))
		}

		// Marshal the result (user ID and blockHash for each) to JSON
		certificatesAsBytes, err := json.Marshal(certificatesResult)
		if err != nil {
			return shim.Error(fmt.Sprintf("Failed to marshal certificates: %c", err.Error()))
		}

		return shim.Success(certificatesAsBytes)

	case "QueryCertificate":
		if len(args) != 1 {
			return shim.Error("Incorrect number of arguments. Expecting 1")
		}
		id, err := primitive.ObjectIDFromHex(args[0])
		if err != nil {
			return shim.Error(fmt.Sprintf("Invalid ID: %cc", args[0]))
		}
		certificate, err := cc.QueryCertificate(APIstub, id)
		if err != nil {
			return shim.Error(fmt.Sprintf("Failed to query certificate: %cc", err.Error()))
		}
		certificateAsBytes, err := json.Marshal(certificate)
		if err != nil {
			return shim.Error(fmt.Sprintf("Failed to marshal certificate: %cc", err.Error()))
		}
		return shim.Success(certificateAsBytes)

	case "QueryAllCertificates":
		certificates, err := cc.QueryAllCertificates(APIstub)
		if err != nil {
			return shim.Error(fmt.Sprintf("Failed to query all certificates: %cc", err.Error()))
		}
		certificatesAsBytes, err := json.Marshal(certificates)
		if err != nil {
			return shim.Error(fmt.Sprintf("Failed to marshal certificates: %cc", err.Error()))
		}
		return shim.Success(certificatesAsBytes)

	case "ChangeCertificateStatus":
		if len(args) != 2 {
			return shim.Error("Incorrect number of arguments. Expecting 2")
		}
		id, err := primitive.ObjectIDFromHex(args[0])
		if err != nil {
			return shim.Error(fmt.Sprintf("Invalid ID: %cc", args[0]))
		}
		err = cc.ChangeCertificateStatus(APIstub, id, args[1])
		if err != nil {
			return shim.Error(fmt.Sprintf("Failed to change certificate status: %cc", err.Error()))
		}
		txID := APIstub.GetTxID()
		txTimestamp, err := APIstub.GetTxTimestamp()
		if err != nil {
			return shim.Error(fmt.Sprintf("Failed to get transaction timestamp: %v", err))
		}
		timestamp := time.Unix(txTimestamp.Seconds, int64(txTimestamp.Nanos)).UTC().Format(time.RFC3339)
		response := map[string]interface{}{
			"message":   "Certificate status changed successfully",
			"txId":      txID,
			"timeStamp": timestamp,
		}
		responseJSON, err := json.Marshal(response)
		if err != nil {
			return shim.Error(fmt.Sprintf("Failed to marshal response: %v", err))
		}
		return shim.Success(responseJSON)

	case "GetCertificateWithHash":
		if len(args) == 0 {
			return shim.Error("Incorrect number of arguments. Expecting at least one certificate ID.")
		}
		return cc.GetCertificateWithHashes(APIstub, args)

	default:
		return shim.Error("Invalid function name")
	}
}

func main() {
	err := shim.Start(new(CertificateContract))
	if err != nil {
		logger.Fatalf("Error starting Certificate contract chaincode: %cc", err)
	}
}
