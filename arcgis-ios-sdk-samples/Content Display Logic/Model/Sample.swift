//
// Copyright © 2018 Esri.
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

struct Sample: Equatable {
    var name: String
    var description: String
    var storyboardName: String
    var dependencies: [String]
}

extension Sample: Decodable {
    enum CodingKeys: String, CodingKey {
        case name = "displayName"
        case description = "descriptionText"
        case storyboardName = "storyboardName"
        case dependencies = "dependency"
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        name = try values.decode(String.self, forKey: .name)
        description = try values.decode(String.self, forKey: .description)
        storyboardName = try values.decode(String.self, forKey: .storyboardName)
        dependencies = try values.decodeIfPresent([String].self, forKey: .dependencies) ?? []
    }
}
