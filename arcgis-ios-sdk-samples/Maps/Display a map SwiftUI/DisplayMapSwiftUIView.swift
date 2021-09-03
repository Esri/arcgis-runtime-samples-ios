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
    /// A boolean that indicates whether the action sheet is presented.
    @State private var showingOptions = false
    /// An object used for setting up a `SwiftUIMapView`.
    @ObservedObject private var mapViewContext = MapViewContext()
    
    var body: some View {
        VStack {
            SwiftUIMapView(mapViewContext: mapViewContext)
                .onMapViewTap { _, mapPoint in
                    let graphic = AGSGraphic(geometry: mapPoint, symbol: nil)
                    mapViewContext.graphicsOverlay.graphics.add(graphic)
                }
                .edgesIgnoringSafeArea(.all)
            HStack {
                Button("Change Basemap") {
                    showingOptions = true
                }
                .actionSheet(isPresented: $showingOptions) {
                    ActionSheet(
                        title: Text("Choose a basemap."),
                        buttons: [
                            .default(Text("Topographic")) {
                                let basemap = AGSBasemap(style: .arcGISTopographic)
                                mapViewContext.map.basemap = basemap
                            },
                            .default(Text("Oceans")) {
                                let basemap = AGSBasemap(style: .arcGISOceans)
                                mapViewContext.map.basemap = basemap
                            },
                            .default(Text("Navigation")) {
                                let basemap = AGSBasemap(style: .arcGISNavigation)
                                mapViewContext.map.basemap = basemap
                            },
                            .cancel()
                        ]
                    )
                }
                Spacer()
                Button("Clear Graphics") {
                    mapViewContext.graphicsOverlay.graphics.removeAllObjects()
                }
                .disabled(mapViewContext.graphicsEmpty)
            }
            .padding()
        }
    }
}

struct DisplayMapSwiftUIView_Previews: PreviewProvider {
    static var previews: some View {
        DisplayMapSwiftUIView()
    }
}
