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

protocol LegendViewControllerDelegate:class {
    
    func dismissLegend()
    
}

class LegendViewController: UIViewController {
    
    @IBOutlet weak var legendTableView:UITableView!
    var legendDataSource:LegendDataSource!
    var popOverController:UIPopoverController!
    
    weak var delegate:LegendViewControllerDelegate?
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        //Hook up the table view with the data source to display legend
        self.legendTableView.dataSource = self.legendDataSource
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func dismiss() {
        self.delegate?.dismissLegend()
    }

}
