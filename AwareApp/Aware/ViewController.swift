//
//  ViewController.swift
//  Aware
//
//  Created by Shusil Shapkota on 2020-01-19.
//  Copyright © 2020 Shusil. All rights reserved.
//

import UIKit
import AVKit
import Vision
import Speech
import AVFoundation
import MediaPlayer

class ViewController: UIViewController, SFSpeechRecognizerDelegate, AVCaptureVideoDataOutputSampleBufferDelegate {
    @IBOutlet var dictationButton: UIButton!
    
    var objectInFront = "wall"
    var obj = "wall"
    
    let audioEngine = AVAudioEngine()
    let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))!
    
    var request: SFSpeechAudioBufferRecognitionRequest?
    var task: SFSpeechRecognitionTask?
    
    let identifierLabel: UILabel = {
        let label = UILabel()
        label.backgroundColor = .orange
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        dictationButton.isEnabled = false
        speechRecognizer.delegate = self
        
        SFSpeechRecognizer.requestAuthorization { (status) in
            OperationQueue.main.addOperation {
                switch status {
                case .authorized: self.dictationButton.isEnabled = true
                default: self.dictationButton.isEnabled = false
                }
            }
        }
        
        // Now we start the camera
        let captureSession = AVCaptureSession()
        captureSession.sessionPreset = .photo
        
        guard let captureDevice = AVCaptureDevice.default(for: .video) else { return }
        guard let input = try? AVCaptureDeviceInput(device: captureDevice) else { return }
        captureSession.addInput(input)
        
        captureSession.startRunning()
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        view.layer.addSublayer(previewLayer)
        previewLayer.frame = view.frame
        
        let dataOutput = AVCaptureVideoDataOutput()
        dataOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
        captureSession.addOutput(dataOutput)
        
        setupIdentifierConfidenceLabel()
    }
    
    func startDictation(){
        task?.cancel()
        task = nil
        
        // Initializes the request variable
        request = SFSpeechAudioBufferRecognitionRequest()
        
        // Assigns the shared audio session instance to a constant
        let audioSession = AVAudioSession.sharedInstance()
        
        // Assigns the input node of the audio engine to a constant
        let inputNode = audioEngine.inputNode
        
        // If possible, the request variable is unwrapped and assigned to a local constant
        guard let request = request else { return }
        request.shouldReportPartialResults = true
        
        // Attempts to set various attributes and returns nil if fails
        try? audioSession.setCategory(AVAudioSession.Category.playAndRecord)
        try? audioSession.setMode(AVAudioSession.Mode.measurement)
        //        try? audioSession.setActive(true, withFlags: .notifyOthersOnDeactivation)
        
        // Initializes the task with a recognition task
        task = speechRecognizer.recognitionTask(with: request, resultHandler: { (result, error) in guard let result = result else { return }
            print(result.bestTranscription.formattedString)
            if error != nil || result.isFinal {
                self.audioEngine.stop()
                self.request = nil
                self.task = nil
                
                inputNode.removeTap(onBus: 0)
            }
        })
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer, when) in self.request?.append(buffer)}
        
        audioEngine.prepare()
        try? audioEngine.start()
    }
    
    func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        if available {
            dictationButton.isEnabled = true
        } else {
            dictationButton.isEnabled = false
        }
    }
    
    @IBAction func dictationButtonTapped() {
        if audioEngine.isRunning {
            dictationButton.setTitle("Start Recording", for: .normal)
            objectInFront = obj
            print(objectInFront)
            announce(myText: "I think I see " + objectInFront, myLang: "en_US")
            request?.endAudio()
            audioEngine.stop()
        }else{
            dictationButton.setTitle("Stop Recording", for: .normal)
            startDictation()
        }
    }
    
    fileprivate func setupIdentifierConfidenceLabel() {
        view.addSubview(identifierLabel)
        identifierLabel.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -32).isActive = true
        identifierLabel.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        identifierLabel.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        identifierLabel.heightAnchor.constraint(equalToConstant: 50).isActive = true
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        guard let pixelBuffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        // Here we use the model
        guard let model = try? VNCoreMLModel(for: Resnet50().model) else { return }
        let request = VNCoreMLRequest(model: model) { (finishedReq, err) in
            
            guard let results = finishedReq.results as? [VNClassificationObservation] else { return }
            
            guard let firstObservation = results.first else { return }
            
            self.obj = firstObservation.identifier
            
            DispatchQueue.main.async {
                self.identifierLabel.text = "\(firstObservation.identifier) \(firstObservation.confidence * 100)"
            }
        }
        try? VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:]).perform([request])
    }
    
    func announce(myText :String , myLang : String ) {
        let volumeView = MPVolumeView()
        if let view = volumeView.subviews.first as? UISlider
        {
            view.value = 1.0   
        }
        
        let audioSession = AVAudioSession.sharedInstance()
        try? audioSession.setCategory(AVAudioSession.Category.playback)
        
        let uttrace = AVSpeechUtterance(string: myText )
        uttrace.voice = AVSpeechSynthesisVoice(language: myLang)
        
        let synthesizer = AVSpeechSynthesizer()
        synthesizer.speak(uttrace)
    }
    
}

