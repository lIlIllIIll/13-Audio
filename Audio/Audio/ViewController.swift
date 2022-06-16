//
//  ViewController.swift
//  Audio
//
//  Created by 203a on 2022/05/20.
//

import UIKit
import AVFoundation  // 오디오 재생을 위한 상수와 변수 추가 ( AVAudioPlayerDelegate )

class ViewController: UIViewController, AVAudioPlayerDelegate, AVAudioRecorderDelegate {
    
    var audioPlayer : AVAudioPlayer! // AVAudioPlayer 인스턴스 변수
    var audioFile : URL!        // 재생할 오디오의 파일명 변수
    
    let MAX_VOLUME : Float = 10.0       // 최대 볼륨, 실수형 변수
    
    var progressTimer : Timer!          // 타이머를 위한 변수
    
    let timePlayerSelector:Selector = #selector(ViewController.updatePlayTime) // 재생 타이머를 위한 변수
    let timeRecordSelector:Selector = #selector(ViewController.updateRecordTime) // 녹음 타이머를 위한 변수
    @IBOutlet var pvProgressPlay: UIProgressView!
    @IBOutlet var lblCurrentTime: UILabel!
    @IBOutlet var lblendTime: UILabel!
    @IBOutlet var btnPlay: UIButton!
    @IBOutlet var btnPause: UIButton!
    @IBOutlet var btnStop: UIButton!
    @IBOutlet var slVolume: UISlider!
    
    @IBOutlet var btnRecord: UIButton!
    @IBOutlet var lblRecordTime: UILabel!
    
    var audioRecorder : AVAudioRecorder!
    var isRecordMode = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        selectAudioFile()
        if !isRecordMode { // 재생 모드일 때
            initPlay()
            btnRecord.isEnabled = false
            lblRecordTime.isEnabled = false
        } else {
            initRecord() // 녹음 모드일 때
        }

    }
    
    func selectAudioFile() {    // 재생 모드일 때는 오디오파일 선택, 녹음 모드일 때는 새 파일인 recordFile 생성
        if !isRecordMode {
            audioFile = Bundle.main.url(forResource: "Sicilian_Breeze", withExtension: "mp3")
        } else {
            let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask) [0]
            audioFile = documentDirectory.appendingPathComponent("recordFile.m4a")
        }
    }
    
    func initRecord() { // 녹음 모드 초기화
        let recordSettings = [
            AVFormatIDKey : NSNumber(value: kAudioFormatAppleLossless as UInt32),
            AVEncoderAudioQualityKey : AVAudioQuality.max.rawValue,
            AVEncoderBitRateKey : 320000,
            AVNumberOfChannelsKey :2,
            AVSampleRateKey : 44100.0] as [String : Any]
        do{
            audioRecorder = try AVAudioRecorder(url: audioFile, settings: recordSettings)
        } catch let error as NSError {
            print("Error-initRecord : \(error)")
        }
        
        audioRecorder.delegate = self
        slVolume.value = 1.0
        audioPlayer.volume = slVolume.value
        lblendTime.text = converNSTimeInterval2String(0)
        lblCurrentTime.text = converNSTimeInterval2String(0)
        setPlayButtons(play: false, pause: false, stop: false)
        let session = AVAudioSession.sharedInstance()
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch let error as NSError {
            print("Error-setCategory: \(error)")
        }
        do {
            try session.setActive(true)
        } catch let error as NSError {
            print("Error-setActive : \(error)")
        }
    }
    
    func initPlay() {       // 오디오 재생을 위한 초기화(재생 초기화와 녹음 초기화 분리)
        do{             // 입력 파라미터인 오디오 파일이 없을 때를 대비하여 do-try-catch문을 사용
            audioPlayer = try AVAudioPlayer(contentsOf: audioFile)
        } catch let error as NSError{
            print("Error-initPlay : \(error)")
        }
        slVolume.maximumValue = MAX_VOLUME  // 슬라이더의 최대 볼륨을 상수 MAX_VOLUME인 1.0으로 초기화
        slVolume.value = 1.0        // 슬라이더의 볼륨을 1.0으로 초기화
        pvProgressPlay.progress = 0     // 프로그레스 뷰의 진행을 0으로 초기화
        
        audioPlayer.delegate = self     // 오디오플레이어의 델리게이트를 셀프로 함
        audioPlayer.prepareToPlay()     // prepareToPlay()를 실행
        audioPlayer.volume = slVolume.value     // 오디오 플레이어의 불륨을 방금 앞에서 초기화한 슬라이더의 불륨 값 1.0으로 초기화
        
        lblendTime.text = converNSTimeInterval2String(audioPlayer.duration)
        lblCurrentTime.text = converNSTimeInterval2String(0)
        btnPlay.isEnabled = true
        btnPause.isEnabled = false
        btnStop.isEnabled = false
        /* setPlayButtons(play: true, pause: false, stop: false)로 대체 가능 */
    }
    
    func setPlayButtons(play:Bool, pause:Bool, stop:Bool) {
        btnPlay.isEnabled = play
        btnPause.isEnabled = pause
        btnStop.isEnabled = stop
    }
    
    func converNSTimeInterval2String(_ time: TimeInterval) -> String {//00:00형태의 문자열로 변환
        let min = Int(time/60)
        let sec = Int(time.truncatingRemainder(dividingBy: 60))
        let strTime = String(format: "%02d:%02d", min, sec)
        return strTime
    }

    @IBAction func btnPlayAudio(_ sender: UIButton) {   // 오디오 재생
        audioPlayer.play()
        setPlayButtons(play: false, pause: true, stop: true)
        progressTimer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: timePlayerSelector, userInfo: nil, repeats: true)
    }
    
    @objc func updatePlayTime() { // 0.1초마다 호출되어 재생 시간을 표시
        lblCurrentTime.text = converNSTimeInterval2String(audioPlayer.currentTime)
        pvProgressPlay.progress = Float(audioPlayer.currentTime/audioPlayer.duration)
    }

    @IBAction func btnPauseAudio(_ sender: UIButton) {      // 오디오 일시정지
        audioPlayer.pause()
        setPlayButtons(play: true, pause: false, stop: true)
    }
    
    @IBAction func btnStopAudio(_ sender: UIButton) {       // 오디오 정지
        audioPlayer.stop()
        audioPlayer.currentTime = 0
        lblCurrentTime.text = converNSTimeInterval2String(0)
        setPlayButtons(play: true, pause: false, stop: false)
        progressTimer.invalidate()
    }
    @IBAction func slChangeVolume(_ sender: UISlider) {
        audioPlayer.volume = slVolume.value
    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        progressTimer.invalidate()
        setPlayButtons(play: true, pause: false, stop: false)
    }
    
    @IBAction func swRecordMode(_ sender: UISwitch) { // 녹음 모드 / 재생 모드로 전환
        if sender.isOn {
            audioPlayer.stop()
            audioPlayer.currentTime = 0
            lblRecordTime!.text = converNSTimeInterval2String(0)
            isRecordMode = true
            btnRecord.isEnabled = true
            lblRecordTime.isEnabled = true
        } else {
            isRecordMode = false
            btnRecord.isEnabled = false
            lblRecordTime.isEnabled = false
            lblRecordTime.text = converNSTimeInterval2String(0)
        }
        selectAudioFile()
        if !isRecordMode {
            initPlay()
        } else {
            initRecord()
        }
    }
    @IBAction func btnRecord(_ sender: UIButton) {
        if (sender as AnyObject).titleLabel?.text == "Record" {
            audioRecorder.record()
            setPlayButtons(play: false, pause: false, stop: false)
            (sender as AnyObject).setTitle("Stop", for: UIControl.State())
            progressTimer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: timeRecordSelector, userInfo: nil, repeats: true)
        } else {
            audioRecorder.stop()
            progressTimer.invalidate()
            (sender as AnyObject).setTitle("Record", for: UIControl.State())
            btnPlay.isEnabled = true
            initPlay()
            setPlayButtons(play: false, pause: false, stop: false) // 녹음을 시작한 후 정지를 하면 Play 버튼이 활성화되는 오류가 있었는데 setPlayButtons(play: false, pause: false, stop: false) 를 뒤에 두어 비활성화 하였다.

        }
    }
    
    @objc func updateRecordTime() { //0.1초마다 호출되어 녹음 시간을 표시
        lblRecordTime.text = converNSTimeInterval2String(audioRecorder.currentTime)
    }

}

