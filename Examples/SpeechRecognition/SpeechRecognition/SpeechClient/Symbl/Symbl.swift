//import AVFoundation
//import Combine
//import ComposableArchitecture
//import Speech
//import Starscream
//
//extension SpeechClient {
//  static var symbl: Self {
//    var audioEngine: AVAudioEngine!
//    var ws: WebSocket!
//
//    let symblApi = Symbl()
//
//    return Self(
//      requestAuthorization: {
//        .future { callback in
//
//          symblApi.authenticate(authCallback: { result in
//            switch result {
//            case let .success(token):
//              print("Token: \(token)")
//              let authResult = SpeechRecognitionAuthorizationResult(
//                status: .authorized,
//                token: token.token,
//                expiresAt: token.expiresAt!
//              )
//              callback(.success(authResult))
//
//            case let .failure(error):
//              fatalError("Error authenticating \(error)")
//              print("Error authenticating: \(error)")
//            }
//          })
//        }
//      },
//
//      recognitionTask: { token in
//
//        Effect.run { subscriber in
//          guard let token = token else {
//            // TODO: handle (although rare) error appropriately
//            fatalError("No token")
//          }
//
//          // MARK: - Setup
//
//          let randomConnectionId = UUID().uuidString
//
//          var request =
//            URLRequest(
//              url: URL(
//                string: "wss://api.symbl.ai/v1/streaming/\(randomConnectionId)?access_token=\(token)"
//              )!
//            )
//          request.timeoutInterval = 5
//          ws = WebSocket(request: request)
//
//          ws.onEvent = { event in
//            print(event)
//            print(
//              "--------------------------------------------------------------------------------"
//            )
//            switch event {
//            case let .connected(headers):
//              print("connected")
//              //      self.isConnected = true
//              //              print("websocket is connected: \(headers)")
//              // create a dictionary
//              let configStartRequest: [String: Any] = [
//                "type": "start_request",
//                "insightTypes": ["question", "action_item"],
//                "speaker": [
//                  "name": "Blueberry Chopsticks",
//                ],
//              ]
//              // convert to json data
//              let jsonData = try? JSONSerialization.data(
//                withJSONObject: configStartRequest,
//                options: []
//              )
//              // print out all the json to the console
//              print(String(data: jsonData!, encoding: .utf8)!)
//
//              ws.write(data: jsonData!)
//
//            case let .disconnected(reason, code):
//              //      isConnected = false
//              print("websocket is disconnected: \(reason) with code: \(code)")
//            case let .text(string):
//              print("Received text: \(string)")
//
//            case let .binary(data):
//              print("Received data: \(data.count)")
//            case .ping:
//              print("Received ping")
//            case .pong:
//              print("Received pong")
//            case .viabilityChanged:
//              print("Viability changed")
//            case .reconnectSuggested:
//              print("Reconnect suggested")
//            case .cancelled:
//              print("Cancelled")
//            //      isConnected = false
//            case let .error(error):
//              print("error")
//              //      isConnected = false
//              handleError(error)
//            }
//          }
//
//          let cancellable = AnyCancellable {
//            audioEngine?.stop()
//            inputNode?.removeTap(onBus: 0)
//            //            recognitionTask?.cancel()
//            //            _ = speechRecognizer
//            //            _ = speechRecognizerDelegate
//          }
//
//          // MARK: - Audio Setup
//
//          audioEngine = .init()
//
//          let inputNode = audioEngine!.inputNode
//          let inputFormat = inputNode.inputFormat(forBus: 0)
//
//          let outputFormat = AVAudioFormat(
//            commonFormat: .pcmFormatInt16,
//            sampleRate: inputFormat.sampleRate,
//            channels: inputFormat.channelCount,
//            interleaved: true
//          )
//
//          let converterNode = AVAudioMixerNode()
//          let sinkNode = AVAudioMixerNode()
//
//          audioEngine!.attach(converterNode)
//          audioEngine!.attach(sinkNode)
//
//          converterNode.installTap(
//            onBus: 0,
//            bufferSize: 1024,
//            format: converterNode.outputFormat(forBus: 0)
//          ) { buffer, _ in
////            print(buffer, time)
//
//            let audioBuffer = buffer.audioBufferList.pointee.mBuffers
//            let audioData = Data(
//              bytes: audioBuffer.mData!,
//              count: Int(audioBuffer.mDataByteSize)
//            )
//
//            ws.write(data: audioData)
//          }
//
//          audioEngine!.connect(inputNode, to: converterNode, format: inputFormat)
//          audioEngine!.connect(converterNode, to: sinkNode, format: outputFormat)
//          audioEngine!.prepare()
//
//          do {
//            try AVAudioSession.sharedInstance().setCategory(.record)
//            try audioEngine!.start()
//            ws.connect()
//          } catch {
//            subscriber.send(completion: .failure(.couldntStartAudioEngine))
//            return cancellable
//          }
//
//          return cancellable
//        }
//      },
//
//      finishTask: {
//        .fireAndForget {
////          request.endAudio()
//          audioEngine?.stop()
//          inputNode?.removeTap(onBus: 0)
////          recognitionTask?.finish()
//        }
//      }
//    )
//  }
//}
