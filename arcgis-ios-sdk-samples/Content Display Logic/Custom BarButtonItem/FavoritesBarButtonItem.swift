// Copyright 2022 Esri.
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

import UIKit
import Firebase

final class FavoritesBarButtonItem: UIBarButtonItem {
    let sample: Sample
    
    init(sample: Sample) {
        self.sample = sample
        super.init()
        self.image = makeImage(isFavorite: sample.isFavorite)
        self.target = self
        self.action = #selector(toggleIsFavorite)
    }
    
    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /// Toggle the isFavorite boolean.
    @objc
    func toggleIsFavorite() {
        // Update the bool.
        sample.isFavorite.toggle()
        if sample.isFavorite {
            // Google Analytics set favorite event.
            Analytics.logEvent("set_favorite", parameters: [
                AnalyticsParameterContentType: sample.name
            ])
        }
        // Update the image.
        self.image = makeImage(isFavorite: sample.isFavorite)
    }
    
    /// Update the image to indicate if the sample is favorited.
    func makeImage(isFavorite: Bool) -> UIImage {
        let systemName = isFavorite ? "star.fill" : "star"
        return UIImage(systemName: systemName)!
    }
}
