/*
 Copyright 2014 Esri
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */

#import "LegendViewController.h"
#import <ArcGIS/ArcGIS.h>
#import "LegendCell.h"
#import "AppConstants.h"

@interface LegendViewController () <UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIView *footerView;
@property (weak, nonatomic) IBOutlet UISegmentedControl *segmentedControl;

@property (weak, nonatomic) IBOutlet UITextField *classificationTextField;
@property (weak, nonatomic) IBOutlet UITextField *methodTextField;
@property (weak, nonatomic) IBOutlet UITextField *algorithmTextField;
@property (weak, nonatomic) IBOutlet UISlider *classCountSlider;
@property (weak, nonatomic) IBOutlet UITextField *classCountTextField;
@property (weak, nonatomic) IBOutlet UITextField *normalizationTextField;

@property (weak, nonatomic) IBOutlet UILabel *normalizationLabel;
@property (weak, nonatomic) IBOutlet UILabel *classesLabel;
@property (weak, nonatomic) IBOutlet UILabel *methodLabel;

//array used to store classification fields that can be used for class break rendering
@property (nonatomic, strong) NSArray *classBreakClassificationFields;
//array used to store classification fields that can be used for unique value rendering
@property (nonatomic, strong) NSArray *uniqueValueClassificationFields;

@property (nonatomic, strong) AGSGenerateRendererTask *generateRendererTask;
@property (nonatomic, strong) NSArray *classificationMethods;
@property (nonatomic, strong) NSArray *colorRampAlgorithms;

@property (nonatomic, assign) NSInteger selectedFieldIndex;
@property (nonatomic, assign) NSInteger selectedNormalizationIndex;
@property (nonatomic, assign) NSInteger selectedMethodIndex;
@property (nonatomic, assign) NSInteger selectedAlgorithmIndex;
@property (nonatomic, assign) NSInteger selectedClassCount;

@property (nonatomic, strong) AGSUniqueValueRenderer *uniqueValueRenderer;
@property (nonatomic, strong) AGSClassBreaksRenderer *classBreakRenderer;

@property (nonatomic, weak) id<AGSCancellable> lastRendererOperation;

@property (nonatomic, strong) UIPopoverController *popOverController;
@property (nonatomic, strong) OptionsViewController *optionsViewController;

@end

@implementation LegendViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.classificationMethods = @[@"Natural Breaks (Jenks)", @"Equal Interval", @"Quantile", @"Standard Deviation", @"Geometrical Interval"];
    self.colorRampAlgorithms = @[@"HSV", @"CIE Lab", @"Lab LCh"];
    
    //add the info button image as the right view on the text fields
    //to indicate it is interactable
    [self addRightViewForTextFields];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - setter methods

//setter method for classificationFields array
-(void)setClassificationFields:(NSArray *)classificationFields {
    _classificationFields = classificationFields;
    //create the classbreak and unique value arrays
    [self createIndividualArrays];
    //once the arrays are loaded
    //set all the fields to default values
    [self setToDefaults];
}

//setter method for uniqueValue renderer
-(void)setUniqueValueRenderer:(AGSUniqueValueRenderer *)uniqueValueRenderer {
    _uniqueValueRenderer = uniqueValueRenderer;
    //reload the table view data
    //to reflect new values
    [self.tableView reloadData];
}

//setter method for class break renderer
-(void)setClassBreakRenderer:(AGSClassBreaksRenderer *)classBreakRenderer {
    _classBreakRenderer = classBreakRenderer;
    //reload the table view data
    //to reflect new values
    [self.tableView reloadData];
}

//setter method for selectedFieldIndex
//update the value in the classificationTextField based on
//whether classbreak or unique value renderer is selected
-(void)setSelectedFieldIndex:(NSInteger)selectedFieldIndex {
    _selectedFieldIndex = selectedFieldIndex;
    
    AGSField *selectedField;
    if (self.segmentedControl.selectedSegmentIndex == 0) {
        selectedField = [self.classBreakClassificationFields objectAtIndex:selectedFieldIndex];
    }
    else {
        selectedField = [self.uniqueValueClassificationFields objectAtIndex:selectedFieldIndex];
    }
    self.classificationTextField.text = selectedField.name;
}

//setter method for selectedNormalizationIndex
//update the value in the normalizationTextField
//also showing a value None for no normalization
-(void)setSelectedNormalizationIndex:(NSInteger)selectedNormalizationIndex {
    _selectedNormalizationIndex = selectedNormalizationIndex;

    if (selectedNormalizationIndex == 0) {
        self.normalizationTextField.text = NONE_FIELD_VALUE;
    }
    else {
        AGSField *selectedField = [self.classBreakClassificationFields objectAtIndex:self.selectedNormalizationIndex - 1];
        self.normalizationTextField.text = selectedField.name;
    }
}

//setter method for selectedMethodIndex
//update the value in the methodTextField
-(void)setSelectedMethodIndex:(NSInteger)selectedMethodIndex {
    _selectedMethodIndex = selectedMethodIndex;
    
    self.methodTextField.text = [self.classificationMethods objectAtIndex:selectedMethodIndex];
}

//setter method for selectedAlgorithmIndex
//update the value in the algorithmTextField
-(void)setSelectedAlgorithmIndex:(NSInteger)selectedAlgorithmIndex {
    _selectedAlgorithmIndex = selectedAlgorithmIndex;
    
    self.algorithmTextField.text = [self.colorRampAlgorithms objectAtIndex:selectedAlgorithmIndex];
}

//setter mthod for selectedClassCount
//update the value in the classCountTextField
//also generate renderer based on the new value
-(void)setSelectedClassCount:(NSInteger)selectedClassCount {
    if (_selectedClassCount != selectedClassCount) {
        _selectedClassCount = selectedClassCount;
        
        self.classCountTextField.text = [NSString stringWithFormat:@"%ld", (long)selectedClassCount];
        [self generateRenderer];
    }
}

#pragma mark - Private methods

//populate classBreakClassificationFields and uniqueValueClassificationFields arrays
//with all possible values from the classificationFields array
-(void)createIndividualArrays {
    NSMutableArray *uniqueValueClassificationFields = [NSMutableArray array];
    NSMutableArray *classBreakClassificationFields = [NSMutableArray array];
    for (AGSField *field in self.classificationFields) {
        if (field.type >= 0 && field.type <= 3) {
            [classBreakClassificationFields addObject:field];
        }
        
        if (field.type >= 0 && field.type <= 5) {
            [uniqueValueClassificationFields addObject:field];
        }
    }
    self.classBreakClassificationFields = classBreakClassificationFields;
    self.uniqueValueClassificationFields = uniqueValueClassificationFields;
}

//set the fields to default values
-(void)setToDefaults {
    self.selectedFieldIndex = self.selectedNormalizationIndex = self.selectedMethodIndex = self.selectedAlgorithmIndex = 0;
    self.classCountSlider.value = self.selectedClassCount = 3;
    [self generateRenderer];
}

//show the footer view as a loading indicator
-(void)showLoadingFooterView {
    self.footerView.hidden = false;
}

//hide the footer view
-(void)hideLoadingFooterView {
    self.footerView.hidden = true;
}

//method to disable or enable the class count label, textField and slider
//based on whether the standard deviation is selected as the method for classification
-(void)updateClassCountFieldStatus {
    BOOL enabled = !(self.selectedMethodIndex == 3);
    
    self.classCountSlider.enabled = enabled;
    self.classCountSlider.alpha = enabled ? 1 : 0.3;
    self.classCountTextField.alpha = enabled ? 1 : 0.3;
    self.classesLabel.alpha = enabled ? 1 : 0.3;
}

//add the info button image as right view for all textfields
//as an indicator for interaction
-(void)addRightViewForTextFields {
    [self addRightViewForTextField:self.classificationTextField];
    [self addRightViewForTextField:self.normalizationTextField];
    [self addRightViewForTextField:self.methodTextField];
    [self addRightViewForTextField:self.algorithmTextField];
}

//add the info button image as right view for specified textfield
//as an indicator for interaction
-(void)addRightViewForTextField:(UITextField*)textField {
    UIView *rightView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 22, 22)];
    [rightView setUserInteractionEnabled:NO];
    
    UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"InfoIcon"]];
    [rightView addSubview:imageView];
    imageView.center = rightView.center;
    
    [textField setRightView:rightView];
    [textField setRightViewMode:UITextFieldViewModeAlways];
}

//returns an array of NSString with names of the AGSFields
//from the passed array
-(NSArray*)namesArrayFromFieldsArray:(NSArray*)fields {
    NSMutableArray *namesArray = [NSMutableArray arrayWithCapacity:fields.count];
    for (AGSField *field in fields) {
        [namesArray addObject:field.name];
    }
    return namesArray;
}

#pragma mark - Public methods

//returns the name of the currently selected classification field
-(NSString*)selectedFieldName {
    return self.classificationTextField.text;
}

#pragma mark - actions 

//change in the selected class count
- (IBAction)sliderValueChanged:(UISlider*)sender {
    self.selectedClassCount = (int)sender.value;
}

//hide or display fields when switching between the two types of renderers
- (IBAction)segmentControlValueChanged:(UISegmentedControl*)sender {
    //if changed to unique value then disable classes and method
    //and vice versa
    BOOL enabled = sender.selectedSegmentIndex == 0;
    
    self.normalizationTextField.enabled = enabled;
    self.classCountSlider.enabled = enabled;
    self.methodTextField.enabled = enabled;
    
    self.normalizationLabel.alpha = enabled ? 1 : 0.3;
    self.normalizationTextField.alpha = enabled ? 1 : 0.3;
    self.classCountSlider.alpha = enabled ? 1 : 0.3;
    self.classCountTextField.alpha = enabled ? 1 : 0.3;
    self.methodTextField.alpha = enabled ? 1 : 0.3;
    self.classesLabel.alpha = enabled ? 1 : 0.3;
    self.methodLabel.alpha = enabled ? 1 : 0.3;
    
    //update renderer
    [self setToDefaults];
}


#pragma mark - table view data source

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

//number of rows based on the currently selected section
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (self.segmentedControl.selectedSegmentIndex == 0) {
        return self.classBreakRenderer.classBreaks.count;
    }
    else {
        return self.uniqueValueRenderer.uniqueValues.count;
    }
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *cellIdentifier = @"LegendCell";
    LegendCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    if (self.segmentedControl.selectedSegmentIndex == 0) {
        AGSClassBreak *classBreak = [self.classBreakRenderer.classBreaks objectAtIndex:indexPath.row];
        cell.colorView.backgroundColor = classBreak.symbol.color;
        cell.label.text = classBreak.label;
    }
    else {
        AGSUniqueValue *value = [self.uniqueValueRenderer.uniqueValues objectAtIndex:indexPath.row];
        cell.colorView.backgroundColor = value.symbol.color;
        cell.label.text = value.label;
    }
    cell.backgroundColor = [UIColor clearColor];
    return cell;
}

#pragma mark - Renderer logic

//method used to generate renderer using the selected
//values in the UI
- (void)generateRenderer {
    [self showLoadingFooterView];
    
    //initialize the generateRendererTask if not already done
    if (!self.generateRendererTask) {
        NSURL *url = [NSURL URLWithString:FEATURE_SERVICE_URL];
        self.generateRendererTask = [AGSGenerateRendererTask generateRendererTaskWithURL:url];
    }
    
    AGSClassificationDefinition *definition;
    AGSField *field;
    //creating a base color ramp
    AGSAlgorithmicColorRamp *gradientRamp = [[AGSAlgorithmicColorRamp alloc] initWithFromColor:[UIColor colorWithRed:1 green:1 blue:204/255.0 alpha:1]
                                                                                       toColor:[UIColor colorWithRed:0 green:104/255.0 blue:55/255.0 alpha:1]
                                                                                     algorithm:self.selectedAlgorithmIndex];
    if (self.segmentedControl.selectedSegmentIndex == 0) {
        //assign nil to the renderer in order to clear table rows
        self.classBreakRenderer = nil;
        
        //Class break renderer to be generated using the following definition
        field = [self.classBreakClassificationFields objectAtIndex:self.selectedFieldIndex];
        definition = [AGSClassBreaksDefinition classBreaksDefinitionWithClassificationField:field.name
                                                                        classificationMethod:self.selectedMethodIndex
                                                                        breakCount:self.selectedClassCount];
        definition.colorRamp = gradientRamp;
        ((AGSClassBreaksDefinition*)definition).standardDeviationInterval = 1;
        if (self.selectedNormalizationIndex > 0) {
            AGSField *selectedNormalizationField = [self.classBreakClassificationFields objectAtIndex:self.selectedNormalizationIndex-1];
            ((AGSClassBreaksDefinition*)definition).normalizationField = selectedNormalizationField.name;
            ((AGSClassBreaksDefinition*)definition).normalizationType = AGSClassBreaksDefinitionNormalizationTypeByField;
        }
    }
    else {
        //assign nil to the renderer in order to clear table rows
        self.uniqueValueRenderer = nil;
        
        //Unique value renderer to be generated using the following definition
        field = [self.uniqueValueClassificationFields objectAtIndex:self.selectedFieldIndex];
        definition = [AGSUniqueValueDefinition uniqueValueDefinitionWithUniqueValueFields:@[field.name]];
        definition.colorRamp = gradientRamp;
    }
    
    //cancel the previous generate renderer request
    [self.lastRendererOperation cancel];
    
    //using the where clause to specify the counties in the california
    AGSGenerateRendererParameters *rendererParams = [AGSGenerateRendererParameters generateRendererParametersWithClassificationDefinition:definition whereClause:@"state_name = 'California'"];
    self.lastRendererOperation = [self.generateRendererTask generateRendererWithParameters:rendererParams completion:^(AGSRenderer *renderer, NSError *error) {
        if (error) {
            //failed to generate renderer with an error
            if (self.delegate && [self.delegate respondsToSelector:@selector(legendViewController:failedToGenerateRendererWithError:)]) {
                [self.delegate legendViewController:self failedToGenerateRendererWithError:error];
            }
        }
        else if (renderer) {
            //assign the renderer based on the segment selected
            //hide the footer view
            //notify the delegate
            if (self.segmentedControl.selectedSegmentIndex == 0) {
                self.classBreakRenderer = (AGSClassBreaksRenderer*)renderer;
            }
            else {
                self.uniqueValueRenderer = (AGSUniqueValueRenderer*)renderer;
            }
            [self hideLoadingFooterView];
            
            if (self.delegate && [self.delegate respondsToSelector:@selector(legendViewController:didGenerateRenderer:)]) {
                [self.delegate legendViewController:self didGenerateRenderer:renderer];
            }
        }
    }];
}

#pragma mark - UITextField delegates

//using the textField delegate to display the popover view controller instead of the keyboard
//and based on the textfield selected passing the corresponding options
-(BOOL)textFieldShouldBeginEditing:(UITextField *)textField {

    NSArray *options;
    if (textField == self.classificationTextField) {
        if (self.segmentedControl.selectedSegmentIndex == 0) {
            options = [self namesArrayFromFieldsArray:self.classBreakClassificationFields];
        }
        else {
            options = [self namesArrayFromFieldsArray:self.uniqueValueClassificationFields];
        }
    }
    else if (textField == self.normalizationTextField) {
        NSMutableArray *temp = [[self namesArrayFromFieldsArray:self.classBreakClassificationFields] mutableCopy];
        [temp insertObject:NONE_FIELD_VALUE atIndex:0];
        options = temp;
    }
    else if (textField == self.methodTextField) {
        options = self.classificationMethods;
    }
    else if (textField == self.algorithmTextField) {
        options = self.colorRampAlgorithms;
    }
    
    [self showPopOverController:options forTextField:textField];
    return NO;
}

#pragma mark - OptionsViewControllerDelegate Delegate

//updating the selection index for the textField passed and generating a new renderer
-(void)optionsViewController:(OptionsViewController *)optionsViewController didSelectIndex:(NSInteger)index forTextField:(UITextField *)textField {
    if (textField == self.classificationTextField) {
        self.selectedFieldIndex = index;
    }
    else if (textField == self.normalizationTextField) {
        self.selectedNormalizationIndex = index;
    }
    else if (textField == self.methodTextField) {
        self.selectedMethodIndex = index;
        [self updateClassCountFieldStatus];
    }
    else if (textField == self.algorithmTextField) {
        self.selectedAlgorithmIndex = index;
    }
    [self generateRenderer];
}

- (void)showPopOverController:(NSArray*)options forTextField:(UITextField*)textField {
    //using pop over controller to show options for each text field
    //the pop over controller contains the optionsViewController as a tableView controller
    //with all the possible values for that textField
    if (self.optionsViewController == nil) {
        self.optionsViewController = [[OptionsViewController alloc] init];
        //using the legendViewController as the delegate for the optionsViewController
        self.optionsViewController.delegate = self;
    }
    if (self.popOverController == nil) {
        self.popOverController = [[UIPopoverController alloc] initWithContentViewController:self.optionsViewController];
        [self.popOverController setPopoverContentSize:CGSizeMake(240, 200)];
    }
    
    self.optionsViewController.textField = textField;
    self.optionsViewController.options = options;
    
    //use the frame of the textField as the origination rect for the pop over controller
    CGRect textFieldRect = textField.frame;
    [self.popOverController presentPopoverFromRect:textFieldRect inView:self.view permittedArrowDirections:UIPopoverArrowDirectionLeft animated:YES];
}

@end
