// Copyright (c) 2024, WSO2 LLC. (http://www.wso2.com).
//
// WSO2 LLC. licenses this file to you under the Apache License,
// Version 2.0 (the "License"); you may not use this file except
// in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.

import ballerina/http;
import ballerina/time;
import ballerina/uuid;
import ballerina/io;

listener http:Listener httpListener = new (8080);

http:Service mockService = service object {

    # Get account information
    #
    # + return - returns can be any of following types
    # http:Ok (The request has succeeded.)
    # http:Response (The request has failed.)
    resource function get api/v1/account() returns AccountResponse|http:Response {
        AccountResponse response = {
            "id": "acc_12345",
            "trust": {
                "direct_trust": true,
                "external_trust": false,
                "trustAll": false
            }
        };
        return response;
    }

    # List Deployments
    #
    # + headers - Headers to be sent with the request 
    # + return - The list of deployments that belong to the authenticated user
    resource function get api/v1/deployments() returns json|http:Response {
        json deploymentsResponse = {
            deployments: [
                {
                    "id": "dep_001",
                    "name": "production-cluster",
                    "region": "us-west",
                    "status": "running",
                    "resources": []
                },
                {
                    "id": "dep_002",
                    "name": "test-cluster",
                    "region": "eu-central",
                    "status": "stopped",
                    "resources": []
                }
            ]
        };
        return deploymentsResponse;
    }

    # Get API key
    #
    # + apiKeyId - The API Key ID
    # + headers - Headers to be sent with the request 
    # + return - The API key metadata is retrieved 
    resource function get api/v1/users/auth/keys/[string keyId]() returns json|http:Response {
        json apiKey = {
            "id": keyId,
            "name": "My test key",
            "description": "This is a test API key",
            "user_id": "user_001",
            "creation_date": "2023-01-01T00:00:00Z",
            "expiration_date": "2025-01-01T00:00:00Z"
        };
        return apiKey;
    }

    # # Create API key
    #
    # + headers - Headers to be sent with the request 
    # + payload - The request to create the API key 
    # + return - The API key is created and returned in the body of the response 
    resource function post api/v1/users/auth/keys(@http:Payload json payload) returns json|http:Response|error {
        // Generate a mock API key ID
        string keyId = "key_" + uuid:createType4AsString().substring(0, 8);

        // Extract fields from the payload safely
        string keyName = payload.name is string ? (check payload.name).toString() : "Unnamed Key";
        string? description = payload.description is string ? (check payload.description).toString() : ();
        string? expirationDate = payload.expiration_date is string ? (check payload.expiration_date).toString() : ();

        json apiKeyResponse = {
            "id": keyId,
            "name": keyName,
            "description": description,
            "user_id": "user_001",
            "creation_date": time:utcToString(time:utcNow()),
            "expiration_date": expirationDate,
            "api_key": "elastic_api_key_" + uuid:createType4AsString() // Mock API key value
        };

        return apiKeyResponse;
    }

    # Get organizations list
    #
    # + return - returns can be any of following types
    # http:Ok (The request has succeeded.)
    # http:Response (The request has failed.)
    resource function get api/v1/organizations() returns json|http:Response {
        json organizationsResponse = {
            "organizations": [
                {
                    "id": "org_001",
                    "name": "Test Organization 1",
                    "type": "standard",
                    "created_at": "2023-01-01T00:00:00Z",
                    "updated_at": "2023-06-01T00:00:00Z"
                },
                {
                    "id": "org_002",
                    "name": "Test Organization 2",
                    "type": "enterprise",
                    "created_at": "2023-02-01T00:00:00Z",
                    "updated_at": "2023-06-15T00:00:00Z"
                }
            ],
            "next_page": null
        };
        return organizationsResponse;
    }

    # Create Deployment
    #
    # + request - The HTTP request containing the deployment definition
    # + return - The deployment creation response
    resource function post api/v1/deployments(http:Request request) returns DeploymentCreateResponse|http:Response {
        // Extract JSON payload from request
        json|error payloadJson = request.getJsonPayload();

        if payloadJson is error {
            return createErrorResponse(400, "Invalid JSON payload");
        }

        // Extract name from payload
        json|error nameJson = payloadJson.name;
        if nameJson is error || nameJson is () {
            return createErrorResponse(400, "Deployment name is required");
        }

        string deploymentName = nameJson.toString();
        if deploymentName == "" {
            return createErrorResponse(400, "Deployment name is required");
        }

        // Extract optional alias
        json|error aliasJson = payloadJson.alias;
        string? alias = aliasJson is string ? aliasJson : ();

        // Generate a simple deployment ID
        string deploymentId = "dep_" + deploymentName.toLowerAscii() + "_123";

        // Create simple mock response
        DeploymentCreateResponse response = {
            created: true,
            name: deploymentName,
            alias: alias,
            id: deploymentId,
            resources: [
                {
                    id: "res_001",
                    kind: "elasticsearch",
                    region: "us-west-1",
                    refId: "main-elasticsearch"
                }
            ]
        };

        return response;
    }

    # Search Deployments
    #
    # + headers - Headers to be sent with the request 
    # + queries - Queries to be sent with the request 
    # + payload - (Optional) The search query to run. When not specified, all deployments are matched 
    # + return - The list of deployments that match the specified query and belong to the authenticated user 
    resource function post api/v1/deployments/_search(http:Request req) returns DeploymentsSearchResponse|http:Response {
        json|error payloadJson = req.getJsonPayload();
        if payloadJson is error {
            return createErrorResponse(400, "Invalid JSON payload");
        }

        DeploymentsSearchResponse response = {
            deployments: [
                {
                    id: "dep_001",
                    name: "production-cluster",
                    resources: {
                        apm: [],
                        appsearch: [],
                        elasticsearch: [],
                        enterpriseSearch: [],
                        integrationsServer: [],
                        kibana: []
                    },
                    healthy: false
                },
                {
                    id: "dep_002",
                    name: "test-cluster",
                    resources: {
                        apm: [],
                        appsearch: [],
                        elasticsearch: [],
                        enterpriseSearch: [],
                        integrationsServer: [],
                        kibana: []
                    },
                    healthy: false
                }
            ],
            returnCount: 2,
            matchCount: 2
        };

        return response;
    }

    # Delete API key
    #
    # + keyId - The API Key ID to delete
    # + headers - Headers to be sent with the request 
    # + return - The API key deletion response 
    resource function delete api/v1/users/auth/keys/[string keyId]() returns json|http:Response {
        // Check if keyId is provided and not empty
        if keyId == "" {
            return createErrorResponse(400, "API Key ID is required");
        }

        // For mock purposes, simulate successful deletion
        json deleteResponse = {
            "found": true,
            "invalidated": true
        };

        return deleteResponse;
    }

};

function init() returns error? {
    if isLiveServer {
        io:println("Running against live server, skipping mock service initialization.");
        return;
    }
    check httpListener.attach(mockService, "/");
    check httpListener.'start();
}

// Helper function to create error responses
function createErrorResponse(int statusCode, string message) returns http:Response {
    http:Response response = new;
    response.statusCode = statusCode;

    json errorBody = {
        "error": {
            "type": "api_error",
            "message": message
        }
    };

    response.setJsonPayload(errorBody);
    response.setHeader("Content-Type", "application/json");

    return response;
}
