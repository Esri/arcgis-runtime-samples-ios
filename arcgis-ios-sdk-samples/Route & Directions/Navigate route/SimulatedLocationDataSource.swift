// Copyright 2020 Esri
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

import ArcGIS

class SimulatedLocationDataSource: AGSSimulatedLocationDataSource {
    private var driverTimer: Timer?
    private var currentNodeIndex = 0
    private var timerInterval = 1.0
    
    init(route: AGSPolyline) {
        // Start the timer with specified playback interval
        super.init()
        driverTimer = Timer.scheduledTimer(withTimeInterval: TimeInterval(timerInterval), repeats: true) { [unowned self] (_) in
            self.timerAction()
        }
        self.setLocationsWith(route)
    }
    
    private func timerAction() {
        guard let locations = self.locations else { return }
        if currentNodeIndex > locations.count - 1 {
            driverTimer?.invalidate()
            return
        }
        if currentNodeIndex > 0 {
            if let distance = AGSGeometryEngine.geodeticDistanceBetweenPoint1(locations[currentNodeIndex].position!, point2: locations[currentNodeIndex - 1].position!, distanceUnit: AGSLinearUnit.meters(), azimuthUnit: AGSAngularUnit.degrees(), curveType: AGSGeodeticCurveType.geodesic) {
                let speed = distance.distance / timerInterval
                didUpdate(AGSLocation(position: locations[currentNodeIndex].position!, horizontalAccuracy: 5, velocity: speed, course: distance.azimuth2, lastKnown: false))
            } else {
                // Should I throw the error here? Or just leave it, as catching error from async block is cumbersome...
            }
        }
        currentNodeIndex += 1
    }
    
    override func doStart() {
        driverTimer?.fire()
        didStartOrFailWithError(nil)
    }
    
    override func doStop() {
        driverTimer?.invalidate()
    }
}

// will need to test if timer fires twice
