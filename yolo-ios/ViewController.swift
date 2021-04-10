//
//  ViewController.swift
//  yolo-ios
//
//  Created by William Söder on 2021-04-09.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        createTrainAndTestFiles()
        
        let objDataFilePath = createObjDataFile()
        let cfgPath = Bundle.main.path(forResource: "yolov2", ofType: "cfg")!
        let weightsPath = Bundle.main.path(forResource: "darknet19_448.conv", ofType:"23")!
        var zero: Int32 = 0
        
        train_detector(
            makeCString(from: objDataFilePath),
            makeCString(from: cfgPath),
            makeCString(from: weightsPath),
            &zero, 1, 0
        )
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
}

