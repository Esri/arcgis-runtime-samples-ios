//
// Copyright 2014 ESRI
//
// All rights reserved under the copyright laws of the United States
// and applicable international laws, treaties, and conventions.
//
// You may freely redistribute and use this sample code, with or
// without modification, provided you include the original copyright
// notice and use restrictions.
//
// See the use restrictions at http://help.arcgis.com/en/sdk/10.0/usageRestrictions.htm
//

import UIKit
import ArcGIS

//url for the related records of the incident later. One incident can have multiple related records.
//They are related by the objectid of the incidents.
let kIncidentNotesLayerURL = "http://sampleserver3.arcgisonline.com/ArcGIS/rest/services/SanFrancisco/311Incidents/FeatureServer/1"

let ROW_HEIGHT:CGFloat = 60

protocol NotesViewControllerDelegate:class {
    
    func didFinishWithNotes()
}

class NotesViewController: UIViewController, AGSFeatureLayerQueryDelegate, AGSFeatureLayerEditingDelegate, UITableViewDataSource, UITableViewDelegate, AGSPopupsContainerDelegate {

    @IBOutlet weak var tableView:UITableView!
    var incidentLayer:AGSFeatureLayer!
    var incidentNotesLayer:AGSFeatureLayer!
    var incidentOID:Int!
    var relatedFeaturesResultsArray:[AGSGraphic]!
    var notesPopupVC:AGSPopupsContainerViewController!
    var loadingView:LoadingView!
    var indexPathForDeleteOperation:NSIndexPath!
    
    weak var delegate:NotesViewControllerDelegate?
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        //assigning the query delegate of the incident layer
        self.incidentLayer.queryDelegate = self
        
        //set up the incident notes layer as a feature layer. we dont have to add this to the base map as this is a related record table.
        self.incidentNotesLayer = AGSFeatureLayer(URL: NSURL(string: kIncidentNotesLayerURL), mode: .Snapshot)
        
        //we're filtering the outfields because we only want to display these two fields to the end user.
        self.incidentNotesLayer.outFields = ["agree_with_incident", "notes"]
        self.incidentNotesLayer.editingDelegate = self
        
        //query the incidents layer for the related notes.
        self.queryRelatedRecords()
        
        //setting the custom row height to accomodate the image and the text properly
        self.tableView.rowHeight = ROW_HEIGHT
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: - Table view data source
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // Return the number of sections.
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        //Or return 1 if no record exists.
        return self.relatedFeaturesResultsArray?.count ?? 1
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        //Two types of cells - Normal one for showing the related records and other for the empty cell
        let kRecordsIdentifier = "RecordCell"
        let kNoRecordsIdentifier = "NoRecordCell"
        
        var cell:UITableViewCell?
        
        if self.relatedFeaturesResultsArray != nil && self.relatedFeaturesResultsArray.count > 0 {
            cell = tableView.dequeueReusableCellWithIdentifier(kRecordsIdentifier)
            
            if cell == nil {
                cell = self.tableViewCellWithReuseIdentifier(kRecordsIdentifier)
            }
            // configureCell:cell forIndexPath: sets the text and image for the cell
            self.configureCell(cell!, forIndexPath:indexPath)
        }
        else {
            cell = tableView.dequeueReusableCellWithIdentifier(kNoRecordsIdentifier)
            if cell == nil {
                cell = UITableViewCell(style: .Default, reuseIdentifier: kNoRecordsIdentifier)
            }
            cell?.textLabel?.text = "No records found"
            cell?.accessoryType = .None
            cell?.selectionStyle = .None
        }
        return cell!
    }
    
    func tableView(tableView: UITableView, editingStyleForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCellEditingStyle {
        if self.relatedFeaturesResultsArray != nil && self.relatedFeaturesResultsArray.count > 0 {
            //users can delete a related record by swiping on the table cell.
            return .Delete
        }
        return .None
    }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        //Once the user initiates the deletion, the record is deleted from both the incidentnotes layer and the local array of features.
        let oid = self.incidentNotesLayer.objectIdForFeature(self.relatedFeaturesResultsArray[indexPath.row])
        
        if oid > 0 {
            self.loadingView = LoadingView.loadingViewInView(self.notesPopupVC.view, withText:"Deleting record...") as! LoadingView
            //feature has a valid objectid, this means it exists on the server
            //and we simply update the exisiting feature
            self.incidentNotesLayer.deleteFeaturesWithObjectIds([Int(oid)])
            //store the indexpath for updating the table view later.
            self.indexPathForDeleteOperation = indexPath
        }
    }
    
    //MARK: -
    //MARK: - Configuring table view cells
    
    let IMAGE_TAG = 1
    let NOTES_TAG = 2
    
    let LEFT_COLUMN_OFFSET:CGFloat = 10.0
    let IMAGE_SIDE:CGFloat = 30.0
    let LEFT_COLUMN_WIDTH:CGFloat = 30.0
    
    let RIGHT_COLUMN_OFFSET:CGFloat = 50.0
    let RIGHT_COLUMN_WIDTH:CGFloat = 230.0
    
    let MAIN_FONT_SIZE:CGFloat = 18.0
    let LABEL_HEIGHT:CGFloat =  26.0
    
    
    func tableViewCellWithReuseIdentifier(identifier:String) -> UITableViewCell {
        
        //Create an instance of UITableViewCell and add tagged subviews for the image and notes.
        let cell = UITableViewCell(style: .Default, reuseIdentifier: identifier)
        
        //Create label an image for the cell
        var label:UILabel!
        var rect:CGRect
        
        // Create an image view for the quarter image.
        rect = CGRectMake(LEFT_COLUMN_OFFSET, (ROW_HEIGHT - IMAGE_SIDE) / 2.0, IMAGE_SIDE, IMAGE_SIDE);
        
        let imageView = UIImageView(frame: rect)
        imageView.tag = IMAGE_TAG
        cell.contentView.addSubview(imageView)
        
        // Create a label for the time zone name.
        rect = CGRectMake(RIGHT_COLUMN_OFFSET, (ROW_HEIGHT - LABEL_HEIGHT) / 2.0, RIGHT_COLUMN_WIDTH, LABEL_HEIGHT)
        label = UILabel(frame: rect)
        label.tag = NOTES_TAG
        label.font = UIFont.boldSystemFontOfSize(MAIN_FONT_SIZE)
        label.adjustsFontSizeToFitWidth = false
        label.autoresizingMask = .FlexibleWidth
        cell.contentView.addSubview(label)
        label.highlightedTextColor = UIColor.whiteColor()
        
        cell.accessoryType = .DisclosureIndicator
        cell.selectionStyle = .Blue
        
        return cell
    }
    
    
    //this method fills the appropriate info in the cells according to the fields.
    func configureCell(cell:UITableViewCell, forIndexPath indexPath:NSIndexPath) {
        
        let note = self.relatedFeaturesResultsArray[indexPath.row]
        
        //checks whether the agree with incident field is a 1 or 0 and fills the image accordingly.
        let agree = note.attributeAsBoolForKey("agree_with_incident", exists:nil)
        var image:UIImage!
        if !agree {
            image = UIImage(named: "Disagree.png")
        }
        else {
            image = UIImage(named: "Agree.png")
        }
        
        // Set the image.
        let imageView = cell.viewWithTag(IMAGE_TAG) as! UIImageView
        imageView.image = image
        
        //assigns the notes text to the notes field.
        let notesText = note.attributeAsStringForKey("notes")
        
        // Set the notes text.
        let label = cell.viewWithTag(NOTES_TAG) as! UILabel
        label.text = notesText
    }
    
    //MARK: - Table view delegate
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if self.relatedFeaturesResultsArray != nil && self.relatedFeaturesResultsArray.count > 0 {
            //deselect the row first
            self.tableView.deselectRowAtIndexPath(indexPath, animated:false)
            
            //retrieve the corresponding note graphic from the array.
            let note = self.relatedFeaturesResultsArray[indexPath.row]
            
            //make note part of the feature layer's graphics collection (it is a table, so it wont be displayed, but this needed
            //so that field metadata is inspected when creating popup definition for the note)
            self.incidentNotesLayer.addGraphic(note)
            
            //create a popup info.
            let info = AGSPopupInfo(forGraphic: note)
            
            //setup the notes popup
            self.notesPopupVC = AGSPopupsContainerViewController(popupInfo: info, graphic: note, usingNavigationControllerStack: false)
            self.notesPopupVC.delegate = self
            self.notesPopupVC.style = .Default
            self.notesPopupVC.modalTransitionStyle =  .CoverVertical
            
            //If iPad, use a modal presentation style
            if AGSDevice.currentDevice().isIPad() {
                self.notesPopupVC.modalPresentationStyle = .FormSheet
            }
            self.presentViewController(self.notesPopupVC, animated:true, completion:nil)
            
            //set the popup's editing mode
            self.notesPopupVC.startEditingCurrentPopup()
        }
    
    
    }
    
    //MARK: -  AGSPopupsContainerDelegate methods
    
    func popupsContainer(popupsContainer: AGSPopupsContainer!, didFinishEditingForPopup popup: AGSPopup!) {
    
        let oid = self.incidentNotesLayer.objectIdForFeature(popup.graphic)
        if oid > 0 {
            //feature has a valid objectid, this means it exists on the server
            //and we simply update the exisiting feature
            self.incidentNotesLayer.updateFeatures([popup.graphic])
        } else {
            //objectid does not exist, this means we need to add it as a new feature
            self.incidentNotesLayer.addFeatures([popup.graphic])
        }
        
        //Tell the user edits are being saved int the background
        self.loadingView = LoadingView.loadingViewInView(self.notesPopupVC.view, withText:"Saving Notes...") as! LoadingView
    
    }
    
    func popupsContainer(popupsContainer: AGSPopupsContainer!, didCancelEditingForPopup popup: AGSPopup!) {

        //dismiss the popups view controller
        self.dismissViewControllerAnimated(true, completion:nil)
        
        self.notesPopupVC = nil
    }
    
    //MARK: - AGSFeatureLayerQueryDelegate methods
    
    func featureLayer(featureLayer: AGSFeatureLayer!, operation op: NSOperation!, didFailQueryRelatedFeaturesWithError error: NSError!) {
        self.loadingView.removeView()
        self.warnUserOfErrorWithMessage("Could not perform query. Please try again")
        print("Error querying notes : \(error)")
    }
    
    func featureLayer(featureLayer: AGSFeatureLayer!, operation op: NSOperation!, didQueryRelatedFeaturesWithResults relatedFeatures: [NSObject : AnyObject]!) {
        //remove the loading view
        self.loadingView.removeView()
        
        //if the related records already exist we fill the related feature array with the features from the dictionary's result set.
        if relatedFeatures.count > 0 {
            print("Yes, we have related records for this incident")
            let resultsSet = relatedFeatures[self.incidentOID] as! AGSFeatureSet
            self.relatedFeaturesResultsArray  =  resultsSet.features as! [AGSGraphic]
        }
        else {
            self.relatedFeaturesResultsArray  =  [AGSGraphic]()
        }
        
        self.tableView.reloadData()
    }
    
    //MARK: - AGSFeatureLayerEditingDelegate methods
    
    func featureLayer(featureLayer: AGSFeatureLayer!, operation op: NSOperation!, didFeatureEditsWithResults editResults: AGSFeatureLayerEditResults!) {
    
        self.loadingView.removeView()
        
        if let addResults = editResults.addResults where addResults.count > 0 {
            //we were adding a new feature
            let result = addResults[0] as! AGSEditResult
            if !result.success {
                //Inform user
                self.warnUserOfErrorWithMessage("Could not add feature. Please try again")
            }
            else
            {
                //also update the local features array for the table view.
                self.relatedFeaturesResultsArray.append(self.notesPopupVC.currentPopup.graphic)
                
                //dismiss the popup view controller
                self.dismissViewControllerAnimated(true, completion:nil)
                
                self.notesPopupVC = nil
            }
            
        }
        else if let updateResults = editResults.updateResults where updateResults.count > 0 {
            //we were updating a feature
            let result = updateResults[0] as! AGSEditResult
            if !result.success {
                //Inform user
                self.warnUserOfErrorWithMessage("Could not update feature. Please try again")
            }
            else
            {
                //dismiss the popup view controller
                self.dismissViewControllerAnimated(true, completion:nil)
                
                self.notesPopupVC = nil
            }
        }
        else if let deleteResults = editResults.deleteResults where deleteResults.count > 0 {
            let result = deleteResults[0] as! AGSEditResult
            if !result.success {
                //Delete operation failed. Inform user
                self.warnUserOfErrorWithMessage("Could not delete feature. Please try again")
            }
            else
            {
                //also update the local features array for the table view.
                self.relatedFeaturesResultsArray.removeAtIndex(self.indexPathForDeleteOperation.row)
            }
        }
        
        //reload the tableview to show new data.
        self.tableView.reloadData()
    }
    
    func featureLayer(featureLayer: AGSFeatureLayer!, operation op: NSOperation!, didFailFeatureEditsWithError error: NSError!) {
        print("Could not commit edits because: \(error.localizedDescription)")
        self.loadingView.removeView()
        self.warnUserOfErrorWithMessage("Could not save edits. Please try again")
    }
    
    
    
    
    //MARK: - Action Methods
    
    func addNewNote() {
        
        //create a new feature with the template available from the notes layer.
        let note = self.incidentNotesLayer.featureWithTemplate(self.incidentNotesLayer.templates[0] as! AGSFeatureTemplate)
        
        //set the relevant attributes
        //we are setting the ID of  source incident to establish  a relationship between the note  and the incident
        note.setAttributeWithInt(Int32(self.incidentOID), forKey:"sf_311_serviceoid")
        
        //set the default value for the relevant fields. "Yes" for "agree_with_incident" and empty string for notes.
        note.setAttributeWithInt(1, forKey:"agree_with_incident")
        note.setAttributeWithString("", forKey:"notes")
        
        //make note part of the feature layer's graphics collection (it is a table, so it wont be displayed, but this needed
        //so that field metadata is inspected when creating popup definition for the note)
        self.incidentNotesLayer.addGraphic(note)
        
        let info = AGSPopupInfo(forGraphic: note)
        let notePopup = AGSPopup(graphic: note, popupInfo: info)
        
        //The note will not contain any geometry information, hence, don't show user the geometry button in the popup
        notePopup.allowEditGeometry = false
        
        
        
        self.notesPopupVC = AGSPopupsContainerViewController(popups: [notePopup], usingNavigationControllerStack:false)
        self.notesPopupVC.delegate = self
        self.notesPopupVC.style = .Default
        self.notesPopupVC.modalTransitionStyle = .CoverVertical
        
        //If iPad, use a modal presentation style
        if AGSDevice.currentDevice().isIPad() {
            self.notesPopupVC.modalPresentationStyle = .FormSheet
        }
        self.presentViewController(self.notesPopupVC, animated:true, completion:nil)
        self.notesPopupVC.startEditingCurrentPopup()
    }
    
    func done() {
        self.delegate?.didFinishWithNotes()
    }
    
    //MARK: - Helper
    
    func warnUserOfErrorWithMessage(message:String) {
        //Display an alert to the user
        UIAlertView(title: "Error", message: message, delegate: nil, cancelButtonTitle: "Ok").show()
    }
    
    //query the related notes of an incident
    func queryRelatedRecords() {
        
        //Prepare the relationship query
        let query = AGSRelationshipQuery()
        
        //ObjectID of source feature
        query.objectIds = [self.incidentOID]
        
        //Fields of target feature
        query.outFields = ["*"]
        
        //Relationship to query
        query.relationshipId = 1
        
        //Only get related records. This field is necessary and would require a dummy expression to pass
        query.definitionExpression = "1=1"
        
        //Perform query
        let op = self.incidentLayer.queryRelatedFeatures(query) as! AGSJSONRequestOperation
        op.state.setObject(self.incidentOID, forKey:"objectid")
        
        //show the loading view to indicate the process
        self.loadingView = LoadingView.loadingViewInView(self.view, withText: "Querying related records...") as! LoadingView
    }
}
