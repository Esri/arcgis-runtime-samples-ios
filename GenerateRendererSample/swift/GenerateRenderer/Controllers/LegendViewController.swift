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

import UIKit
import ArcGIS

protocol LegendViewControllerDelegate:class {
    //notifies the delegate that the renderer was generated successfully
    func legendViewController(legendViewController:LegendViewController, didGenerateRenderer renderer:AGSRenderer)
    //notifies the delegate it failed to generate renderer with the error
    func legendViewController(legendViewController:LegendViewController, failedToGenerateRendererWithError error:NSError)
}

class LegendViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate, OptionsViewControllerDelegate {
    
    @IBOutlet weak var tableView:UITableView!
    @IBOutlet weak var footerView:UIView!
    @IBOutlet weak var segmentedControl:UISegmentedControl!
    
    @IBOutlet weak var classificationTextField:UITextField!
    @IBOutlet weak var methodTextField:UITextField!
    @IBOutlet weak var algorithmTextField:UITextField!
    @IBOutlet weak var classCountSlider:UISlider!
    @IBOutlet weak var classCountTextField:UITextField!
    @IBOutlet weak var normalizationTextField:UITextField!
    
    @IBOutlet weak var normalizationLabel:UILabel!
    @IBOutlet weak var classesLabel:UILabel!
    @IBOutlet weak var methodLabel:UILabel!
    
    weak var delegate:LegendViewControllerDelegate?
    
    var classificationFields:[AGSField]! {
        didSet {
            //create the classbreak and unique value arrays
            self.createIndividualArrays()
            //once the arrays are loaded
            //set all the fields to default values
            self.setToDefaults()
        }
    }
    
    //array used to store classification fields that can be used for class break rendering
    var classBreakClassificationFields:[AGSField]!
    //array used to store classification fields that can be used for unique value rendering
    var uniqueValueClassificationFields:[AGSField]!
    
    var generateRendererTask:AGSGenerateRendererTask!
    var classificationMethods:[String]!
    var colorRampAlgorithms:[String]!
    
    var selectedFieldIndex:Int! {
        didSet {
            //update the value in the classificationTextField based on
            //whether classbreak or unique value renderer is selected
            var selectedField:AGSField!
            if self.segmentedControl.selectedSegmentIndex == 0 {
                selectedField = self.classBreakClassificationFields[selectedFieldIndex]
            }
            else {
                selectedField = self.uniqueValueClassificationFields[selectedFieldIndex]
            }
            self.classificationTextField.text = selectedField.name
        }
    }
    var selectedNormalizationIndex:Int! {
        didSet {
            //update the value in the normalizationTextField
            //also showing a value None for no normalization
            if selectedNormalizationIndex == 0 {
                self.normalizationTextField.text = NONE_FIELD_VALUE
            }
            else {
                let selectedField = self.classBreakClassificationFields[self.selectedNormalizationIndex - 1]
                self.normalizationTextField.text = selectedField.name
            }
        }
    }
    var selectedMethodIndex:Int! {
        didSet {
            //update the value in the methodTextField
            self.methodTextField.text = self.classificationMethods[selectedMethodIndex]
        }
    }
    var selectedAlgorithmIndex:Int! {
        didSet {
            //update the value in the algorithmTextField
            self.algorithmTextField.text = self.colorRampAlgorithms[selectedAlgorithmIndex]
        }
    }
    var selectedClassCount:Int! {
        didSet {
            //update the value in the classCountTextField
            //also generate renderer based on the new value
            var flag = false
            if oldValue == nil {
                flag = true
            }
            else {
                if oldValue != self.selectedClassCount {
                    flag = true
                }
            }
            
            if flag {
                self.classCountTextField.text = "\(Int(selectedClassCount))"
                self.generateRenderer()
            }
        }
    }
    
    var uniqueValueRenderer:AGSUniqueValueRenderer! {
        didSet {
            //reload the table view data
            //to reflect new values
            self.tableView.reloadData()
        }
    }
    var classBreakRenderer:AGSClassBreaksRenderer! {
        didSet {
            //reload the table view data
            //to reflect new values
            self.tableView.reloadData()
        }
    }
    
    var lastRendererOperation:AGSCancellable!
    var popOverController:UIPopoverController!
    var optionsViewController:OptionsViewController!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.classificationMethods = ["Natural Breaks (Jenks)", "Equal Interval", "Quantile", "Standard Deviation", "Geometrical Interval"]
        self.colorRampAlgorithms = ["HSV", "CIE Lab", "Lab LCh"]
        
        //add the info button image as the right view on the text fields
        //to indicate it is interactable
        self.addRightViewForTextFields()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: - Private methods
    
    //populate classBreakClassificationFields and uniqueValueClassificationFields arrays
    //with all possible values from the classificationFields array
    func createIndividualArrays() {
        var uniqueValueClassificationFields = [AGSField]()
        var classBreakClassificationFields = [AGSField]()
        for field in self.classificationFields {
            if field.type.rawValue >= 0 && field.type.rawValue <= 3 {
                classBreakClassificationFields.append(field)
            }
            
            if field.type.rawValue >= 0 && field.type.rawValue <= 5 {
                uniqueValueClassificationFields.append(field)
            }
        }
        self.classBreakClassificationFields = classBreakClassificationFields
        self.uniqueValueClassificationFields = uniqueValueClassificationFields
    }
    
    //set the fields to default values
    func setToDefaults() {
        self.selectedFieldIndex = 0
        self.selectedNormalizationIndex = 0
        self.selectedMethodIndex = 0
        self.selectedAlgorithmIndex = 0
        self.classCountSlider.value = 3
        self.selectedClassCount = 3
        self.generateRenderer()
    }
    
    //show the footer view as a loading indicator
    func showLoadingFooterView() {
        self.footerView.hidden = false
    }
    
    //hide the footer view
    func hideLoadingFooterView() {
        self.footerView.hidden = true
    }
    
    //method to disable or enable the class count label, textField and slider
    //based on whether the standard deviation is selected as the method for classification
    func updateClassCountFieldStatus() {
        let enabled = !(self.selectedMethodIndex == 3)
        
        self.classCountSlider.enabled = enabled
        self.classCountSlider.alpha = enabled ? 1 : 0.3
        self.classCountTextField.alpha = enabled ? 1 : 0.3
        self.classesLabel.alpha = enabled ? 1 : 0.3
    }
    
    //add the info button image as right view for all textfields
    //as an indicator for interaction
    func addRightViewForTextFields() {
        self.addRightViewForTextField(self.classificationTextField)
        self.addRightViewForTextField(self.normalizationTextField)
        self.addRightViewForTextField(self.methodTextField)
        self.addRightViewForTextField(self.algorithmTextField)
    }
    
    //add the info button image as right view for specified textfield
    //as an indicator for interaction
    func addRightViewForTextField(textField:UITextField) {
        let rightView = UIView(frame: CGRect(x: 0, y: 0, width: 22, height: 22))
        rightView.userInteractionEnabled = false
        
        let imageView = UIImageView(image: UIImage(named: "InfoIcon"))
        rightView.addSubview(imageView)
        imageView.center = rightView.center
        
        textField.rightView = rightView
        textField.rightViewMode = .Always
    }
    
    //returns an array of NSString with names of the AGSFields
    //from the passed array
    func namesArrayFromFieldsArray(fields:[AGSField]) -> [String] {
        var namesArray = [String]()
        for field in fields {
            namesArray.append(field.name)
        }
        return namesArray
    }
    
    //MARK: - Public methods
    
    //returns the name of the currently selected classification field
    func selectedFieldName() -> String {
        return self.classificationTextField.text!
    }
    
    //MARK: - actions
    
    //change in the selected class count
    @IBAction func sliderValueChanged(sender:UISlider) {
        self.selectedClassCount = Int(sender.value)
    }
    
    //hide or display fields when switching between the two types of renderers
    @IBAction func segmentControlValueChanged(sender:UISegmentedControl) {
        //if changed to unique value then disable classes and method
        //and vice versa
        let enabled = sender.selectedSegmentIndex == 0
        
        self.normalizationTextField.enabled = enabled
        self.classCountSlider.enabled = enabled
        self.methodTextField.enabled = enabled
        
        self.normalizationLabel.alpha = enabled ? 1 : 0.3
        self.normalizationTextField.alpha = enabled ? 1 : 0.3
        self.classCountSlider.alpha = enabled ? 1 : 0.3
        self.classCountTextField.alpha = enabled ? 1 : 0.3
        self.methodTextField.alpha = enabled ? 1 : 0.3
        self.classesLabel.alpha = enabled ? 1 : 0.3
        self.methodLabel.alpha = enabled ? 1 : 0.3
        
        //update renderer
        self.setToDefaults()
    }
    
    //MARK: - table view data source
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    //number of rows based on the currently selected section
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if self.segmentedControl.selectedSegmentIndex == 0 {
            if self.classBreakRenderer != nil {
                return self.classBreakRenderer.classBreaks.count
            }
        }
        else {
            if self.uniqueValueRenderer != nil {
                return self.uniqueValueRenderer.uniqueValues.count
            }
        }
        return 0
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cellIdentifier = "LegendCell"
        let cell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier) as! LegendCell
        
        if self.segmentedControl.selectedSegmentIndex == 0 {
            let classBreak = self.classBreakRenderer.classBreaks[indexPath.row] as! AGSClassBreak
            cell.colorView.backgroundColor = classBreak.symbol.color
            cell.label.text = classBreak.label
        }
        else {
            let value = self.uniqueValueRenderer.uniqueValues[indexPath.row] as! AGSUniqueValue
            cell.colorView.backgroundColor = value.symbol.color
            cell.label.text = value.label
        }
        cell.backgroundColor = UIColor.clearColor()
        return cell
    }
    
    //MARK: - Renderer logic
    
    //method used to generate renderer using the selected
    //values in the UI
    func generateRenderer() {
        self.showLoadingFooterView()
        
        //initialize the generateRendererTask if not already done
        if self.generateRendererTask == nil {
            let url = NSURL(string: FEATURE_SERVICE_URL)
            self.generateRendererTask = AGSGenerateRendererTask(URL: url)
        }
        
        var definition:AGSClassificationDefinition!
        var field:AGSField!
        
        let fromColor = UIColor(red: 1, green: 1, blue: 1, alpha: 1)
        let toColor = UIColor(red: 0, green: 104/255.0, blue: 55.0/255.0, alpha: 1)
        //creating a base color ramp
        let gradientRamp = AGSAlgorithmicColorRamp(fromColor: fromColor, toColor: toColor, algorithm: AGSColorRampAlgorithm(rawValue: self.selectedAlgorithmIndex)!)
        if self.segmentedControl.selectedSegmentIndex == 0 {
            //assign nil to the renderer in order to clear table rows
            self.classBreakRenderer = nil
            
            //Class break renderer to be generated using the following definition
            field = self.classBreakClassificationFields[self.selectedFieldIndex]
            definition = AGSClassBreaksDefinition(classificationField: field.name, classificationMethod: AGSClassBreaksDefinitionClassificationMethod(rawValue: self.selectedMethodIndex)!, breakCount: UInt(self.selectedClassCount))
            definition.colorRamp = gradientRamp
            (definition as! AGSClassBreaksDefinition).standardDeviationInterval = 1
            if self.selectedNormalizationIndex > 0 {
                let selectedNormalizationField = self.classBreakClassificationFields[self.selectedNormalizationIndex-1]
                (definition as! AGSClassBreaksDefinition).normalizationField = selectedNormalizationField.name
                (definition as! AGSClassBreaksDefinition).normalizationType = .ByField
            }
        }
        else {
            //assign nil to the renderer in order to clear table rows
            self.uniqueValueRenderer = nil
            
            //Unique value renderer to be generated using the following definition
            field = self.uniqueValueClassificationFields[self.selectedFieldIndex]
            definition = AGSUniqueValueDefinition(uniqueValueFields: [field.name])
            definition.colorRamp = gradientRamp
        }
        
        //cancel the previous generate renderer request
        if self.lastRendererOperation != nil {
            self.lastRendererOperation.cancel()
        }
        
        //using the where clause to specify the counties in the california
        let rendererParams = AGSGenerateRendererParameters(classificationDefinition: definition, whereClause: "state_name = 'California'")
        self.lastRendererOperation = self.generateRendererTask.generateRendererWithParameters(rendererParams, completion: { [weak self] (renderer:AGSRenderer!, error:NSError!) -> Void in
            if let weakSelf = self {
                if error != nil {
                    //failed to generate renderer with an error
                    weakSelf.delegate?.legendViewController(weakSelf, failedToGenerateRendererWithError:error)
                }
                else if renderer != nil {
                    //assign the renderer based on the segment selected
                    //hide the footer view
                    //notify the delegate
                    if weakSelf.segmentedControl.selectedSegmentIndex == 0 {
                        weakSelf.classBreakRenderer = renderer as! AGSClassBreaksRenderer
                    }
                    else {
                        weakSelf.uniqueValueRenderer = renderer as! AGSUniqueValueRenderer
                    }
                    weakSelf.hideLoadingFooterView()
                    
                    weakSelf.delegate?.legendViewController(weakSelf, didGenerateRenderer:renderer)
                }
            }
        })
    }

    //MARK: - UITextField delegates
    
    //using the textField delegate to display the popover view controller instead of the keyboard
    //and based on the textfield selected passing the corresponding options
    func textFieldShouldBeginEditing(textField: UITextField) -> Bool {
        
        var options:[String]!
        if textField == self.classificationTextField {
            if self.segmentedControl.selectedSegmentIndex == 0 {
                options = self.namesArrayFromFieldsArray(self.classBreakClassificationFields)
            }
            else {
                options = self.namesArrayFromFieldsArray(self.uniqueValueClassificationFields)
            }
        }
        else if textField == self.normalizationTextField {
            var temp = self.namesArrayFromFieldsArray(self.classBreakClassificationFields)
            temp.insert(NONE_FIELD_VALUE, atIndex:0)
            options = temp
        }
        else if textField == self.methodTextField {
            options = self.classificationMethods
        }
        else if textField == self.algorithmTextField {
            options = self.colorRampAlgorithms
        }
        
        self.showPopOverController(options, forTextField:textField)
        return false
    }
    
    //MARK: - OptionsViewControllerDelegate Delegate
    
    //updating the selection index for the textField passed and generating a new renderer
    func optionsViewController(optionsViewController: OptionsViewController, didSelectIndex index: (NSInteger), forTextField textField: (UITextField)) {
        if textField == self.classificationTextField {
            self.selectedFieldIndex = index
        }
        else if textField == self.normalizationTextField {
            self.selectedNormalizationIndex = index
        }
        else if textField == self.methodTextField {
            self.selectedMethodIndex = index
            self.updateClassCountFieldStatus()
        }
        else if textField == self.algorithmTextField {
            self.selectedAlgorithmIndex = index
        }
        self.generateRenderer()
    }
    
    func showPopOverController(options:[String], forTextField textField:UITextField) {
        //using pop over controller to show options for each text field
        //the pop over controller contains the optionsViewController as a tableView controller
        //with all the possible values for that textField
        if self.optionsViewController == nil {
            self.optionsViewController = OptionsViewController()
            //using the legendViewController as the delegate for the optionsViewController
            self.optionsViewController.delegate = self
        }
        if (self.popOverController == nil) {
            self.popOverController = UIPopoverController(contentViewController: self.optionsViewController)
            self.popOverController.popoverContentSize = CGSize(width: 240, height: 200)
        }
        
        self.optionsViewController.textField = textField
        self.optionsViewController.options = options
        
        //use the frame of the textField as the origination rect for the pop over controller
        let textFieldRect = textField.frame
        self.popOverController.presentPopoverFromRect(textFieldRect, inView:self.view, permittedArrowDirections:.Left, animated:true)
    }
}
