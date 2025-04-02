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

var logger = flogging.MustGetLogger("CertificateContractLogger")

type HealthCardContract struct{}

type HealthCard struct {
	ID                     primitive.ObjectID     `json:"id"`
	Name                   string                 `json:"name"`
	Email                  string                 `json:"email"`
	Address                Address                `json:"address"`
	PhoneNumber            string                 `json:"phoneNumber"`
	IDCode                 string                 `json:"idCode"`
	DateOfBirth            string                 `json:"dob"`
	Gender                 string                 `json:"gender"`
	BloodGroup             string                 `json:"bloodGroup"`
	Allergy                string                 `json:"allergy"`
	LastBloodPressure      string                 `json:"lastBloodPressure"`
	BloodSugar             string                 `json:"bloodSugar"`
	PastSurgery            string                 `json:"pastSurgery"`
	LastHospitalization    string                 `json:"lastHospitalization"`
	DiseaseCondition       string                 `json:"diseaseCondition"`
	RegularMedication      string                 `json:"regularMedication"`
	HealthMessage          string                 `json:"healthMessage"`
	EmergencyContactNumber string                 `json:"emergencyContactNumber"`
	HealthCardImages       []HealthCardImages     `json:"healthCardImages"`
	Slug                   string                 `json:"slug"`
	QrUrl                  string                 `json:"qrUrl"`
	CreatedAt              string                 `json:"createdAt"`
	HealthCardManufacturer HealthCardManufacturer `json:"healthCardManufacturer"`
	BlockHash              string                 `json:"blockHash"`
}

type Address struct {
	City        string `json:"city"`
	Country     string `json:"country"`
	AddressLine string `json:"addressLine"`
}

type HealthCardImages struct {
	FilePath  string             `json:"filePath"`
	ImageHash string             `json:"imageHash"`
	ID        primitive.ObjectID `json:"_id"`
}

type HealthCardQueryResult struct {
	ID        string `json:"id"`
	BlockHash string `json:"blockHash"`
}

type HealthCardManufacturer struct {
	ID          primitive.ObjectID `json:"_id"`
	CompanyName string             `json:"companyName"`
}

// Init initializes the chaincode
func (h *HealthCardContract) Init(APIstub shim.ChaincodeStubInterface) peer.Response {
	logger.Info("Initializing HealthCardContract")
	return shim.Success(nil)
}

func (h *HealthCardContract) CreateHealthCard(
	APIstub shim.ChaincodeStubInterface,
	id primitive.ObjectID,
	name string,
	email string,
	address Address,
	phoneNumber string,
	idCode string,
	dob string,
	gender string,
	bloodGroup string,
	allergy string,
	lastBloodPressure string,
	bloodSugar string,
	pastSurgery string,
	lastHospitalization string,
	diseaseCondition string,
	regularMedication string,
	healthMessage string,
	emergencyContactNumber string,
	healthCardImages []HealthCardImages,
	slug string,
	qrUrl string,
	createdAt string,
	healthCardManufacturer HealthCardManufacturer,
) error {

	// Check if health card already exists using the health card's ID as key
	healthCardAsBytes, err := APIstub.GetState(id.Hex())
	if err != nil {
		return fmt.Errorf("failed to check if health card exists: %v", err)
	}
	if healthCardAsBytes != nil {
		return fmt.Errorf("health card with ID %s already exists", id.Hex())
	}

	healthCard := HealthCard{
		ID:                     id,
		Name:                   name,
		Email:                  email,
		Address:                address,
		PhoneNumber:            phoneNumber,
		IDCode:                 idCode,
		DateOfBirth:            dob,
		Gender:                 gender,
		BloodGroup:             bloodGroup,
		Allergy:                allergy,
		LastBloodPressure:      lastBloodPressure,
		BloodSugar:             bloodSugar,
		PastSurgery:            pastSurgery,
		LastHospitalization:    lastHospitalization,
		DiseaseCondition:       diseaseCondition,
		RegularMedication:      regularMedication,
		HealthMessage:          healthMessage,
		EmergencyContactNumber: emergencyContactNumber,
		HealthCardImages:       healthCardImages,
		Slug:                   slug,
		QrUrl:                  qrUrl,
		CreatedAt:              createdAt,
		HealthCardManufacturer: healthCardManufacturer,
	}

	hash, err := computeHealthCardHash(healthCard)
	if err != nil {
		return fmt.Errorf("failed to compute health card hash: %v", err)
	}
	healthCard.BlockHash = hash

	healthCardAsBytes, err = json.Marshal(healthCard)
	if err != nil {
		return fmt.Errorf("failed to marshal health card data: %v", err)
	}

	err = APIstub.PutState(id.Hex(), healthCardAsBytes)
	if err != nil {
		return fmt.Errorf("failed to create health card: %v", err)
	}

	return nil
}

// computeHealthCardHash computes a SHA256 hash of the health card data (excluding BlockHash)
func computeHealthCardHash(healthCard HealthCard) (string, error) {
	// Create a temporary struct excluding the BlockHash field
	healthCardWithoutHash := struct {
		ID                     primitive.ObjectID     `json:"id"`
		Name                   string                 `json:"name"`
		Email                  string                 `json:"email"`
		Address                Address                `json:"address"`
		PhoneNumber            string                 `json:"phoneNumber"`
		IDCode                 string                 `json:"idCode"`
		DateOfBirth            string                 `json:"dob"`
		Gender                 string                 `json:"gender"`
		BloodGroup             string                 `json:"bloodGroup"`
		Allergy                string                 `json:"allergy"`
		LastBloodPressure      string                 `json:"lastBloodPressure"`
		BloodSugar             string                 `json:"bloodSugar"`
		PastSurgery            string                 `json:"pastSurgery"`
		LastHospitalization    string                 `json:"lastHospitalization"`
		DiseaseCondition       string                 `json:"diseaseCondition"`
		RegularMedication      string                 `json:"regularMedication"`
		HealthMessage          string                 `json:"healthMessage"`
		EmergencyContactNumber string                 `json:"emergencyContactNumber"`
		HealthCardImages       []HealthCardImages     `json:"healthCardImages"`
		Slug                   string                 `json:"slug"`
		QrUrl                  string                 `json:"qrUrl"`
		CreatedAt              string                 `json:"createdAt"`
		HealthCardManufacturer HealthCardManufacturer `json:"healthCardManufacturer"`
	}{
		ID:                     healthCard.ID,
		Name:                   healthCard.Name,
		Email:                  healthCard.Email,
		Address:                healthCard.Address,
		PhoneNumber:            healthCard.PhoneNumber,
		IDCode:                 healthCard.IDCode,
		DateOfBirth:            healthCard.DateOfBirth,
		Gender:                 healthCard.Gender,
		BloodGroup:             healthCard.BloodGroup,
		Allergy:                healthCard.Allergy,
		LastBloodPressure:      healthCard.LastBloodPressure,
		BloodSugar:             healthCard.BloodSugar,
		PastSurgery:            healthCard.PastSurgery,
		LastHospitalization:    healthCard.LastHospitalization,
		DiseaseCondition:       healthCard.DiseaseCondition,
		RegularMedication:      healthCard.RegularMedication,
		HealthMessage:          healthCard.HealthMessage,
		EmergencyContactNumber: healthCard.EmergencyContactNumber,
		HealthCardImages:       healthCard.HealthCardImages,
		Slug:                   healthCard.Slug,
		QrUrl:                  healthCard.QrUrl,
		CreatedAt:              healthCard.CreatedAt,
		HealthCardManufacturer: healthCard.HealthCardManufacturer,
	}

	var buf bytes.Buffer
	encoder := json.NewEncoder(&buf)
	encoder.SetEscapeHTML(false)
	if err := encoder.Encode(healthCardWithoutHash); err != nil {
		return "", fmt.Errorf("failed to marshal health card for hashing: %v", err)
	}

	healthCardBytes := buf.Bytes()
	// Remove the trailing newline added by encoder.Encode()
	if len(healthCardBytes) > 0 && healthCardBytes[len(healthCardBytes)-1] == '\n' {
		healthCardBytes = healthCardBytes[:len(healthCardBytes)-1]
	}

	hash := sha256.Sum256(healthCardBytes)
	return fmt.Sprintf("%x", hash[:]), nil
}

func (h *HealthCardContract) QueryHealthCard(APIstub shim.ChaincodeStubInterface, id primitive.ObjectID) (*HealthCard, error) {
	healthCardAsBytes, err := APIstub.GetState(id.Hex())
	if err != nil {
		return nil, fmt.Errorf("failed to read health card: %v", err)
	}
	if healthCardAsBytes == nil {
		return nil, fmt.Errorf("health card not found: %s", id.Hex())
	}

	var healthCard HealthCard
	err = json.Unmarshal(healthCardAsBytes, &healthCard)
	if err != nil {
		return nil, fmt.Errorf("failed to unmarshal health card data: %v", err)
	}

	return &healthCard, nil
}

func (h *HealthCardContract) QueryHealthCardsByIDs(APIstub shim.ChaincodeStubInterface, IDs []primitive.ObjectID) ([]HealthCardQueryResult, error) {
	var results []HealthCardQueryResult

	// Iterate over each provided ID
	for _, ID := range IDs {
		// Retrieve the health card from the ledger using the provided ID
		healthCardAsBytes, err := APIstub.GetState(ID.Hex())
		if err != nil {
			return nil, fmt.Errorf("failed to read health card with ID %s: %v", ID.Hex(), err)
		}

		// Check if the health card exists
		if healthCardAsBytes == nil {
			// If not found, add a pending result
			results = append(results, HealthCardQueryResult{
				ID:        ID.Hex(),
				BlockHash: "pending",
			})
		} else {
			// Unmarshal the health card data
			var healthCard HealthCard
			err = json.Unmarshal(healthCardAsBytes, &healthCard)
			if err != nil {
				return nil, fmt.Errorf("failed to unmarshal health card with ID %s: %v", ID.Hex(), err)
			}

			// Append the health card result (ID and BlockHash)
			results = append(results, HealthCardQueryResult{
				ID:        healthCard.ID.Hex(),
				BlockHash: healthCard.BlockHash,
			})
		}
	}

	return results, nil
}

func (h *HealthCardContract) EditHealthCard(
	APIstub shim.ChaincodeStubInterface,
	id primitive.ObjectID,
	name string,
	email string,
	address Address,
	phoneNumber string,
	idCode string,
	dob string,
	gender string,
	bloodGroup string,
	allergy string,
	lastBloodPressure string,
	bloodSugar string,
	pastSurgery string,
	lastHospitalization string,
	diseaseCondition string,
	regularMedication string,
	healthMessage string,
	emergencyContactNumber string,
	healthCardImages []HealthCardImages,
	slug string,
	qrUrl string,
	createdAt string,
) error {

	healthCard, err := h.QueryHealthCard(APIstub, id)
	if err != nil {
		return fmt.Errorf("failed to retrieve health card: %v", err)
	}

	healthCard.Name = name
	healthCard.Email = email
	healthCard.Address = address
	healthCard.PhoneNumber = phoneNumber
	healthCard.IDCode = idCode
	healthCard.DateOfBirth = dob
	healthCard.Gender = gender
	healthCard.BloodGroup = bloodGroup
	healthCard.Allergy = allergy
	healthCard.LastBloodPressure = lastBloodPressure
	healthCard.BloodSugar = bloodSugar
	healthCard.PastSurgery = pastSurgery
	healthCard.LastHospitalization = lastHospitalization
	healthCard.DiseaseCondition = diseaseCondition
	healthCard.RegularMedication = regularMedication
	healthCard.HealthMessage = healthMessage
	healthCard.EmergencyContactNumber = emergencyContactNumber
	healthCard.HealthCardImages = healthCardImages
	healthCard.Slug = slug
	healthCard.QrUrl = qrUrl
	healthCard.CreatedAt = createdAt

	newHash, err := computeHealthCardHash(*healthCard)
	if err != nil {
		return fmt.Errorf("failed to compute hash: %v", err)
	}
	healthCard.BlockHash = newHash

	healthCardAsBytes, err := json.Marshal(healthCard)
	if err != nil {
		return fmt.Errorf("failed to marshal updated health card data: %v", err)
	}

	err = APIstub.PutState(id.Hex(), healthCardAsBytes)
	if err != nil {
		return fmt.Errorf("failed to update health card data: %v", err)
	}

	return nil
}

func (h *HealthCardContract) QueryAllHealthCards(APIstub shim.ChaincodeStubInterface) ([]HealthCard, error) {
	resultsIterator, err := APIstub.GetStateByRange("", "")
	if err != nil {
		return nil, fmt.Errorf("failed to get state by range: %v", err)
	}
	defer resultsIterator.Close()

	var healthCards []HealthCard
	for resultsIterator.HasNext() {
		queryResponse, err := resultsIterator.Next()
		if err != nil {
			return nil, fmt.Errorf("failed to iterate over results: %v", err)
		}

		var healthCard HealthCard
		err = json.Unmarshal(queryResponse.Value, &healthCard)
		if err != nil {
			return nil, fmt.Errorf("failed to unmarshal health card data: %v", err)
		}

		healthCards = append(healthCards, healthCard)
	}

	return healthCards, nil
}

func (h *HealthCardContract) Invoke(APIstub shim.ChaincodeStubInterface) peer.Response {
	function, args := APIstub.GetFunctionAndParameters()

	switch function {

	case "CreateHealthCard":
		if len(args) != 23 {
			return shim.Error("Incorrect number of arguments. Expecting 23")
		}

		// Parse ID
		id, err := primitive.ObjectIDFromHex(args[0])
		if err != nil {
			return shim.Error(fmt.Sprintf("Invalid ID: %s", args[0]))
		}

		// Parse phoneNumber
		phoneNumber := args[4]

		// Parse address
		var address Address
		err = json.Unmarshal([]byte(args[3]), &address)
		if err != nil {
			return shim.Error(fmt.Sprintf("Invalid address JSON: %s", args[3]))
		}

		// Parse healthCardImages
		var healthCardImages []HealthCardImages
		err = json.Unmarshal([]byte(args[18]), &healthCardImages)
		if err != nil {
			return shim.Error(fmt.Sprintf("Invalid healthCardImages JSON: %s", args[18]))
		}

		var healthcardManufacturer HealthCardManufacturer
		err = json.Unmarshal([]byte(args[22]), &healthcardManufacturer)
		if err != nil {
			return shim.Error(fmt.Sprintf("Invalid certificateManufacturer JSON: %s", args[22]))
		}

		err = h.CreateHealthCard(
			APIstub,
			id,
			args[1],
			args[2],
			address,
			phoneNumber,
			args[5],
			args[6],
			args[7],
			args[8],
			args[9],
			args[10],
			args[11],
			args[12],
			args[13],
			args[14],
			args[15],
			args[16],
			args[17],
			healthCardImages,
			args[19],
			args[20],
			args[21],
			healthcardManufacturer,
		)
		if err != nil {
			return shim.Error(fmt.Sprintf("Failed to create health card: %s", err.Error()))
		}

		txID := APIstub.GetTxID()
		txTimestamp, err := APIstub.GetTxTimestamp()
		if err != nil {
			return shim.Error(fmt.Sprintf("Failed to get transaction timestamp: %v", err))
		}
		timestamp := time.Unix(txTimestamp.Seconds, int64(txTimestamp.Nanos)).UTC().Format(time.RFC3339)
		response := map[string]interface{}{
			"message":   "Health card created successfully",
			"txId":      txID,
			"timeStamp": timestamp,
		}
		responseJSON, err := json.Marshal(response)
		if err != nil {
			return shim.Error(fmt.Sprintf("Failed to marshal response: %v", err))
		}
		return shim.Success(responseJSON)

	case "QueryHealthCard":
		if len(args) != 1 {
			return shim.Error("Incorrect number of arguments. Expecting 1")
		}

		// Parse ID
		id, err := primitive.ObjectIDFromHex(args[0])
		if err != nil {
			return shim.Error(fmt.Sprintf("Invalid ID: %s", args[0]))
		}

		healthCard, err := h.QueryHealthCard(APIstub, id)
		if err != nil {
			return shim.Error(fmt.Sprintf("Failed to query health card: %s", err.Error()))
		}

		healthCardJSON, err := json.Marshal(healthCard)
		if err != nil {
			return shim.Error(fmt.Sprintf("Failed to marshal health card data: %v", err))
		}
		return shim.Success(healthCardJSON)

	case "QueryHealthCardsByIDs":
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

		// Call QueryHealthCardsByIDs function to return id and blockHash for each ID
		healthCardsResult, err := h.QueryHealthCardsByIDs(APIstub, IDs)
		if err != nil {
			return shim.Error(fmt.Sprintf("Failed to query health cards: %s", err.Error()))
		}

		// Marshal the result (user ID and blockHash for each) to JSON
		healthCardsAsBytes, err := json.Marshal(healthCardsResult)
		if err != nil {
			return shim.Error(fmt.Sprintf("Failed to marshal health cards: %s", err.Error()))
		}

		return shim.Success(healthCardsAsBytes)

	case "EditHealthCard":
		if len(args) != 22 {
			return shim.Error("Incorrect number of arguments. Expecting 22")
		}

		// Parse ID
		id, err := primitive.ObjectIDFromHex(args[0])
		if err != nil {
			return shim.Error(fmt.Sprintf("Invalid ID: %s", args[0]))
		}

		// Parse phoneNumber
		phoneNumber := args[4]

		// Parse address
		var address Address
		err = json.Unmarshal([]byte(args[3]), &address)
		if err != nil {
			return shim.Error(fmt.Sprintf("Invalid address JSON: %s", args[3]))
		}

		// Parse healthCardImages
		var healthCardImages []HealthCardImages
		err = json.Unmarshal([]byte(args[18]), &healthCardImages)
		if err != nil {
			return shim.Error(fmt.Sprintf("Invalid healthCardImages JSON: %s", args[18]))
		}

		err = h.EditHealthCard(
			APIstub,
			id,
			args[1],
			args[2],
			address,
			phoneNumber,
			args[5],
			args[6],
			args[7],
			args[8],
			args[9],
			args[10],
			args[11],
			args[12],
			args[13],
			args[14],
			args[15],
			args[16],
			args[17],
			healthCardImages,
			args[19],
			args[20],
			args[21],
		)
		if err != nil {
			return shim.Error(fmt.Sprintf("Failed to edit health card: %s", err.Error()))
		}

		txID := APIstub.GetTxID()
		txTimestamp, err := APIstub.GetTxTimestamp()
		if err != nil {
			return shim.Error(fmt.Sprintf("Failed to get transaction timestamp: %v", err))
		}
		timestamp := time.Unix(txTimestamp.Seconds, int64(txTimestamp.Nanos)).UTC().Format(time.RFC3339)
		response := map[string]interface{}{
			"message":   "Health card updated successfully",
			"txId":      txID,
			"timeStamp": timestamp,
		}
		responseJSON, err := json.Marshal(response)
		if err != nil {
			return shim.Error(fmt.Sprintf("Failed to marshal response: %v", err))
		}
		return shim.Success(responseJSON)

	case "QueryAllHealthCards":
		healthCards, err := h.QueryAllHealthCards(APIstub)
		if err != nil {
			return shim.Error(fmt.Sprintf("Failed to query all health cards: %s", err.Error()))
		}

		healthCardsJSON, err := json.Marshal(healthCards)
		if err != nil {
			return shim.Error(fmt.Sprintf("Failed to marshal health cards data: %v", err))
		}
		return shim.Success(healthCardsJSON)

	default:
		return shim.Error(fmt.Sprintf("Invalid function name: %s", function))
	}
}

func main() {
	err := shim.Start(new(HealthCardContract))
	if err != nil {
		logger.Fatalf("Error starting HealthCard contract chaincode: %cc", err)
	}
}
