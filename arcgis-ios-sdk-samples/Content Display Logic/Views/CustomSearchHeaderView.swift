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
    func customSearchHeaderViewWillShowSuggestions(customSearchHeaderView:CustomSearchHeaderView)
    func customSearchHeaderViewWillHideSuggestions(customSearchHeaderView:CustomSearchHeaderView)
    func customSearchHeaderView(customSearchHeaderView:CustomSearchHeaderView, didFindSamples sampleNames:[String]?)
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
        self.backgroundColor = UIColor.clearColor()
        
        self.nibView = self.loadViewFromNib()
        
        self.nibView.frame = self.bounds
        nibView.autoresizingMask = [UIViewAutoresizing.FlexibleHeight, .FlexibleWidth]
        
        
        
        if let searchTextField = self.searchBar.valueForKey("searchField") as? UITextField {
            let placeholderAttributes = [NSForegroundColorAttributeName: UIColor.whiteColor(), NSFontAttributeName: UIFont.systemFontOfSize(UIFont.systemFontSize())]
            let attributedPlaceholder = NSAttributedString(string: "Search", attributes: placeholderAttributes)
            searchTextField.attributedPlaceholder = attributedPlaceholder
            searchTextField.textColor = UIColor.whiteColor()
            searchTextField.borderStyle = .None
            searchTextField.layer.cornerRadius = 8
            searchTextField.backgroundColor = UIColor.secondaryBlue()
            
            let imageV = searchTextField.leftView as! UIImageView
            imageV.image = imageV.image?.imageWithRenderingMode(UIImageRenderingMode.AlwaysTemplate)
            imageV.tintColor = UIColor.whiteColor()
        }
        
        self.addSubview(self.nibView)
    }
    
    func loadViewFromNib() -> UIView {
        let bundle = NSBundle(forClass: self.dynamicType)
        let nib = UINib(nibName: "CustomSearchHeaderView", bundle: bundle)
        let view = nib.instantiateWithOwner(self, options: nil)[0] as! UIView
        
        return view
    }
    
    override func awakeFromNib() {
        //register table cell
        let nib = UINib(nibName: "SuggestionTableViewCell", bundle: NSBundle(forClass: self.dynamicType))
        self.suggestionsTableView.registerNib(nib, forCellReuseIdentifier: cellIdentifier)
    }
    
    func showSuggestionsTable() {
        self.isShowingSuggestions = true
        self.delegate?.customSearchHeaderViewWillShowSuggestions(self)
    }
    
    func hideSuggestionsTable() {
        self.isShowingSuggestions = false
        self.delegate?.customSearchHeaderViewWillHideSuggestions(self)
    }
    
    func searchForString(string:String) {
        //hide suggestions
        self.hideSuggestionsTable()
        //hide keyboard
        self.searchBar.resignFirstResponder()
        
        let sampleNames = SearchEngine.sharedInstance().searchForString(string)
        self.delegate?.customSearchHeaderView(self, didFindSamples: sampleNames)
    }
    
    // MARK: - Table view data source
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.suggestions?.count ?? 0
    }
    
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier, forIndexPath: indexPath)
        
        cell.textLabel?.text = suggestions[indexPath.row]
        cell.backgroundColor = UIColor.clearColor()
        
        return cell
    }
    
    //MARK: - Table view delegate
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        self.searchBar.text = self.suggestions[indexPath.row]
        self.searchForString(self.searchBar.text!)
    }
    
    //MARK: - UISearchBarDelegate
    
    func searchBarSearchButtonClicked(searchBar: UISearchBar) {
        self.searchForString(self.searchBar.text!)
    }
    
    func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
        if let suggestions = SearchEngine.sharedInstance().suggestionsForString(searchText) where suggestions.count > 0 {
            self.suggestions = suggestions
            //call delegate
            self.showSuggestionsTable()
        }
        else {
            self.hideSuggestionsTable()
        }
    }
    
    func searchBarShouldBeginEditing(searchBar: UISearchBar) -> Bool {
        searchBar.setShowsCancelButton(true, animated: true)
        return true
    }
    
    func searchBarShouldEndEditing(searchBar: UISearchBar) -> Bool {
        searchBar.setShowsCancelButton(false, animated: true)
        return true
    }
    
    func searchBarCancelButtonClicked(searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        self.hideSuggestionsTable()
    }
    
}
