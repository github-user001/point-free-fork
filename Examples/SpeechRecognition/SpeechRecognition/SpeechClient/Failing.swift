import Combine
import ComposableArchitecture
import Speech

#if DEBUG
  extension SpeechClient {
    static let failing = Self(
      requestAuthorization: { .failing("SpeechClient.requestAuthorization") },
      recognitionTask: { .failing("SpeechClient.recognitionTask") },
      finishTask: { .failing("SpeechClient.finishTask") }
    )
  }
#endif
