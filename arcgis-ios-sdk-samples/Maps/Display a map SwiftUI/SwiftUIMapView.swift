// Copyright 2021 Esri
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//   https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import SwiftUI
import ArcGIS

struct SwiftUIMapView: UIViewRepresentable {
    typealias UIViewType = AGSMapView
    
    /// The context for setting up the `SwiftUIMapView`.
    let mapViewContext: MapViewContext
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(self)
    }
    
    func makeUIView(context: Context) -> AGSMapView {
        let mapView = mapViewContext.mapView
        mapView.map = mapViewContext.map
        mapView.touchDelegate = context.coordinator
        return mapView
    }
    
    func updateUIView(_ uiView: AGSMapView, context: Context) {
    }
    
    var onMapViewTapAction: ((CGPoint, AGSPoint) -> Void)?
    
    func onMapViewTap(action: @escaping (CGPoint, AGSPoint) -> Void) -> SwiftUIMapView {
        var newView = self
        newView.onMapViewTapAction = action
        return newView
    }
}

extension SwiftUIMapView {
    /// You can use this coordinator to implement common Cocoa patterns, such as
    /// delegates, data sources, and responding to user events via target-action.
    class Coordinator: NSObject, AGSGeoViewTouchDelegate {
        var parent: SwiftUIMapView
        
        init(_ parent: SwiftUIMapView) {
            self.parent = parent
        }
        
        /// Add conformance and implement the required methods.
        func geoView(_ geoView: AGSGeoView, didTapAtScreenPoint screenPoint: CGPoint, mapPoint: AGSPoint) {
            parent.onMapViewTapAction?(screenPoint, mapPoint)
        }
    }
}

class MapViewContext: ObservableObject {
    let map: AGSMap
    let mapView: AGSMapView
    
    @Published var graphicsEmpty: Bool!
    
    private var graphicsObservation: NSKeyValueObservation?
    
    let graphicsOverlay: AGSGraphicsOverlay = {
        let overlay = AGSGraphicsOverlay()
        overlay.renderer = AGSSimpleRenderer(
            symbol: AGSSimpleMarkerSymbol(style: .circle, color: .red, size: 10)
        )
        return overlay
    }()
    
    init(map: AGSMap = .init(basemapStyle: .arcGISTopographic)) {
        self.map = map
        mapView = AGSMapView(frame: .zero)
        mapView.graphicsOverlays.add(graphicsOverlay)
        graphicsObservation = graphicsOverlay.observe(\.graphics, options: [.initial]) { [weak self] overlay, _ in
            self?.graphicsEmpty = (overlay.graphics as! [AGSGraphic]).isEmpty
        }
    }
}
