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

struct SwiftUIMapView {
    let map: AGSMap
    let graphicsOverlays: [AGSGraphicsOverlay]
    
    init(
        map: AGSMap,
        graphicsOverlays: [AGSGraphicsOverlay] = []
    ) {
        self.map = map
        self.graphicsOverlays = graphicsOverlays
    }
    
    private var onSingleTapAction: ((CGPoint, AGSPoint) -> Void)?
}

extension SwiftUIMapView {
    func onSingleTap(action: @escaping (CGPoint, AGSPoint) -> Void) -> Self {
        var copy = self
        copy.onSingleTapAction = action
        return copy
    }
}

extension SwiftUIMapView: UIViewRepresentable {
    typealias UIViewType = AGSMapView
    
    func makeCoordinator() -> Coordinator {
        Coordinator(
            onSingleTapAction: onSingleTapAction
        )
    }
    
    func makeUIView(context: Context) -> AGSMapView {
        let uiView = AGSMapView()
        uiView.map = map
        uiView.graphicsOverlays.setArray(graphicsOverlays)
        uiView.touchDelegate = context.coordinator
        return uiView
    }
    
    func updateUIView(_ uiView: AGSMapView, context: Context) {
        if map != uiView.map {
            uiView.map = map
        }
        if graphicsOverlays != uiView.graphicsOverlays as? [AGSGraphicsOverlay] {
            uiView.graphicsOverlays.setArray(graphicsOverlays)
        }
        context.coordinator.onSingleTapAction = onSingleTapAction
    }
}

extension SwiftUIMapView {
    /// You can use this coordinator to implement common Cocoa patterns, such as
    /// delegates, data sources, and responding to user events via target-action.
    class Coordinator: NSObject {
        var onSingleTapAction: ((CGPoint, AGSPoint) -> Void)?
        
        init(
            onSingleTapAction: ((CGPoint, AGSPoint) -> Void)?
        ) {
            self.onSingleTapAction = onSingleTapAction
        }
    }
}

extension SwiftUIMapView.Coordinator: AGSGeoViewTouchDelegate {
    /// Add conformance and implement the required methods.
    func geoView(_ geoView: AGSGeoView, didTapAtScreenPoint screenPoint: CGPoint, mapPoint: AGSPoint) {
        onSingleTapAction?(screenPoint, mapPoint)
    }
}
