import Combine
import ComposableArchitecture
import Speech

struct SpeechClient {
  var requestAuthorization: () -> Effect<SpeechRecognitionAuthorizationResult, Never>
  var recognitionTask: () -> Effect<Action, Error>
  var finishTask: () -> Effect<Never, Never>

  enum Action: Equatable {
    case availabilityDidChange(isAvailable: Bool)
    case taskResult(SpeechRecognitionResult)
  }

  enum Error: Swift.Error, Equatable {
    case taskError
    case couldntStartAudioEngine
    case couldntConfigureAudioSession
  }
}
