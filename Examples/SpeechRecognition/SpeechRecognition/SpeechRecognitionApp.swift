import ComposableArchitecture
import SwiftUI

@main
struct SpeechRecognitionApp: App {
  var body: some Scene {
    WindowGroup {
      HStack{
        
      SpeechRecognitionView(
        store: Store(
          initialState: .init(),
          reducer: appReducer,
          environment: AppEnvironment(
            mainQueue: .main,
            speechClient: .apple
          )
        )
      )
    
      SpeechRecognitionView(
        store: Store(
          initialState: .init(),
          reducer: appReducer,
          environment: AppEnvironment(
            mainQueue: .main,
            speechClient: .deepgram
          )
        )
      )
    
      }
    }
  }
}
