import Combine
import ComposableArchitecture
import Foundation
import Speech

extension SpeechClient {
  static var apple: Self {
    var audioEngine: AVAudioEngine?
    var inputNode: AVAudioInputNode?
    var recognitionTask: SFSpeechRecognitionTask?
    let request = SFSpeechAudioBufferRecognitionRequest()

    return Self(
      requestAuthorization: {
        .future { callback in
          SFSpeechRecognizer.requestAuthorization { status in
            callback(.success(SpeechRecognitionAuthorizationResult(
              status: status
                .toSpeechRecognizerAuthorizationStatus
            )))
          }
        }
      },
      recognitionTask: { _ in
        Effect.run { subscriber in

          request.shouldReportPartialResults = true
          request.requiresOnDeviceRecognition = false

          let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))!
          let speechRecognizerDelegate = SpeechRecognizerDelegate(
            availabilityDidChange: { available in
              subscriber.send(.availabilityDidChange(isAvailable: available))
            }
          )
          speechRecognizer.delegate = speechRecognizerDelegate

          let cancellable = AnyCancellable {
            audioEngine?.stop()
            inputNode?.removeTap(onBus: 0)
            recognitionTask?.cancel()
            _ = speechRecognizer
            _ = speechRecognizerDelegate
          }

          audioEngine = AVAudioEngine()
          let audioSession = AVAudioSession.sharedInstance()
          do {
            try audioSession.setCategory(
              .record,
              mode: .measurement,
              options: .duckOthers
            )
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
          } catch {
            subscriber.send(completion: .failure(.couldntConfigureAudioSession))
            return cancellable
          }
          inputNode = audioEngine!.inputNode

          recognitionTask = speechRecognizer
            .recognitionTask(with: request) { result, error in
              switch (result, error) {
              case let (.some(result), _):
                subscriber.send(.taskResult(SpeechRecognitionResult(result)))
              case (_, .some):
                subscriber.send(completion: .failure(.taskError))
              case (.none, .none):
                fatalError(
                  "It should not be possible to have both a nil result and nil error."
                )
              }
            }

          inputNode!.installTap(
            onBus: 0,
            bufferSize: 1024,
            format: inputNode!.outputFormat(forBus: 0)
          ) { buffer, _ in
            request.append(buffer)
          }

          audioEngine!.prepare()
          do {
            try audioEngine!.start()
          } catch {
            subscriber.send(completion: .failure(.couldntStartAudioEngine))
            return cancellable
          }

          return cancellable
        }
      }, finishTask: {
        .fireAndForget {
          request.endAudio()
          audioEngine?.stop()
          inputNode?.removeTap(onBus: 0)
          recognitionTask?.finish()
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
