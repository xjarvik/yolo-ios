//
//  ViewController.swift
//  yolo-ios
//
//  Created by William Söder on 2021-04-09.
//

import UIKit

class ViewController: UIViewController {
    @IBOutlet weak var trainButton: UIButton!
    @IBOutlet weak var trainSpinner: UIActivityIndicatorView!
    @IBOutlet weak var elapsedLabel: UILabel!
    
    var elapsed = 0
    var timer: Timer? = nil
    
    func startTimer(){
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            self.elapsed += 1
            
            let hours: Int = self.elapsed / 3600
            let minutes: Int = (self.elapsed % 3600) / 60
            let seconds: Int = (self.elapsed % 60)
            
            self.elapsedLabel.text = String(hours) + "h " + String (minutes) + "m " + String(seconds) + "s elapsed"
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    func createObjDataFile() -> String{
        var stringToSave = "classes = 2\n"
        
        let trainPath = FileManager.default.urls(for: .documentDirectory,
                                                  in: .userDomainMask)[0].appendingPathComponent("train.txt")
        
        stringToSave += "train = " + trainPath.absoluteString.replacingOccurrences(of: "file://", with: "") + "\n"
        
        let testPath = FileManager.default.urls(for: .documentDirectory,
                                             in: .userDomainMask)[0].appendingPathComponent("test.txt")
        
        stringToSave += "valid = " + testPath.absoluteString.replacingOccurrences(of: "file://", with: "") + "\n"
        
        let namesPath = Bundle.main.path(forResource: "obj", ofType: "names")
        
        stringToSave += "names = " + namesPath!.replacingOccurrences(of: "file://", with: "") + "\n"
        
        var isDir:ObjCBool = true
        
        let backupPath = FileManager.default.urls(for: .documentDirectory,
                                                in: .userDomainMask)[0].appendingPathComponent("backup")
        
        if !FileManager.default.fileExists(atPath: backupPath.path, isDirectory: &isDir) {
            do {
                try FileManager.default.createDirectory(atPath: backupPath.path, withIntermediateDirectories: true, attributes: nil)
            } catch {
                print(error.localizedDescription)
            }
        }
        
        stringToSave += "backup = " + backupPath.path
        
        let path = FileManager.default.urls(for: .documentDirectory,
                                            in: .userDomainMask)[0].appendingPathComponent("obj.data")

        if let stringData = stringToSave.data(using: .utf8) {
            try? stringData.write(to: path)
        }
        
        return path.absoluteString.replacingOccurrences(of: "file://", with: "")
    }
    
    func createTrainAndTestFiles(){
        var count = 0
        var test = ""
        var train = ""
        
        let fm = FileManager.default
        let path = Bundle.main.resourcePath! + "/deepfake-dataset5/"

        do {
            let items = try fm.contentsOfDirectory(atPath: path)

            for item in items {
                if(item.hasSuffix(".jpg") || item.hasSuffix(".png")){
                    count += 1
                    if(count == 10){
                        count = 0
                        test += path + item + "\n"
                    }
                    else{
                        train += path + item + "\n"
                    }
                }
            }
        } catch {
            // failed to read directory – bad permissions, perhaps?
        }
        
        let testPath = FileManager.default.urls(for: .documentDirectory,
                                            in: .userDomainMask)[0].appendingPathComponent("test.txt")

        if let stringData = test.data(using: .utf8) {
            try? stringData.write(to: testPath)
        }
        
        let trainPath = FileManager.default.urls(for: .documentDirectory,
                                            in: .userDomainMask)[0].appendingPathComponent("train.txt")

        if let stringData = train.data(using: .utf8) {
            try? stringData.write(to: trainPath)
        }
    }
    
    func makeCString(from str: String) -> UnsafeMutablePointer<Int8> {
        let count = str.utf8.count + 1
        let result = UnsafeMutablePointer<Int8>.allocate(capacity: count)
        str.withCString { (baseAddress) in
            // func initialize(from: UnsafePointer<Pointee>, count: Int)
            result.initialize(from: baseAddress, count: count)
        }
        return result
    }
    
    @IBAction func trainButtonPressed() {
        elapsed = 0
        startTimer()
        
        trainButton.isEnabled = false
        trainButton.setTitleColor(UIColor(red: 0, green: 0, blue: 0, alpha: 0.5), for: .disabled)
        trainButton.setTitle("Training...", for: .disabled)
        
        trainSpinner.isHidden = false
        
        createTrainAndTestFiles()
        
        let objDataFilePath = createObjDataFile()
        let cfgPath = Bundle.main.path(forResource: "yolov2", ofType: "cfg")!
        let weightsPath = Bundle.main.path(forResource: "darknet19_448.conv", ofType:"23")!
        var zero: Int32 = 0
        
        DispatchQueue.background(background:{
            train_detector(
                self.makeCString(from: objDataFilePath),
                self.makeCString(from: cfgPath),
                self.makeCString(from: weightsPath),
                &zero, 1, 0
            )
        }, completion:{
            self.trainButton.isEnabled = true
            self.trainSpinner.isHidden = true
            self.timer?.invalidate()
        })
    }
}

extension DispatchQueue {
    static func background(delay: Double = 0.0, background: (()->Void)? = nil, completion: (() -> Void)? = nil) {
        DispatchQueue.global(qos: .default).async {
            background?()
            if let completion = completion {
                DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: {
                    completion()
                })
            }
        }
    }
}
