//
// Copyright 2014 ESRI
//
// All rights reserved under the copyright laws of the United States
// and applicable international laws, treaties, and conventions.
//
// You may freely redistribute and use this sample code, with or
// without modification, provided you include the original copyright
// notice and use restrictions.
//
// See the use restrictions at http://help.arcgis.com/en/sdk/10.0/usageRestrictions.htm
//

import UIKit
import ArcGIS

class ViewController: UIViewController, AGSLayerDelegate {
    
    @IBOutlet weak var mapView:AGSMapView!
    @IBOutlet weak var downloadPanel:UIView!
    @IBOutlet weak var scaleLabel:UILabel!
    @IBOutlet  var estimateLabel:UILabel!
    @IBOutlet weak var lodLabel:UILabel!
    @IBOutlet weak var estimateButton:UIButton!
    @IBOutlet weak var downloadButton:UIButton!
    @IBOutlet weak var levelStepper:UIStepper!
    @IBOutlet weak var timerLabel:UILabel!
    
    var tileCacheTask:AGSExportTileCacheTask!
    var tiledLayer:AGSTiledMapServiceLayer!
    
    // in iOS7 this gets called and hides the status bar so the view does not go under the top iPhone status bar
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //You can change this to any other service on tiledbasemaps.arcgis.com if you have an ArcGIS for Organizations subscription
        let tileServiceURL = "http://sampleserver6.arcgisonline.com/arcgis/rest/services/World_Street_Map/MapServer"
        
        //Add basemap layer to the map
        //Set delegate to be notified of success or failure while loading
        let tiledUrl = NSURL(string: tileServiceURL)
        self.tiledLayer = AGSTiledMapServiceLayer(URL: tiledUrl)
        self.tiledLayer.delegate  = self
        self.mapView.addMapLayer(self.tiledLayer, withName:"World Street Map")
        
        
        // Init the tile cache task
        if self.tileCacheTask == nil {
            self.tileCacheTask = AGSExportTileCacheTask(URL: tiledUrl)
        }
        
        self.scaleLabel.numberOfLines = 0
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    //MARK: - AGSLayer delegate
    
    func layer(layer: AGSLayer!, didFailToLoadWithError error: NSError!) {
        //Alert user of error
        UIAlertView(title: "Error", message: error.localizedDescription, delegate: nil, cancelButtonTitle: nil).show()
    }
    
    func layerDidLoad(layer: AGSLayer!) {
        if layer == self.tiledLayer {
            //Initialize UIStepper based on number of scale levels in the tiled layer
            self.levelStepper.value = 0
            self.levelStepper.minimumValue = 0
            self.levelStepper.maximumValue = Double(self.tiledLayer.tileInfo.lods.count-1)
            
            //Register observer for mapScale property so we can reset the stepper and other UI when map is zoomed in/out
            self.mapView.addObserver(self, forKeyPath: "mapScale", options: .New, context: nil)
        }
    }
    
    //MARK: - KVO
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        //Clear out any estimate or previously chosen levels by the user
        //They are no longer relevant as the map's scale has changed
        //Disable buttons to force the user to specify levels again
        self.estimateLabel.text = ""
        self.scaleLabel.text = ""
        self.lodLabel.text = ""
        self.estimateButton.enabled = false
        self.downloadButton.enabled = false
        
        
        //Re-initialize the stepper with possible values based on current map scale
        if self.tiledLayer.currentLOD() != nil {
            let lods = self.tiledLayer.mapServiceInfo.tileInfo.lods as! [AGSLOD]
            
            if let index = lods.indexOf(self.tiledLayer.currentLOD()) {
                self.levelStepper.maximumValue = Double(self.tiledLayer.tileInfo.lods.count - index)
                self.levelStepper.minimumValue = 0
                self.levelStepper.value = 0
            }
        }
    }
    
    
    @IBAction func changeLevels(sender:AnyObject) {

        //Enable buttons because the user has specified how many levels to download
        self.estimateButton.enabled = true
        self.downloadButton.enabled = true
        self.levelStepper.minimumValue = 1
        
        //Display the levels
        self.lodLabel.text = "\(Int(self.levelStepper.value))"
        
        //Display the scale range that will be downloaded based on specified levels
        let currentScale = "\(Int(self.tiledLayer.currentLOD().scale))"
        let maxLOD = self.tiledLayer.mapServiceInfo.tileInfo.lods[Int(self.levelStepper.value)] as! AGSLOD
        let maxScale = "\(Int(maxLOD.scale))"
        self.scaleLabel.text = String(format: "1:%@\n\tto\n1:%@",currentScale , maxScale)
    }
    
    @IBAction func estimateAction(sender:AnyObject) {
        
        //Prepare list of levels to download
        let desiredLevels = self.levelsWithCount(Int(self.levelStepper.value), startingAt:self.tiledLayer.currentLOD(), fromLODs:self.tiledLayer.tileInfo.lods as! [AGSLOD])
        print("LODs requested \(desiredLevels)")
        
        //Use current envelope to download
        let extent = self.mapView.visibleAreaEnvelope
        
        //Prepare params with levels and envelope
        let params = AGSExportTileCacheParams(levelsOfDetail: desiredLevels, areaOfInterest:extent)
        
        //kick-off operation to estimate size
        self.tileCacheTask.estimateTileCacheSizeWithParameters(params, status: { (status, userInfo) -> Void in
            
            print("\(AGSResumableTaskJobStatusAsString(status)), \(userInfo)")
            
        }) { (tileCacheSizeEstimate, error) -> Void in
            
            if error != nil {
                //Report error to user
                UIAlertView(title: "Error", message: error.localizedDescription, delegate: nil, cancelButtonTitle: "Ok").show()
                SVProgressHUD.dismiss()
            }else{
                
                //Display results (# of bytes and tiles), properly formatted, ofcourse
                let tileCountString = "\(tileCacheSizeEstimate.tileCount)"
                
                let byteCountFormatter = NSByteCountFormatter()
                let byteCountString = byteCountFormatter.stringFromByteCount(tileCacheSizeEstimate.fileSize)
                self.estimateLabel.text = "\(byteCountString) / \(tileCountString) tiles"
                
                SVProgressHUD.showSuccessWithStatus("Estimated size:\n\(byteCountString) / \(tileCountString) tiles")
                
            }
        }
        
        SVProgressHUD.showWithStatus("Estimating\n size", maskType:4)
    
    }
    
    
    
    @IBAction func downloadAction(sender:AnyObject) {
        
        //Prepare list of levels to download
        let desiredLevels = self.levelsWithCount(Int(self.levelStepper.value), startingAt:self.tiledLayer.currentLOD(), fromLODs:self.tiledLayer.tileInfo.lods as! [AGSLOD])
        print("LODs requested \(desiredLevels)")
        
        //Use current envelope to download
        let extent = self.mapView.visibleAreaEnvelope
        
        //Prepare params using levels and envelope
        let params = AGSExportTileCacheParams(levelsOfDetail: desiredLevels, areaOfInterest:extent)
        
        //Kick-off operation
        self.tileCacheTask.exportTileCacheWithParameters(params, downloadFolderPath: nil, useExisting: true, status: { (status, userInfo) -> Void in
            //Print the job status
            print("\(AGSResumableTaskJobStatusAsString(status)), \(userInfo)")
            if userInfo != nil {
                
                let allMessages =  userInfo["messages"] as? [AGSGPMessage]
                
                if status == .FetchingResult {
                    let totalBytesDownloaded = userInfo["AGSDownloadProgressTotalBytesDownloaded"] as? Double
                    let totalBytesExpected = userInfo["AGSDownloadProgressTotalBytesExpected"] as? Double
                    if totalBytesDownloaded != nil && totalBytesExpected != nil {
                        let dPercentage = totalBytesDownloaded!/totalBytesExpected!
                        print("\(totalBytesDownloaded) / \(totalBytesExpected) = \(dPercentage)")
                        SVProgressHUD.showProgress(Float(dPercentage), status: "Downloading", maskType: 4)
                    }
                }
                else if allMessages != nil && allMessages!.count > 0 {
                    
                    //Else, display latest progress message provided by the service
                    if let message = MessageHelper.extractMostRecentMessage(allMessages!) {
                        print(message)
                        SVProgressHUD.showWithStatus(message, maskType:4)
                    }
                }
            }
        }) { (localTiledLayer, error) -> Void in
            SVProgressHUD.dismiss()
            if error != nil {
                
                //alert the user
                UIAlertView(title: "Error", message: error.localizedDescription, delegate: nil, cancelButtonTitle: "Ok").show()
                self.estimateLabel.text = ""
            }
            else{
                
                //clear out the map, and add the downloaded tile cache to the map
                self.mapView.reset()
                self.mapView.addMapLayer(localTiledLayer, withName:"offline")
                
                //Tell the user we're done
                UIAlertView(title: "Download Complete", message: "The tile cache has been added to the map", delegate: nil, cancelButtonTitle: "Ok").show()
                
                //Remove the option to download again.
//                for subview in self.downloadPanel.subviews as [UIView] {
//                    subview.removeFromSuperview()
//                }
                self.levelStepper.enabled = false
                
                BackgroundHelper.postLocalNotificationIfAppNotActive("Tile cache downloaded.")
            }
        }
        SVProgressHUD.showWithStatus("Preparing\n to download", maskType: 4)
    }
    
    
    
    func levelsWithCount(count:Int, startingAt startLOD:AGSLOD, fromLODs allLODs:[AGSLOD]) -> [UInt] {
        if let index = allLODs.indexOf(startLOD) {
            let endIndex = index + count-1
            let desiredLODs = Array(allLODs[index...endIndex])
            var desiredLevels = [UInt]()
            for LOD  in desiredLODs {
                desiredLevels.append(LOD.level)
            }
            
            return desiredLevels
        }
        return [UInt]()
    }

}

