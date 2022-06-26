import Combine
import ComposableArchitecture
import Speech
import SwiftUI

private let readMe = """
This application demonstrates how to work with a complex dependency in the Composable \
Architecture. It uses the SFSpeechRecognizer API from the Speech framework to listen to audio on \
the device and live-transcribe it to the UI.
"""

struct AppState: Equatable {
  var alert: AlertState<AppAction>?
  var isRecording = false
  var speechRecognizerAuthorization: SpeechRecognitionAuthorizationResult = .uninitiated
//  var transcribedText = ""
  var transcript: Transcription  = Transcription(
    sections: [
      Section(start: 0.0, chunks: [])
    ])
}

enum AppAction: Equatable {
  case dismissAuthorizationStateAlert
  case recordButtonTapped
  case speech(Result<SpeechClient.Action, SpeechClient.Error>)
  case speechRecognizerAuthorizationStatusResponse(SpeechRecognitionAuthorizationResult)
}

struct AppEnvironment {
  var mainQueue: AnySchedulerOf<DispatchQueue>
  var speechClient: SpeechClient
}

let appReducer = Reducer<
  AppState,
  AppAction,
  AppEnvironment
> { state, action, environment in
  switch action {
  case .dismissAuthorizationStateAlert:
    state.alert = nil
    return .none

  case .speech(.failure(.couldntConfigureAudioSession)),
       .speech(.failure(.couldntStartAudioEngine)):
    state.alert = .init(title: .init("Problem with audio device. Please try again."))
    return .none

  case .recordButtonTapped:
    state.isRecording.toggle()
    if state.isRecording {
      return environment.speechClient.requestAuthorization()
        .receive(on: environment.mainQueue)
        .map(AppAction.speechRecognizerAuthorizationStatusResponse)
        .eraseToEffect()
    } else {
      return environment.speechClient.finishTask()
        .fireAndForget()
    }

  case let .speech(.success(.availabilityDidChange(isAvailable))):
    return .none

  case let .speech(.success(.taskResult(result))):
    let currentSection = state.transcript.sections.last!
    
    let previousEnd = currentSection.chunks.last?.words.last?.end ?? 0
    let newBeginning = result.words.first!.start
    
    let pauseTime = newBeginning - previousEnd
    print("Pause time is \(pauseTime)")
    
    let sectionPauseThreshold = Float16(3.0)
    
    if pauseTime > sectionPauseThreshold {
      state.transcript.sections.append(Section(start:newBeginning))
    }
    
//    let newSection = Section(start: result.words.first!.start, chunks: result.words)
    state.transcript.sections[state.transcript.sections.count - 1].chunks.append(
      Chunk(
        start: result.words.first!.start,
        end: result.words.last!.end,
        words: result.words
      ))
    
//    if result.isFinal {
//      return environment.speechClient.finishTask()
//        .fireAndForget()
//    } else {
      return .none
//    }

  case let .speech(.failure(error)):
    state
      .alert =
      .init(title: .init("An error occured while transcribing. Please try again."))
    return environment.speechClient.finishTask()
      .fireAndForget()

  case let .speechRecognizerAuthorizationStatusResponse(result):
    let status = result.status

    state.isRecording = status == .authorized
    state.speechRecognizerAuthorization = result

    switch status {
    case .notDetermined:
      state.alert = .init(title: .init("Try again."))
      return .none

    case .denied:
      state.alert = .init(
        title: .init(
          """
          You denied access to speech recognition. This app needs access to transcribe your speech.
          """
        )
      )
      return .none

    case .restricted:
      state.alert = .init(title: .init("Your device does not allow speech recognition."))
      return .none

    case .authorized:
      return environment.speechClient
        .recognitionTask(state.speechRecognizerAuthorization.token)
        .catchToEffect(AppAction.speech)

    @unknown default:
      return .none
    }
  }
}
.debug(actionFormat: .labelsOnly)

struct AuthorizationStateAlert: Equatable, Identifiable {
  var title: String

  var id: String { title }
}

struct SpeechRecognitionView: View {
  let store: Store<AppState, AppAction>

  var body: some View {
    WithViewStore(store) { viewStore in
      VStack {
        VStack(alignment: .leading) {
          Text(readMe)
            .padding(.bottom, 32)

//          Text(viewStore.transcript.sections.first!.chun)
//            .font(.largeTitle)
//            .minimumScaleFactor(0.1)
//            .frame(minHeight: 0, maxHeight: .infinity, alignment: .topLeading)
        }

        Spacer()
        
        ScrollView {
          ForEach(viewStore.transcript.sections) { section in
//            Text(section.chunks.first?.words.first?.text ?? "no text yet")
            VStack {
              Text(section.id.description).font(.title)
              ForEach(section.chunks) {chunk in
                HStack {
                  ForEach(chunk.words) { word in
                    Text(word.text).onTapGesture {
                      print(word.text)
                      print(word.start)
                    }
                  }
                }
              }
              Spacer()
            }
          }
        }

        Button(action: { viewStore.send(.recordButtonTapped) }) {
          HStack {
            Image(
              systemName: viewStore.isRecording
                ? "stop.circle.fill" : "arrowtriangle.right.circle.fill"
            )
            .font(.title)
            Text(viewStore.isRecording ? "Stop Recording" : "Start Recording")
          }
          .foregroundColor(.white)
          .padding()
          .background(viewStore.isRecording ? Color.red : .green)
          .cornerRadius(16)
        }
      }.onAppear {
        viewStore.send(.recordButtonTapped)
      }
      .padding()
      .alert(store.scope(state: \.alert), dismiss: .dismissAuthorizationStateAlert)
    }
  }
}

struct SpeechRecognitionView_Previews: PreviewProvider {
  static var previews: some View {
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
  }
}
