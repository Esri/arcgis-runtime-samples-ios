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

struct DisplayMapSwiftUIView: View {
    struct MapOption: Equatable {
        let title: String
        let map: AGSMap
        
        static let topographic = MapOption(title: "Topographic", map: AGSMap(basemapStyle: .arcGISTopographic))
        static let oceans = MapOption(title: "Oceans", map: AGSMap(basemapStyle: .arcGISOceans))
        static let navigation = MapOption(title: "Navigation", map: AGSMap(basemapStyle: .arcGISNavigation))
        
        static let allOptions: [MapOption] = [.topographic, .oceans, .navigation]
    }
    
    /// The graphics overlay used to initialize `SwiftUIMapView`.
    let graphicsOverlay: AGSGraphicsOverlay = {
        let overlay = AGSGraphicsOverlay()
        overlay.renderer = AGSSimpleRenderer(
            symbol: AGSSimpleMarkerSymbol(style: .circle, color: .red, size: 10)
        )
        return overlay
    }()
    
    @State private var clearGraphicsButtonDisabled = true
    @State private var selectedMapOption: MapOption = .topographic
    /// A boolean that indicates whether the action sheet is presented.
    @State private var showingOptions = false
    
    var body: some View {
        VStack {
            SwiftUIMapView(map: selectedMapOption.map, graphicsOverlays: [graphicsOverlay])
                .onSingleTap { _, mapPoint in
                    let graphic = AGSGraphic(geometry: mapPoint, symbol: nil)
                    graphicsOverlay.graphics.add(graphic)
                    updateClearGraphicsButtonState()
                }
                .edgesIgnoringSafeArea(.all)
            HStack {
                Button("Choose Map", action: { showingOptions = true })
                    .actionSheet(isPresented: $showingOptions) {
                        ActionSheet(
                            title: Text("Choose a basemap."),
                            buttons: MapOption.allOptions.map { option in
                                    .default(Text(option.title), action: {
                                        guard option != selectedMapOption else { return }
                                        clearGraphics()
                                        selectedMapOption = option
                                    })
                            } + [.cancel()]
                        )
                    }
                Spacer()
                Button("Clear Graphics", action: clearGraphics)
                    .disabled(clearGraphicsButtonDisabled)
            }
            .padding()
        }
    }
    
    func clearGraphics() {
        graphicsOverlay.graphics.removeAllObjects()
        updateClearGraphicsButtonState()
    }
    
    func updateClearGraphicsButtonState() {
        clearGraphicsButtonDisabled = (graphicsOverlay.graphics as! [AGSGraphic]).isEmpty
    }
}

struct DisplayMapSwiftUIView_Previews: PreviewProvider {
    static var previews: some View {
        DisplayMapSwiftUIView()
    }
}
