//
//  OpenAIExampleView.swift
//  BananaClock
//
//  Example usage of OpenAI service
//  For development testing only
//

#if DEBUG
import SwiftUI

struct OpenAIExampleView: View {
    @StateObject private var openAI = OpenAIService.shared
    @State private var prompt = ""
    @State private var response = ""
    @State private var isLoading = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("OpenAI Test")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                VStack(alignment: .leading, spacing: 10) {
                    Text("Enter a prompt:")
                        .font(.headline)
                    
                    TextEditor(text: $prompt)
                        .frame(height: 100)
                        .padding(8)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                }
                
                Button(action: testOpenAI) {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                    } else {
                        Text("Generate Response")
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(prompt.isEmpty || isLoading)
                
                if !response.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Response:")
                            .font(.headline)
                        
                        ScrollView {
                            Text(response)
                                .font(.body)
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.green.opacity(0.1))
                                .cornerRadius(8)
                        }
                    }
                }
                
                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding()
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(8)
                }
                
                Spacer()
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private func testOpenAI() {
        isLoading = true
        errorMessage = ""
        response = ""
        
        Task {
            do {
                // Example: Generate a wake-up message
                let systemPrompt = "You are a cheerful AI assistant helping users wake up with a smile. Keep responses brief and uplifting."
                
                let generatedText = try await openAI.generateText(
                    prompt: prompt,
                    systemPrompt: systemPrompt,
                    model: "gpt-4o-mini",
                    temperature: 0.8,
                    maxTokens: 150
                )
                
                await MainActor.run {
                    response = generatedText
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isLoading = false
                }
            }
        }
    }
}

// MARK: - Integration Example
extension OpenAIExampleView {
    /// Example of how to use in production code
    static func exampleUsage() async {
        do {
            // Simple text generation
            let joke = try await OpenAIService.shared.generateText(
                prompt: "Tell me a banana joke",
                temperature: 0.9
            )
            print("Joke: \(joke)")
            
            // More complex conversation
            let messages = [
                OpenAIService.ChatMessage(role: "system", content: "You are a helpful alarm clock assistant"),
                OpenAIService.ChatMessage(role: "user", content: "What's the weather like today?")
            ]
            
            let request = OpenAIService.ChatCompletionRequest(
                model: "gpt-4o-mini",
                messages: messages
            )
            
            let response = try await OpenAIService.shared.createChatCompletion(request)
            print("Response: \(response.choices.first?.message.content ?? "")")
            
        } catch {
            print("Error: \(error)")
        }
    }
}

#Preview {
    OpenAIExampleView()
}
#endif