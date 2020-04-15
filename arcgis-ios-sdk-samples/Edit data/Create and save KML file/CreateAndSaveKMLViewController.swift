// Copyright © 2020 Esri.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//   http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import UIKit
import ArcGIS

class CreateAndSaveKMLViewController: UIViewController {
    // Set the map.
    @IBOutlet var mapView: AGSMapView! {
        didSet {
            mapView.map = AGSMap(basemap: .darkGrayCanvasVector())
            resetKML()
            let sketchEditor = AGSSketchEditor()
            mapView.sketchEditor = sketchEditor
        }
    }
    
    @IBOutlet var addButton: UIBarButtonItem!
    @IBOutlet var sketchDoneButton: UIBarButtonItem!
    @IBOutlet var toolbar: UIToolbar!
    @IBOutlet var actionButtonItem: UIBarButtonItem!
    @IBOutlet var resetButtonItem: UIBarButtonItem!
    
    // Prompt feature selection action sheet.
    @IBAction func addFeature() {
        let alertController = UIAlertController(title: "Select Feature", message: nil, preferredStyle: .actionSheet)
        let pointAction = UIAlertAction(title: "Point", style: .default) { (_) in
            self.addPoint()
        }
        alertController.addAction(pointAction)
        let polylineAction = UIAlertAction(title: "Polyline", style: .default) { (_) in
            self.addPolyline()
        }
        alertController.addAction(polylineAction)
        let polygonAction = UIAlertAction(title: "Polygon", style: .default) { (_) in
            self.addPolygon()
        }
        alertController.addAction(polygonAction)
        
        // Add "cancel" item.
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        
        alertController.popoverPresentationController?.barButtonItem = addButton
        present(alertController, animated: true, completion: nil)
    }
    
    // Prompt options to allow the user to save the KMZ file.
    @IBAction func saveKMZ(_ sender: UIBarButtonItem) {
        let kmzProvider = KMZProvider(document: kmlDocument)
        let activityViewController = UIActivityViewController(activityItems: [kmzProvider], applicationActivities: nil)
        activityViewController.popoverPresentationController?.barButtonItem = sender
        present(activityViewController, animated: true)
        activityViewController.completionWithItemsHandler = { (activityType: UIActivity.ActivityType?, completed: Bool, arrayReturnedItems: [Any]?, error: Error?) in
            kmzProvider.deleteKMZ()
        }
    }

    // Complete the current sketch and add it to the KML document.
    @IBAction func completeSketch() {
        let geometry = mapView.sketchEditor?.geometry
        let projectedGeometry = AGSGeometryEngine.projectGeometry(geometry!, to: spatialRef)
        let kmlGeometry = AGSKMLGeometry(geometry: projectedGeometry!, altitudeMode: .clampToGround)
        currentPlacemark = AGSKMLPlacemark(geometry: kmlGeometry!)
        currentPlacemark!.style = kmlStyle
        kmlDocument.addChildNode(currentPlacemark!)
        mapView.sketchEditor?.stop()
        updateToolbarItems()
        actionButtonItem?.isEnabled = true
    }
    
    // Reset the KML.
    @IBAction func resetKML() {
        mapView.map?.operationalLayers.removeAllObjects()
        currentPlacemark = nil
        kmlDocument = AGSKMLDocument()
        let kmlDataset = AGSKMLDataset(rootNode: kmlDocument)
        kmlLayer = AGSKMLLayer(kmlDataset: kmlDataset)
        mapView.map?.operationalLayers.add(kmlLayer!)
    }
    
    var sketchCreationMode: AGSSketchCreationMode?
    var kmlDocument = AGSKMLDocument()
    let spatialRef = AGSSpatialReference.wgs84()
    var kmlStyle = AGSKMLStyle()
    var currentPlacemark: AGSKMLPlacemark?
    var kmlLayer: AGSKMLLayer?
    let colors: [(String, UIColor)] = [
        ("Red", .red),
        ("Yellow", .yellow),
        ("White", .white),
        ("Purple", .purple),
        ("Orange", .orange),
        ("Magenta", .magenta),
        ("Light gray", .lightGray),
        ("Gray", .gray),
        ("Dark gray", .darkGray),
        ("Green", .green),
        ("Cyan", .cyan),
        ("Brown", .brown),
        ("Blue", .blue),
        ("Black", .black)
    ]
    
    // Prompt icon selection action sheet.
    func addPoint() {
        let alertController = UIAlertController(title: "Select Icon", message: "This icon will be used for the new feature", preferredStyle: .actionSheet)
        let icons: [(String, URL)] = [
            ("No style", URL(string: "http://resources.esri.com/help/900/arcgisexplorer/sdk/doc/bitmaps/148cca9a-87a8-42bd-9da4-5fe427b6fb7b127.png")!),
            ("Star", URL(string: "https://static.arcgis.com/images/Symbols/Shapes/BlueStarLargeB.png")!),
            ("Diamond", URL(string: "https://static.arcgis.com/images/Symbols/Shapes/BlueDiamondLargeB.png")!),
            ("Circle", URL(string: "https://static.arcgis.com/images/Symbols/Shapes/BlueCircleLargeB.png")!),
            ("Square", URL(string: "https://static.arcgis.com/images/Symbols/Shapes/BlueSquareLargeB.png")!),
            ("Round pin", URL(string: "https://static.arcgis.com/images/Symbols/Shapes/BluePin1LargeB.png")!),
            ("Square pin", URL(string: "https://static.arcgis.com/images/Symbols/Shapes/BluePin2LargeB.png")!)
        ]
        icons.forEach { (title, url) in
            let pointAction = UIAlertAction(title: title, style: .default) { (_) in
                self.kmlStyle = self.makeKMLStyleWithPointStyle(iconURL: url)
                self.startSketch(creationMode: .point)
            }
            alertController.addAction(pointAction)
        }
        // Add "cancel" item.
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        
        alertController.popoverPresentationController?.barButtonItem = addButton
        present(alertController, animated: true, completion: nil)
    }
    
    // Prompt color selection action sheet for polyline feature.
    func addPolyline() {
        let alertController = UIAlertController(title: "Select Color", message: "This color will be used for the polyline", preferredStyle: .actionSheet)
        colors.forEach { (colorTitle, colorValue) in
                let colorAction = UIAlertAction(title: colorTitle, style: .default) { (_) in
                self.kmlStyle = self.makeKMLStyleWithLineStyle(color: colorValue)
                self.startSketch(creationMode: .polyline)
                }
            alertController.addAction(colorAction)
        }
        // Add "cancel" item.
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        
        alertController.popoverPresentationController?.barButtonItem = addButton
        present(alertController, animated: true, completion: nil)
    }
    
    // Prompt color selection action sheet for polygon feature.
    func addPolygon() {
        let alertController = UIAlertController(title: "Select Color", message: "This color will be used to fill the polygon", preferredStyle: .actionSheet)
        colors.forEach { (colorTitle, colorValue) in
                let colorAction = UIAlertAction(title: colorTitle, style: .default) { (_) in
                self.kmlStyle = self.makeKMLStyleWithPolygonStyle(color: colorValue)
                self.startSketch(creationMode: .polygon)
                }
            alertController.addAction(colorAction)
        }
        // Add "cancel" item.
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        
        alertController.popoverPresentationController?.barButtonItem = addButton
        present(alertController, animated: true, completion: nil)
    }
    
    // Make KML with a point style.
    func makeKMLStyleWithPointStyle(iconURL: URL) -> AGSKMLStyle {
        let icon = AGSKMLIcon(url: iconURL)
        let iconStyle = AGSKMLIconStyle(icon: icon, scale: 1.0)
        kmlStyle.iconStyle = iconStyle
        return kmlStyle
    }
    
    // Make KML with a line style.
    func makeKMLStyleWithLineStyle(color: UIColor) -> AGSKMLStyle {
        kmlStyle.lineStyle = AGSKMLLineStyle(color: color, width: 2.0)
        return kmlStyle
    }
    
    // Make KML with a polygon style.
    func makeKMLStyleWithPolygonStyle(color: UIColor) -> AGSKMLStyle {
        kmlStyle.polygonStyle = AGSKMLPolygonStyle(color: color)
        kmlStyle.polygonStyle?.isFilled = true
        kmlStyle.polygonStyle?.isOutlined = false
        return kmlStyle
    }
    
    // Update the bottom toolbar button.
    func updateToolbarItems() {
        guard let sketchEditor = mapView.sketchEditor else {
            return
        }
        let middleButtonItem: UIBarButtonItem
        if sketchEditor.isStarted {
            middleButtonItem = sketchDoneButton
        } else {
            middleButtonItem = addButton
        }
        let flexibleSpace1 = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let flexibleSpace2 = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        toolbar.items = [resetButtonItem, flexibleSpace1, middleButtonItem, flexibleSpace2, actionButtonItem]
    }
    
    // Start a new sketch mode.
    func startSketch(creationMode: AGSSketchCreationMode) {
        mapView.sketchEditor?.start(with: creationMode)
        updateToolbarItems()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        updateToolbarItems()
        // Add the source code button item to the right of navigation bar.
        (navigationItem.rightBarButtonItem as? SourceCodeBarButtonItem)?.filenames = [
            "CreateAndSaveKMLViewController",
            "CreateAndSaveKMLSettingsViewController"
        ]
    }
}

// Handles saving a KMZ file.
private class KMZProvider: UIActivityItemProvider {
    private let document: AGSKMLDocument
    private var temporaryDirectoryURL: URL?
    
    init(document: AGSKMLDocument) {
        self.document = document
        if document.name.isEmpty {
            document.name = "Untitled"
        }
        super.init(placeholderItem: URL(fileURLWithPath: "\(document.name).kmz"))
    }

    override var item: Any {
        temporaryDirectoryURL = try? FileManager.default.url(
            for: .itemReplacementDirectory,
            in: .userDomainMask,
            appropriateFor: Bundle.main.bundleURL,
            create: true
        )
        let documentURL = temporaryDirectoryURL?.appendingPathComponent("\(document.name).kmz")
        let semaphore = DispatchSemaphore(value: 0)
        document.save(toFileURL: documentURL!) { _ in
            semaphore.signal()
        }
        semaphore.wait()
        return documentURL!
    }
    
    // Deletes the temporary directory.
    func deleteKMZ() {
        guard let url = temporaryDirectoryURL else { return }
        try? FileManager.default.removeItem(at: url)
    }
}
