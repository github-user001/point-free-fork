import Combine
import ComposableArchitecture
import Speech

#if DEBUG
  extension SpeechClient {
    static let failing = Self(
      finishTask: { .failing("SpeechClient.finishTask") },
      recognitionTask: { .failing("SpeechClient.recognitionTask") },
      requestAuthorization: { .failing("SpeechClient.requestAuthorization") }
    )
  }
#endif
