//
// Created by laptop on 5/4/22.
//
import AVFoundation
import Foundation
import Speech
import Starscream
import SwiftUI

class Symbl {
  var ws: WebSocket!
  var recordingSession: AVCaptureSession!
  var audioRecorder: AVAudioRecorder!

  // get the current timer
  @Published var timer: Timer = .init()
  // Observe the timer in a text view
  @Published var timerText: String = ""

  @Published
  var session: String = ""
  @Published
  var token: String = ""
  @Published
  var isAuthenticated: Bool = false
  @Published
  var isConnected: Bool = false
  @Published
  var error: String = ""
  @Published
  var recording: Bool = false

  func getDocumentsDirectory() -> URL {
    let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
    let documentsDirectory = paths[0]
    return documentsDirectory
  }

  // MARK: Auth

  /// A Struct that holds a token and expiresAt Date
  /// - Note:
  ///  - expiresAt is the date when the token expires
  /// - expiresAt is nil if the token is not valid
  /// - expiresAt is nil if the token is valid but has expired
  struct Token: Codable {
    let token: String
    let expiresAt: Date?
  }

  /// A Type for a callback that returns a Result containing either a Token or an Error
  typealias TokenCallback = (Result<Token, Error>) -> Void

  func authenticate(authCallback: @escaping TokenCallback) {
    let appId = SymblApiKeys.appId
    let appSecret = SymblApiKeys.appSecret

    // Get token and expiresIn from UserDefaults
//    let defaults = UserDefaults.standard
//    let token = defaults.string(forKey: "accessToken")
//    let expiresAt = defaults.string(forKey: "expiresAt")

    // If we don't have a token or if the token is expired, get a new one
//    if token == nil || expiresAt == nil || expiresAt! < Date().timeIntervalSince1970.description {
    let authOptions: [String: Any] = [
      "type": "application",
      "appId": appId,
      "appSecret": appSecret,
    ]

    let url = "https://api.symbl.ai/oauth2/token:generate"

    let request = NSMutableURLRequest(url: NSURL(string: url)! as URL)
    request.httpMethod = "POST"
    request.addValue("application/json", forHTTPHeaderField: "Content-Type")
    request.httpBody = try? JSONSerialization.data(
      withJSONObject: authOptions,
      options: []
    )

    let session = URLSession.shared
    session.dataTask(
      with: request as URLRequest,
      completionHandler: { data, _, error in
        if let data = data {
          do {
            let json = try JSONSerialization
              .jsonObject(with: data, options: []) as! [String: Any]
            let token = json["accessToken"] as! String
            let expiresIn = json["expiresIn"] as! Double
            // Add expires in to the current time
            let expiresAt = Date().timeIntervalSince1970 + expiresIn
            // Save expiresAt and token to UserDefaults
//            defaults.set(token, forKey: "accessToken")
//            defaults.set(expiresAt, forKey: "expiresAt")

//          DispatchQueue.main.async {

            authCallback(.success(Token(
              token: token,
              expiresAt: Date(timeIntervalSince1970: expiresAt)
            )))
//          self.token = token
//          self.isAuthenticated = true
//          }
          } catch {
            authCallback(.failure(error))
          }
        }
      }
    ).resume()

//    } else {
//      DispatchQueue.main.async {
//        self.token = token!
//        self.isAuthenticated = true
//      }
  }
}

// MARK: Setup websocket

func connect(_ token: String) {
  print("connect")
  let randomConnectionId = UUID().uuidString

  var request =
    URLRequest(
      url: URL(
        string: "wss://api.symbl.ai/v1/streaming/\(randomConnectionId)?access_token=\(token)"
      )!
    )
  request.timeoutInterval = 5
  let ws = WebSocket(request: request)

  ws.onEvent = { event in
    print(event)
    switch event {
    case let .connected(headers):
      print("connected")
//      self.isConnected = true
      print("websocket is connected: \(headers)")
      // create a dictionary
      let configStartRequest: [String: Any] = [
        "type": "start_request",
        "insightTypes": ["question", "action_item"],
        "speaker": [
          "name": "Blueberry Chopsticks",
        ],
      ]
      // convert to json data
      let jsonData = try? JSONSerialization.data(
        withJSONObject: configStartRequest,
        options: []
      )
      ws.write(data: jsonData!)

    case let .disconnected(reason, code):
//      isConnected = false
      print("websocket is disconnected: \(reason) with code: \(code)")
    case let .text(string):
      print("Received text: \(string)")

    case let .binary(data):
      print("Received data: \(data.count)")
    case .ping:
      print("Received ping")
    case .pong:
      print("Received pong")
    case .viabilityChanged:
      print("Viability changed")
    case .reconnectSuggested:
      print("Reconnect suggested")
    case .cancelled:
      print("Cancelled")
//      isConnected = false
    case let .error(error):
//      isConnected = false
      handleError(error)
    }
  }
  ws.connect()
}

func handleError(_ error: Error?) {
  print(error?.localizedDescription)
}
