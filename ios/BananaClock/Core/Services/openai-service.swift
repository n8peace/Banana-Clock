//
//  OpenAIService.swift
//  BananaClock
//
//  Service for OpenAI API interactions
//  Development: Direct API calls with local key
//  Production: Proxied through Supabase Edge Function
//

import Foundation
import Supabase

@MainActor
class OpenAIService: ObservableObject {
    static let shared = OpenAIService()
    
    private init() {}
    
    // MARK: - Chat Completion
    
    struct ChatMessage {
        let role: String
        let content: String
    }
    
    struct ChatCompletionRequest {
        let model: String
        let messages: [ChatMessage]
        let temperature: Double?
        let maxTokens: Int?
        
        init(
            model: String = "gpt-4o-mini",
            messages: [ChatMessage],
            temperature: Double? = 0.7,
            maxTokens: Int? = 1000
        ) {
            self.model = model
            self.messages = messages
            self.temperature = temperature
            self.maxTokens = maxTokens
        }
    }
    
    struct ChatCompletionResponse: Codable {
        let id: String
        let choices: [Choice]
        let usage: Usage?
        
        struct Choice: Codable {
            let message: Message
            let finishReason: String?
            
            enum CodingKeys: String, CodingKey {
                case message
                case finishReason = "finish_reason"
            }
        }
        
        struct Message: Codable {
            let role: String
            let content: String
        }
        
        struct Usage: Codable {
            let promptTokens: Int
            let completionTokens: Int
            let totalTokens: Int
            
            enum CodingKeys: String, CodingKey {
                case promptTokens = "prompt_tokens"
                case completionTokens = "completion_tokens"
                case totalTokens = "total_tokens"
            }
        }
    }
    
    func createChatCompletion(_ request: ChatCompletionRequest) async throws -> ChatCompletionResponse {
        // Always use proxy for both development and production
        return try await createChatCompletionViaProxy(request)
    }
    
    // MARK: - Private Methods
    
    private func createChatCompletionViaProxy(_ request: ChatCompletionRequest) async throws -> ChatCompletionResponse {
        print("🍌 OpenAI: Starting chat completion request")
        print("🍌 OpenAI: Model: \(request.model)")
        print("🍌 OpenAI: Messages count: \(request.messages.count)")
        print("🍌 OpenAI: Temperature: \(request.temperature ?? 0.7)")
        print("🍌 OpenAI: Max tokens: \(request.maxTokens ?? 1000)")
        
        // Ensure user is authenticated
        print("🍌 OpenAI: Checking user authentication...")
        guard let session = try await SupabaseService.shared.getCurrentSession() else {
            print("❌ OpenAI: User not authenticated")
            throw OpenAIError.notAuthenticated
        }
        print("✅ OpenAI: User authenticated with session")
        print("🍌 OpenAI: Access token length: \(session.accessToken.count)")
        
        // Prepare request body
        let messagesArray = request.messages.map { ["role": $0.role, "content": $0.content] }
        let body: [String: Any] = [
            "model": request.model,
            "messages": messagesArray,
            "temperature": request.temperature ?? 0.7,
            "max_tokens": request.maxTokens ?? 1000
        ]
        
        print("🍌 OpenAI: Request body prepared")
        print("🍌 OpenAI: Messages in request: \(messagesArray.count)")
        for (index, message) in messagesArray.enumerated() {
            print("  Message \(index): \(message["role"] ?? "unknown") - \((message["content"] as? String)?.prefix(50) ?? "empty")...")
        }
        
        // Make request to proxy
        let proxyURL = "\(AppEnvironment.supabaseURL)/functions/v1/openai-proxy"
        print("🍌 OpenAI: Proxy URL: \(proxyURL)")
        
        guard let url = URL(string: proxyURL) else {
            print("❌ OpenAI: Invalid proxy URL")
            throw OpenAIError.invalidResponse
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("Bearer \(session.accessToken)", forHTTPHeaderField: "Authorization")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            urlRequest.httpBody = try JSONSerialization.data(withJSONObject: body)
            print("✅ OpenAI: Request body serialized successfully")
            print("🍌 OpenAI: Body size: \(urlRequest.httpBody?.count ?? 0) bytes")
        } catch {
            print("❌ OpenAI: Failed to serialize request body: \(error)")
            throw OpenAIError.invalidResponse
        }
        
        print("🍌 OpenAI: Making request to proxy...")
        
        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await URLSession.shared.data(for: urlRequest)
            print("✅ OpenAI: Received response from proxy")
        } catch {
            print("❌ OpenAI: Network request failed: \(error)")
            print("❌ OpenAI: Error details: \(error.localizedDescription)")
            throw OpenAIError.proxyError(statusCode: -1, message: "Network error: \(error.localizedDescription)")
        }
        
        guard let httpResponse = response as? HTTPURLResponse else {
            print("❌ OpenAI: Invalid response type")
            throw OpenAIError.invalidResponse
        }
        
        print("🍌 OpenAI: HTTP Status Code: \(httpResponse.statusCode)")
        print("🍌 OpenAI: Response headers: \(httpResponse.allHeaderFields)")
        print("🍌 OpenAI: Response data size: \(data.count) bytes")
        
        // Always log the response body for debugging
        if let responseString = String(data: data, encoding: .utf8) {
            print("🍌 OpenAI: Response body: \(responseString.prefix(500))\(responseString.count > 500 ? "..." : "")")
        }
        
        guard httpResponse.statusCode == 200 else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            print("❌ OpenAI: Proxy error (\(httpResponse.statusCode)): \(errorMessage)")
            throw OpenAIError.proxyError(statusCode: httpResponse.statusCode, message: errorMessage)
        }
        
        do {
            let decodedResponse = try JSONDecoder().decode(ChatCompletionResponse.self, from: data)
            print("✅ OpenAI: Successfully decoded response")
            print("🍌 OpenAI: Response ID: \(decodedResponse.id)")
            print("🍌 OpenAI: Choices count: \(decodedResponse.choices.count)")
            if let firstChoice = decodedResponse.choices.first {
                print("🍌 OpenAI: First choice content: \(firstChoice.message.content.prefix(100))...")
            }
            return decodedResponse
        } catch {
            print("❌ OpenAI: Failed to decode response: \(error)")
            print("❌ OpenAI: Decoding error details: \(error.localizedDescription)")
            throw OpenAIError.invalidResponse
        }
    }
    
    // MARK: - Convenience Methods
    
    func generateText(
        prompt: String,
        systemPrompt: String? = nil,
        model: String = "gpt-4o-mini",
        temperature: Double = 0.7,
        maxTokens: Int = 1000
    ) async throws -> String {
        print("🍌 OpenAI: generateText called")
        print("🍌 OpenAI: Prompt length: \(prompt.count)")
        print("🍌 OpenAI: System prompt: \(systemPrompt != nil ? "Present (\(systemPrompt!.count) chars)" : "None")")
        print("🍌 OpenAI: Model: \(model)")
        
        var messages: [ChatMessage] = []
        
        if let systemPrompt = systemPrompt {
            messages.append(ChatMessage(role: "system", content: systemPrompt))
            print("🍌 OpenAI: Added system message")
        }
        
        messages.append(ChatMessage(role: "user", content: prompt))
        print("🍌 OpenAI: Added user message")
        print("🍌 OpenAI: Total messages: \(messages.count)")
        
        let request = ChatCompletionRequest(
            model: model,
            messages: messages,
            temperature: temperature,
            maxTokens: maxTokens
        )
        
        do {
            let response = try await createChatCompletion(request)
            
            guard let content = response.choices.first?.message.content else {
                print("❌ OpenAI: No content in response")
                print("🍌 OpenAI: Response choices: \(response.choices.count)")
                throw OpenAIError.noContent
            }
            
            print("✅ OpenAI: generateText completed successfully")
            print("🍌 OpenAI: Generated content length: \(content.count)")
            return content
        } catch {
            print("❌ OpenAI: generateText failed: \(error)")
            throw error
        }
    }
}

// MARK: - Errors

enum OpenAIError: LocalizedError {
    case missingAPIKey
    case notAuthenticated
    case invalidResponse
    case noContent
    case apiError(statusCode: Int, message: String)
    case proxyError(statusCode: Int, message: String)
    
    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "OpenAI API key not configured"
        case .notAuthenticated:
            return "User must be authenticated to use AI features"
        case .invalidResponse:
            return "Invalid response from server"
        case .noContent:
            return "No content in response"
        case .apiError(let statusCode, let message):
            return "OpenAI API error (\(statusCode)): \(message)"
        case .proxyError(let statusCode, let message):
            return "Proxy error (\(statusCode)): \(message)"
        }
    }
}