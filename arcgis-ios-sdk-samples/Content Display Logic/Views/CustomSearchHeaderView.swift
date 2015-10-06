//
//  CustomSeachHeaderView.swift
//  arcgis-ios-sdk-samples
//
//  Created by Gagandeep Singh on 10/2/15.
//  Copyright © 2015 Esri. All rights reserved.
//

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
}
