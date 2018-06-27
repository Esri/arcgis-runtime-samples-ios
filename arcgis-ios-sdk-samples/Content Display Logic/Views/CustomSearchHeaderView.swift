// Copyright 2016 Esri.
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

protocol CustomSearchHeaderViewDelegate:class {
    func customSearchHeaderViewWillShowSuggestions(_ customSearchHeaderView:CustomSearchHeaderView)
    func customSearchHeaderViewWillHideSuggestions(_ customSearchHeaderView:CustomSearchHeaderView)
    func customSearchHeaderView(_ customSearchHeaderView:CustomSearchHeaderView, didFindSamples sampleNames:[String]?)
}

class CustomSearchHeaderView: UICollectionReusableView, UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate {
    
    @IBOutlet var searchBar:UISearchBar!
    @IBOutlet var suggestionsTableView:UITableView!
    
    private let cellIdentifier = "SuggestionCell"
    
    weak var delegate:CustomSearchHeaderViewDelegate?
    
    var nibView:UIView!
    let shrinkedViewHeight:CGFloat = 44
    let expandedViewHeight:CGFloat = 200
    var isShowingSuggestions = false
    
    var suggestions:[String]! {
        didSet {
            self.suggestionsTableView.reloadData()
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        self.setup()
    }
    
    func setup() {
        //set background color to clear color
        self.backgroundColor = .clear
        
        self.nibView = self.loadViewFromNib()
        
        self.nibView.frame = self.bounds
        nibView.autoresizingMask = [UIViewAutoresizing.flexibleHeight, .flexibleWidth]
        
        
        
        if let searchTextField = self.searchBar.value(forKey: "searchField") as? UITextField {
            let placeholderAttributes = [NSAttributedStringKey.foregroundColor: UIColor.white, NSAttributedStringKey.font: UIFont.systemFont(ofSize: UIFont.systemFontSize)]
            let attributedPlaceholder = NSAttributedString(string: "Search", attributes: placeholderAttributes)
            searchTextField.attributedPlaceholder = attributedPlaceholder
            searchTextField.textColor = .white
            searchTextField.borderStyle = .none
            searchTextField.layer.cornerRadius = 8
            searchTextField.backgroundColor = .secondaryBlue
            
            let imageV = searchTextField.leftView as! UIImageView
            imageV.image = imageV.image?.withRenderingMode(UIImageRenderingMode.alwaysTemplate)
            imageV.tintColor = .white
        }
        
        self.addSubview(self.nibView)
    }
    
    func loadViewFromNib() -> UIView {
        let bundle = Bundle(for: type(of: self))
        let nib = UINib(nibName: "CustomSearchHeaderView", bundle: bundle)
        let view = nib.instantiate(withOwner: self, options: nil)[0] as! UIView
        
        return view
    }
    
    override func awakeFromNib() {
        //register table cell
        let nib = UINib(nibName: "SuggestionTableViewCell", bundle: Bundle(for: type(of: self)))
        self.suggestionsTableView.register(nib, forCellReuseIdentifier: cellIdentifier)
    }
    
    func showSuggestionsTable() {
        self.isShowingSuggestions = true
        self.delegate?.customSearchHeaderViewWillShowSuggestions(self)
    }
    
    func hideSuggestionsTable() {
        self.isShowingSuggestions = false
        self.delegate?.customSearchHeaderViewWillHideSuggestions(self)
    }
    
    func searchForString(_ string:String) {
        //hide suggestions
        self.hideSuggestionsTable()
        //hide keyboard
        self.searchBar.resignFirstResponder()
        
        let sampleNames = SearchEngine.sharedInstance().searchForString(string)
        self.delegate?.customSearchHeaderView(self, didFindSamples: sampleNames)
    }
    
    // MARK: - Table view data source
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.suggestions?.count ?? 0
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath)
        
        cell.textLabel?.text = suggestions[indexPath.row]
        cell.backgroundColor = .clear
        
        return cell
    }
    
    //MARK: - Table view delegate
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.searchBar.text = self.suggestions[indexPath.row]
        self.searchForString(self.searchBar.text!)
    }
    
    //MARK: - UISearchBarDelegate
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        self.searchForString(self.searchBar.text!)
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if let suggestions = SearchEngine.sharedInstance().suggestionsForString(searchText) , suggestions.count > 0 {
            self.suggestions = suggestions
            //call delegate
            self.showSuggestionsTable()
        }
        else {
            self.hideSuggestionsTable()
        }
    }
    
    func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
        searchBar.setShowsCancelButton(true, animated: true)
        return true
    }
    
    func searchBarShouldEndEditing(_ searchBar: UISearchBar) -> Bool {
        searchBar.setShowsCancelButton(false, animated: true)
        return true
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        self.hideSuggestionsTable()
    }
    
}
