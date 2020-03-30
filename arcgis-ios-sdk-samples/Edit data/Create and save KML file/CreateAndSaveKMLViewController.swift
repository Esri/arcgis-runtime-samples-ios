//
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
            mapView.map = makeMap()
            let sketchEditor = AGSSketchEditor()
            mapView.sketchEditor = sketchEditor
        }
    }
    
    @IBOutlet var addButton: UIBarButtonItem?
    @IBOutlet var sketchDoneButton: UIBarButtonItem?
    @IBOutlet var toolbar: UIToolbar?
    @IBOutlet var saveButton: UIBarButtonItem?
    
    // Prompt options to allow the user to save the KMZ file.
    @IBAction func saveKMZ() {
        let kmzProvider = KMZProvider(document: kmlDocument)
        let activityViewController = UIActivityViewController(activityItems: [kmzProvider], applicationActivities: nil)
        present(activityViewController, animated: true)
        activityViewController.completionWithItemsHandler = { (activityType: UIActivity.ActivityType?, completed: Bool, arrayReturnedItems: [Any]?, error: Error?) in
            kmzProvider.deleteKMZ()
        }
    }

    // Complete the current sketch and add it to the KML document.
    @IBAction func completeSketch() {
        geometry = mapView.sketchEditor?.geometry
        projectedGeometry = AGSGeometryEngine.projectGeometry(geometry!, to: spatialRef)
        kmlGeometry = AGSKMLGeometry(geometry: projectedGeometry!, altitudeMode: .clampToGround)
        currentPlacemark = AGSKMLPlacemark(geometry: kmlGeometry!)
        currentPlacemark!.style = kmlStyle
        kmlDocument.addChildNode(currentPlacemark!)
        mapView.sketchEditor?.stop()
        changeButton()
    }
    
    // Reset the KML.
    @IBAction func resetKML() {
        mapView.map?.operationalLayers.removeAllObjects()
        currentPlacemark = nil
        kmlDocument = AGSKMLDocument()
        kmlDataset = AGSKMLDataset(rootNode: kmlDocument)
        kmlLayer = AGSKMLLayer(kmlDataset: kmlDataset!)
        mapView.map?.operationalLayers.add(kmlLayer!)
    }
    
    var sketchCreationMode: AGSSketchCreationMode?
    var kmlDocument = AGSKMLDocument()
    let spatialRef = AGSSpatialReference.wgs84()
    var kmlStyle = AGSKMLStyle()
    var geometry: AGSGeometry?
    var projectedGeometry: AGSGeometry?
    var kmlGeometry: AGSKMLGeometry?
    var currentPlacemark: AGSKMLPlacemark?
    var kmlDataset: AGSKMLDataset?
    var kmlLayer: AGSKMLLayer?
    
    // Set the basemap and add a KML layer.
    func makeMap() -> AGSMap {
        let map = AGSMap(basemap: .darkGrayCanvasVector())
        let kmlDataset = AGSKMLDataset(rootNode: kmlDocument)
        map.operationalLayers.add(AGSKMLLayer(kmlDataset: kmlDataset))
        return map
    }
    
    // Make KML with a point style.
    func makeKMLStyleWithPointStyle(icon: AGSKMLIcon, color: UIColor) -> AGSKMLStyle {
        let iconStyle = AGSKMLIconStyle(icon: icon, scale: 1.0)
        let kmlStyle = AGSKMLStyle()
        kmlStyle.iconStyle = iconStyle
        return kmlStyle
    }
    
    // Make KML with a line style.
    func makeKMLStyleWithLineStyle(color: UIColor) -> AGSKMLStyle {
        let kmlStyle = AGSKMLStyle()
        kmlStyle.lineStyle = AGSKMLLineStyle(color: color, width: 2.0)
        return kmlStyle
    }
    
    // Make KML with a polygon style.
    func makeKMLStyleWithPolygonStyle(color: UIColor) -> AGSKMLStyle {
        let kmlStyle = AGSKMLStyle()
        kmlStyle.polygonStyle = AGSKMLPolygonStyle(color: color)
        return kmlStyle
    }
    
    // Change the bottom toolbar button.
    func changeButton() {
        if (toolbar?.items?.contains(addButton!))! {
            toolbar?.items?.remove(at: 2)
            toolbar?.items?.insert(sketchDoneButton!, at: 2)
        } else {
            toolbar?.items?.remove(at: 2)
            toolbar?.items?.insert(addButton!, at: 2)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        toolbar?.items?.remove(at: 3)
        // Add the source code button item to the right of navigation bar.
        (navigationItem.rightBarButtonItem as? SourceCodeBarButtonItem)?.filenames = [
            "CreateAndSaveKMLViewController",
            "CreateAndSaveKMLSettingsViewController"
        ]
    }
    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        if let navigationController = segue.destination as? UINavigationController,
            let settingsViewController = navigationController.topViewController as? CreateAndSaveKMLSettingsViewController {
            settingsViewController.kmlStyle = kmlStyle
            settingsViewController.delegate = self
        }
    }
}

// Handles saving a KMZ file.
private class KMZProvider: UIActivityItemProvider {
    private let document: AGSKMLDocument
    private var documentURL: URL?
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
        documentURL = temporaryDirectoryURL?.appendingPathComponent("\(document.name).kmz")
        let semaphore = DispatchSemaphore(value: 0)
        document.save(toFileURL: documentURL!) { _ in
            semaphore.signal()
        }
        semaphore.wait()
        return documentURL!
    }
    
    func deleteKMZ() {
        guard let url = temporaryDirectoryURL else { return }
        try? FileManager.default.removeItem(at: url)
    }
}

// Set KML style depending on which feature has been chosen.
extension CreateAndSaveKMLViewController: CreateAndSaveKMLSettingsViewControllerDelegate {
    func createAndSaveKMLSettingsViewController(_ createAndSaveKMLSettingsViewController: CreateAndSaveKMLSettingsViewController, feature: String, icon: AGSKMLIcon?, color: UIColor) {
        switch feature {
        case "point":
            sketchCreationMode = AGSSketchCreationMode.point
            kmlStyle = makeKMLStyleWithPointStyle(icon: icon!, color: color)
        case "polyline":
            sketchCreationMode = AGSSketchCreationMode.polyline
            kmlStyle = makeKMLStyleWithLineStyle(color: color)
        case "polygon":
            sketchCreationMode = AGSSketchCreationMode.polygon
            kmlStyle = makeKMLStyleWithPolygonStyle(color: color)
            kmlStyle.polygonStyle?.isFilled = true
            kmlStyle.polygonStyle?.isOutlined = false
        default:
            break
        }
    }
    
    // Begins sketch editor after attributes were chosen. 
    func createAndSaveKMLSettingsViewControllerDidFinish(_ controller: CreateAndSaveKMLSettingsViewController) {
        dismiss(animated: true)
        changeButton()
        mapView.sketchEditor?.stop()
        mapView.sketchEditor?.start(with: sketchCreationMode!)
    }
}
