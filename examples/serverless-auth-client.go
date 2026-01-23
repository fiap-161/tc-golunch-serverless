package examples
// Example: Updated HTTP client to use serverless authentication
// This replaces the local middleware approach

package examples

import (
    "bytes"
    "encoding/json"
    "fmt"
    "net/http"
    "os"
    "time"
)

// ServiceAuthRequest represents the request to validate service authentication
type ServiceAuthRequest struct {
    ServiceName string `json:"serviceName"`
    ApiKey      string `json:"apiKey"`
}

// ServiceAuthResponse represents the response from service authentication
type ServiceAuthResponse struct {
    Success     bool   `json:"success"`
    ServiceName string `json:"serviceName"`
    Message     string `json:"message"`
    Error       string `json:"error,omitempty"`
}

// ValidateServiceAuth validates service credentials using serverless Lambda
func ValidateServiceAuth(serviceName, apiKey string) error {
    // Get the service auth API URL from environment
    serviceAuthURL := os.Getenv("SERVICE_AUTH_API_URL")
    if serviceAuthURL == "" {
        // Fallback to local validation for development
        return validateServiceAuthLocal(serviceName, apiKey)
    }
    
    // Prepare request
    authRequest := ServiceAuthRequest{
        ServiceName: serviceName,
        ApiKey:      apiKey,
    }
    
    jsonData, err := json.Marshal(authRequest)
    if err != nil {
        return fmt.Errorf("failed to marshal auth request: %v", err)
    }
    
    // Create HTTP request
    req, err := http.NewRequest("POST", serviceAuthURL, bytes.NewBuffer(jsonData))
    if err != nil {
        return fmt.Errorf("failed to create auth request: %v", err)
    }
    
    req.Header.Set("Content-Type", "application/json")
    
    // Execute request with timeout
    client := &http.Client{Timeout: 10 * time.Second}
    resp, err := client.Do(req)
    if err != nil {
        return fmt.Errorf("service auth request failed: %v", err)
    }
    defer resp.Body.Close()
    
    // Parse response
    var authResponse ServiceAuthResponse
    if err := json.NewDecoder(resp.Body).Decode(&authResponse); err != nil {
        return fmt.Errorf("failed to decode auth response: %v", err)
    }
    
    // Check authentication result
    if resp.StatusCode != 200 || !authResponse.Success {
        return fmt.Errorf("service authentication failed: %s", authResponse.Error)
    }
    
    return nil
}

// validateServiceAuthLocal provides local fallback for development
func validateServiceAuthLocal(serviceName, apiKey string) error {
    expectedKey := os.Getenv(serviceName + "_API_KEY")
    if expectedKey == "" {
        return fmt.Errorf("no API key configured for service: %s", serviceName)
    }
    
    if apiKey != expectedKey {
        return fmt.Errorf("invalid API key for service: %s", serviceName)
    }
    
    return nil
}

// AddServiceAuthHeaders adds authentication headers to HTTP requests
func AddServiceAuthHeaders(req *http.Request, serviceName string) error {
    apiKey := os.Getenv(serviceName + "_API_KEY")
    if apiKey == "" {
        return fmt.Errorf("no API key found for service: %s", serviceName)
    }
    
    req.Header.Set("X-Service-Name", serviceName)
    req.Header.Set("X-Service-Key", apiKey)
    
    return nil
}