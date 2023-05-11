import SwiftUI

struct ContentView: View {
    @State private var username = ""
    @State private var token = ""
    @State private var messages: [String] = []
    @State private var messageText = ""
    @State private var userList: [String] = []
    
    func login() {
        guard let url = URL(string: "http://localhost:8000/login?username=\(username)") else { return }
        let body = ["username": username]
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        guard let httpBody = try? JSONSerialization.data(withJSONObject: body, options: []) else { return }
        request.httpBody = httpBody
        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data else { return }
            do {
                let decodedResponse = try JSONDecoder().decode(TokenResponse.self, from: data)
                DispatchQueue.main.async {
                    self.token = decodedResponse.token
                }
            } catch let error {
                print(error)
            }
        }.resume()
    }
    
    func logout() {
        guard let url = URL(string: "http://localhost:8000/logout?token=\(token)") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue(token, forHTTPHeaderField: "Authorization")
        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data else { return }
            if let response = String(data: data, encoding: .utf8) {
                DispatchQueue.main.async {
                    self.token = ""
                    self.messages = []
                    self.userList = []
                    print(response)
                }
            }
        }.resume()
    }
    
    func getMessages() {
        guard let url = URL(string: "http://localhost:8000/message/list?token=\(token)") else { return }
        var request = URLRequest(url: url)
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue(token, forHTTPHeaderField: "Authorization")
        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data else { return }
            do {
                let decodedResponse = try JSONDecoder().decode([MessageResponse].self, from: data)
                DispatchQueue.main.async {
                    self.messages = decodedResponse.map { "\($0.user): \($0.message)" }
                }
            } catch let error {
                print(error)
            }
        }.resume()
    }
    
    func postMessage() {
        guard let url = URL(string: "http://localhost:8000/message") else { return }
        let body = ["message": messageText, "token": token]
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        guard let httpBody = try? JSONSerialization.data(withJSONObject: body, options: []) else { return }
        request.httpBody = httpBody
        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data else { return }
            do {
                let decodedResponse = try JSONDecoder().decode(MessageIdResponse.self, from: data)
                DispatchQueue.main.async {
                    self.messages.append("You: \(self.messageText)")
                    self.messageText = ""
                }
            } catch let error {
                print(error)
            }
        }.resume()
    }
    
    func getUsers() {
        guard let url = URL(string: "http://localhost:8000/user/list?token=\(token)") else { return }
        var request = URLRequest(url: url)
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue(token, forHTTPHeaderField: "Authorization")
        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data else { return }
            do {
                let decodedResponse = try JSONDecoder().decode([UserResponse].self, from: data)
                DispatchQueue.main.async {
                    self.userList = decodedResponse.map { $0.username }
                }
            } catch let error {
                print(error)
            }
        }.resume()
    }
    
    var body: some View {
        VStack {
            if token.isEmpty {
                TextField("Enter username", text: $username)
                    .padding()
                Button("Login") {
                    login()
                }
            } else {
                HStack {
                    Text("Logged in as: \(username)")
                    Spacer()
                    Button("Logout") {
                        logout()
                    }
                }
                .padding()
                
                List(messages, id: \.self) { message in
                    Text(message)
                }
                .onAppear {
                    getMessages()
                }
                
                HStack {
                    TextField("Type message", text: $messageText)
                        .padding()
                    Button("Send") {
                        postMessage()
                    }
                }
                .padding()
                
                List(userList, id: \.self) { user in
                    Text(user)
                }
                .onAppear {
                    getUsers()
                }
            }
        }
    }
}

struct TokenResponse: Decodable {
    let token: String
}

struct MessageResponse: Decodable {
    let user: String
    let message: String
}

struct MessageIdResponse: Decodable {
    let id: String
}

struct UserResponse: Decodable {
    let username: String
}
