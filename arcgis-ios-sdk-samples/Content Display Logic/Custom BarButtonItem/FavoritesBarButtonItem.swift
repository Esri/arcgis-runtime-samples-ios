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

class FavoritesBarButtonItem: UIBarButtonItem {
    var sample: Sample
    
    init(sample: Sample) {
        self.sample = sample
        super.init()
        self.image = updateImage(isFavorite: sample.isFavorite)
        self.target = self
        self.action = #selector(FavoritesBarButtonItem.toggleIsFavorite)
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
        // Update the image.
        self.image = updateImage(isFavorite: sample.isFavorite)
    }
    
    /// Update the image to indicate if the sample is favorited.
    func updateImage(isFavorite: Bool) -> UIImage {
        switch isFavorite {
        case true:
            return UIImage(systemName: "star.fill")!
        case false:
            return UIImage(systemName: "star")!
        }
    }
}
