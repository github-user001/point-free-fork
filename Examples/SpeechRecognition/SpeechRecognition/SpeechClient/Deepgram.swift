import Combine
import ComposableArchitecture
import Foundation
import Speech
import Starscream
import AVFoundation

extension SpeechClient {
  static var deepgram: Self {
    let apiKey = "Token 051eb23117ef848bb315bfeaa84c4a59a99c18b2"
    var audioEngine: AVAudioEngine!
    let shouldPunctuate = true
    var runningTranscript = ""

    lazy var socket: WebSocket = {
      let url =
        URL(
          string: "wss://api.deepgram.com/v1/listen?encoding=linear16&sample_rate=48000&channels=1"
        )!
      var urlRequest = URLRequest(url: url)
      urlRequest.url?.append(queryItems: [Foundation.URLQueryItem(name: "punctuate", value: shouldPunctuate.description)])
      urlRequest.setValue(
        "permessage-deflate",
        forHTTPHeaderField: "Sec-WebSocket-Extensions"
      )
      urlRequest.setValue(apiKey, forHTTPHeaderField: "Authorization")
      return WebSocket(request: urlRequest)
    }()

    return Self(
      requestAuthorization: {
        .future { callback in

          callback(.success(.init(status: .authorized)))
        }
      },

      recognitionTask: { _ in
        Effect.run { subscriber in

          let cancellable = AnyCancellable {
            print("anycancellable")
            socket.disconnect(closeCode: 0)
//            audioEngine.stop()
//            inputNode.removeTap(onBus: 0)

//            recognitionTask?.cancel()
//            _ = speechRecognizer
//            _ = speechRecognizerDelegate
          }

          audioEngine = .init()
          let inputNode: AVAudioInputNode = audioEngine.inputNode
          let inputFormat = inputNode.outputFormat(forBus: 0)
          let outputFormat = AVAudioFormat(
            commonFormat: .pcmFormatInt16,
            sampleRate: inputFormat.sampleRate,
            channels: inputFormat.channelCount,
            interleaved: true
          )

          socket.onEvent = { event in
            print("event: \(event)")
            switch event {
            case let .text(text):
              let jsonData = Data(text.utf8)
              let response = try! jsonDecoder.decode(DeepgramResponse.self, from: jsonData)
              let transcript = response.channel.alternatives.first!.transcript
              if transcript == "" {
                return
              }
              
              runningTranscript += "\n" + transcript
              
              if response.isFinal {
                print("Transcript isFinal")
                subscriber.send(.taskResult(SpeechRecognitionResult(runningTranscript)))
              } else {
                print("Transcript !isFinal")
                subscriber.send(.taskResult(SpeechRecognitionResult(runningTranscript)))
              }
//            case let .error(error):
//              print(error ?? "")
            default:
              print("something else happened")
            }
          }

          let converterNode = AVAudioMixerNode()
          let sinkNode = AVAudioMixerNode()

          audioEngine.attach(converterNode)
          audioEngine.attach(sinkNode)

          converterNode.installTap(
            onBus: 0,
            bufferSize: 1024,
            format: converterNode.outputFormat(forBus: 0)
          ) { (buffer: AVAudioPCMBuffer!, _: AVAudioTime!) in
            let audioBuffer = buffer.audioBufferList.pointee.mBuffers
            let data = Data(
              bytes: audioBuffer.mData!,
              count: Int(audioBuffer.mDataByteSize)
            )
            socket.write(data: data) {
//              print("Write completed")
            }
          }

          audioEngine.connect(inputNode, to: converterNode, format: inputFormat)
          audioEngine.connect(converterNode, to: sinkNode, format: outputFormat)
          audioEngine.prepare()

          do {
            try AVAudioSession.sharedInstance().setCategory(.record)
            try audioEngine.start()
            socket.connect()
            print("Started")
          } catch {
            print("Error: \(error)")
          }

          return cancellable
        }
      }, finishTask: {
        .fireAndForget {
//          request.endAudio()
          audioEngine.stop()
          print("fireAndForget")
          socket.disconnect()
          
//          inputNode.removeTap(onBus: 0)
//          recognitionTask?.finish()
        }
      }
    )
  }
}

private class SpeechRecognizerDelegate: NSObject, SFSpeechRecognizerDelegate {
  var availabilityDidChange: (Bool) -> Void

  init(availabilityDidChange: @escaping (Bool) -> Void) {
    self.availabilityDidChange = availabilityDidChange
  }

  func speechRecognizer(_: SFSpeechRecognizer, availabilityDidChange available: Bool) {
    availabilityDidChange(available)
  }
}


struct DeepgramResponse: Codable {
  let isFinal: Bool
  let channel: Channel
  let duration: Float16
  
  struct Channel: Codable {
    let alternatives: [Alternatives]
  }
  
  struct Alternatives: Codable {
    let transcript: String
  }
}

private let jsonDecoder: JSONDecoder = {
  let decoder = JSONDecoder()
  decoder.keyDecodingStrategy = .convertFromSnakeCase
  return decoder
}()
