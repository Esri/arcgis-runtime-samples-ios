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
    // Set icon
    override init() {
        super.init()
        self.image = UIImage(systemName: "star")
        self.target = self
        self.action = #selector(FavoritesBarButtonItem.addToFavorites)
    }
    
    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // Add to favorites. Change sample favorites property
    @objc
    func addToFavorites() {
        // Add to favorites category in content plist
        // change button to fill star
        self.image = UIImage(systemName: "star.fill")
    }
}
