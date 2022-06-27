import Speech

// The core data types in the Speech framework are reference types and are not constructible by us,
// and so they aren't super testable out the box. We define struct versions of those types to make
// them easier to use and test.
//
// These are organized from top to bottom in terms of general relevance to an average consumer of
// this codebase.

// The Transcription is the overall recognition of all spoken language and other data that may
// be provided. A Transcription contains a list of Sections, which in turn contain a list of
// Chunks, which in turn contain a list of Words.
struct Transcription: Equatable {
  var sections: [Section]
}

struct SpeechRecognitionResult: Equatable {
  var words: [Word]
  var punctuatedSentence: String
  // TODO what does is final mean? Why would this ever be coming from a result?
//  var isFinal: Bool
//  var speechRecognitionMetadata: SpeechRecognitionMetadata?
//  var transcriptions: [Transcription]
}

struct Section: Equatable, Identifiable {
  let id = UUID()
  var start: Float16
  var chunks: [Chunk] = []
}

struct Chunk: Equatable, Identifiable {
  let id = UUID()
  var start: Float16
  var end: Float16
  var words: [Word]
}

struct Word: Equatable, Identifiable {
  let id = UUID()
  var start: Float16
  var end: Float16
  var text: String
}

struct TranscriptionSegment: Equatable {
  var alternativeSubstrings: [String]
  var confidence: Float
  var duration: TimeInterval
  var substring: String
  var substringRange: NSRange
  var timestamp: TimeInterval
}

struct VoiceAnalytics: Equatable {
  var jitter: AcousticFeature
  var pitch: AcousticFeature
  var shimmer: AcousticFeature
  var voicing: AcousticFeature
}

struct AcousticFeature: Equatable {
  var acousticFeatureValuePerFrame: [Double]
  var frameDuration: TimeInterval
}

extension SpeechRecognitionMetadata {
  init(_ speechRecognitionMetadata: SFSpeechRecognitionMetadata) {
    averagePauseDuration = speechRecognitionMetadata.averagePauseDuration
    speakingRate = speechRecognitionMetadata.speakingRate
    voiceAnalytics = speechRecognitionMetadata.voiceAnalytics.map(VoiceAnalytics.init)
  }
}

struct SpeechRecognitionMetadata: Equatable {
  var averagePauseDuration: TimeInterval
  var speakingRate: Double
  var voiceAnalytics: VoiceAnalytics?
}

enum SpeechRecognizerAuthorizationStatus: Int, Equatable {
  case notDetermined = 0
  case denied = 1
  case restricted = 2
  case authorized = 3
  /**
   * TODO handle all cases
   * incorrect keys
   * expired
   */
}

extension SFSpeechRecognizerAuthorizationStatus {
  var toSpeechRecognizerAuthorizationStatus: SpeechRecognizerAuthorizationStatus {
    SpeechRecognizerAuthorizationStatus(rawValue: rawValue) ?? .notDetermined
  }
}

struct SpeechRecognitionAuthorizationResult: Equatable {
  let status: SpeechRecognizerAuthorizationStatus
  var token: String? = nil
  var expiresAt: Date? = nil

  init(status: SpeechRecognizerAuthorizationStatus) {
    self.status = status
  }

  init(status: SpeechRecognizerAuthorizationStatus, token: String, expiresAt: Date) {
    self.status = status
    self.token = token
    self.expiresAt = expiresAt
  }
}

extension SpeechRecognitionAuthorizationResult {
  static let uninitiated = SpeechRecognitionAuthorizationResult(
    status: .notDetermined
  )
}

//extension Transcription {
//  init(_ transcription: SFTranscription) {
//    words = transcription.segments.map({ segment in
//      return Word(start: segment.timestamp, end: segment.timestamp + segment.duration, text: segment.substring)
//    })
//
//  }
//}

extension SpeechRecognitionResult {
  init(_ speechRecognitionResult: SFSpeechRecognitionResult) {
    
    words = speechRecognitionResult.bestTranscription.segments.map({ segment in
      return Word(
        start: Float16(segment.timestamp),
        end: Float16(segment.timestamp + segment.duration),
        text: segment.substring
      )
    })
    
    punctuatedSentence = ""
//    punctuatedSentence =
//    bestTranscription = Transcription(speechRecognitionResult.bestTranscription)
//    isFinal = speechRecognitionResult.isFinal
//    speechRecognitionMetadata = speechRecognitionResult.speechRecognitionMetadata
//      .map(SpeechRecognitionMetadata.init)
//    transcriptions = speechRecognitionResult.transcriptions.map(Transcription.init)
  }
}

extension SpeechRecognitionResult {
  init(_ deepgramResponse: DeepgramResponse) {
    words = deepgramResponse.channel.alternatives.first!.words.map({ deepgramWord in
      return Word(start: deepgramWord.start, end: deepgramWord.end, text: deepgramWord.punctuatedWord ?? deepgramWord.word)
    })
    
    punctuatedSentence = deepgramResponse.channel.alternatives.first!.transcript
    print(punctuatedSentence)
    
  }
}

//extension Transcription {
//  init(_ transcription: SFTranscription) {
//    words = transcription.segments.map({ segment in
//      return Word(start: segment.timestamp, end: segment.timestamp + segment.duration, text: segment.substring)
//    })
//
//  }
//}

extension TranscriptionSegment {
  init(_ transcriptionSegment: SFTranscriptionSegment) {
    alternativeSubstrings = transcriptionSegment.alternativeSubstrings
    confidence = transcriptionSegment.confidence
    duration = transcriptionSegment.duration
    substring = transcriptionSegment.substring
    substringRange = transcriptionSegment.substringRange
    timestamp = transcriptionSegment.timestamp
  }
}

extension VoiceAnalytics {
  init(_ voiceAnalytics: SFVoiceAnalytics) {
    jitter = AcousticFeature(voiceAnalytics.jitter)
    pitch = AcousticFeature(voiceAnalytics.pitch)
    shimmer = AcousticFeature(voiceAnalytics.shimmer)
    voicing = AcousticFeature(voiceAnalytics.voicing)
  }
}

extension AcousticFeature {
  init(_ acousticFeature: SFAcousticFeature) {
    acousticFeatureValuePerFrame = acousticFeature.acousticFeatureValuePerFrame
    frameDuration = acousticFeature.frameDuration
  }
}
