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

import Foundation

protocol SimulatedNMEADataSourceDelegate: AnyObject {
    /// A mock delegate method to receive NMEA data updates.
    /// Replace it with the real one to receive NMEA sentences from a GPS dongle.
    /// - Parameters:
    ///   - dataSource: The data source itself.
    ///   - nmeaData: The latest NMEA data.
    func dataSource(_ dataSource: SimulatedNMEADataSource, didUpdate nmeaData: Data)
}

class SimulatedNMEADataSource {
    /// The playback speed multiplier.
    private let playbackSpeed: Double
    /// An iterator to hold and loop through the mock NMEA data.
    private var nmeaDataIterator: CircularIterator<Data>
    /// A timer to periodically provide NMEA data updates.
    private var timer: Timer?
    /// A delegate to notify view controllers.
    weak var delegate: SimulatedNMEADataSourceDelegate?
    
    /// Load locations from NMEA sentences.
    /// Read mock NMEA sentences line by line and group them by the timestamp.
    /// - Parameters:
    ///   - nmeaSourceFile: The URL of the NMEA source file.
    ///   - speed: The playback speed multiplier.
    init(nmeaSourceFile: URL, speed: Double = 1.0) {
        // An empty container for NMEA data.
        var dataBySeconds = [Data]()
        
        if let nmeaStrings = try? String(contentsOf: nmeaSourceFile, encoding: .utf8).components(separatedBy: .newlines).filter({ !$0.isEmpty }) {
            // A temporary container for the NMEA sentences at current timestamp.
            var currentTimestamp = [String]()
            for nmeaLine in nmeaStrings {
                currentTimestamp.append(nmeaLine)
                // In the mock data file, the sentences in each second end with
                // an RMC message. Join all the messages in this second to a
                // single data object.
                let sentenceIdentifier = nmeaLine.prefix(6)
                if sentenceIdentifier == "$GPRMC",
                   !currentTimestamp.isEmpty {
                    dataBySeconds.append(Data(currentTimestamp.joined(separator: "\n").utf8))
                    currentTimestamp.removeAll()
                }
            }
        }
        // Create an iterator for the mock data generation.
        nmeaDataIterator = CircularIterator(elements: dataBySeconds)
        playbackSpeed = speed
    }
    
    func start() {
        guard !nmeaDataIterator.elements.isEmpty else { return }
        // Invalidate timer to stop previous mock data generation.
        timer?.invalidate()
        // Time interval in second.
        let interval: TimeInterval = 1 / playbackSpeed
        // Create a new timer.
        let newTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.delegate?.dataSource(self, didUpdate: self.nmeaDataIterator.next()!)
        }
        timer = newTimer
    }
    
    func stop() {
        timer?.invalidate()
        timer = nil
    }
    
    deinit {
        stop()
    }
}

/// A generic circular iterator.
private struct CircularIterator<Element>: IteratorProtocol {
    let elements: [Element]
    private var elementIterator: Array<Element>.Iterator
    
    init(elements: [Element]) {
        self.elements = elements
        elementIterator = elements.makeIterator()
    }
    
    mutating func next() -> Element? {
        if let next = elementIterator.next() {
            return next
        } else {
            elementIterator = elements.makeIterator()
            return elementIterator.next()
        }
    }
}
