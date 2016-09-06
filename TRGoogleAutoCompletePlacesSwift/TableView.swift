//
//  TableView.swift
//  TRGoogleAutoCompletePlacesSwift
//
//  Created by Daniel-Ernest Luff on 06/09/2016.
//  Copyright © 2016 toutrig.ht. All rights reserved.
//

import Foundation
import UIKit
import GooglePlaces

class TableView: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var textField: UITextField?
    var resultText: UITextView?
    var fetcher: GMSAutocompleteFetcher?
    var resultsArray: NSMutableArray = []
    var idArray: NSMutableArray = []
    @IBOutlet weak var tableView: UITableView?
    var tabeCount: Int = 0
    
    
    enum addaddress: Int {
        case AddressResults
        case Count
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.whiteColor()
        textField?.becomeFirstResponder()
        self.edgesForExtendedLayout = .None
        
        
        // loaction bias
        let neBoundsCorner = CLLocationCoordinate2D(latitude: 51.716472,
                                                    longitude: 0.286431)
        let swBoundsCorner = CLLocationCoordinate2D(latitude: 51.304086,
                                                    longitude: -0.497718)
        let london = GMSCoordinateBounds(coordinate: neBoundsCorner,
                                         coordinate: swBoundsCorner)
        // filter bias - check the api for options
        let filter = GMSAutocompleteFilter()
        filter.type = .Address
        
        fetcher = GMSAutocompleteFetcher(bounds: london, filter: filter)
        fetcher?.delegate = self
        
        textField?.addTarget(self, action: #selector(TableView.textFieldDidChange(_:)), forControlEvents: .EditingChanged)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        textField?.becomeFirstResponder()
    }
    
    func textFieldDidChange(textField: UITextField) {
        fetcher?.sourceTextHasChanged(textField.text!)
    }
    
}

extension TableView: GMSAutocompleteFetcherDelegate {
    func didAutocompleteWithPredictions(predictions: [GMSAutocompletePrediction]) {
        resultsArray.removeAllObjects()
        idArray.removeAllObjects()
        for prediction in predictions {
            let regularFont = UIFont.systemFontOfSize(15)
            let boldFont = UIFont.boldSystemFontOfSize(15)
            let placeID = prediction.placeID
            let bolded = prediction.attributedFullText.mutableCopy() as! NSMutableAttributedString
            bolded.enumerateAttribute(kGMSAutocompleteMatchAttribute, inRange: NSMakeRange(0, bolded.length), options: []) { (value, range: NSRange, stop: UnsafeMutablePointer<ObjCBool>) -> Void in
                let font = (value == nil) ? regularFont : boldFont
                bolded.addAttribute(NSFontAttributeName, value: font, range: range)
            }
            
            resultsArray.insertObject(bolded, atIndex: resultsArray.count)
            idArray.insertObject(placeID!, atIndex: resultsArray.count - 1)
            tableView?.reloadData()
            
        }
        
        tableView?.reloadData()
        tableView?.setNeedsLayout()
        
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return addaddress.Count.rawValue
    }
    
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch addaddress(rawValue: section)!{
        case .AddressResults:
            return resultsArray.count
        default:
            return 0
        }
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat
    {
        return 75.0;
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        switch addaddress(rawValue: indexPath.section)! {
        case .AddressResults:
            let cell = tableView.dequeueReusableCellWithIdentifier("googleResult", forIndexPath: indexPath) as! ResultCell
            cell.title?.attributedText = resultsArray[indexPath.row] as? NSMutableAttributedString
            cell.placeid = idArray[indexPath.row] as? String
            return cell
        default:
            print("wtf")
        }
        return UITableViewCell()
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        switch addaddress(rawValue: indexPath.section)!{
        case .AddressResults:
            let indexPath = tableView.indexPathForSelectedRow
            let currentCell = tableView.cellForRowAtIndexPath(indexPath!)! as! ResultCell
            let placeID = currentCell.placeid
            let placesClient = GMSPlacesClient.sharedClient()
            
            placesClient.lookUpPlaceID(placeID!, callback: { (place: GMSPlace?, error: NSError?) -> Void in
                if let error = error {
                    print("lookup place id query error: \(error.localizedDescription)")
                    return
                }
                if let place = place {
                    let delayTime = dispatch_time(DISPATCH_TIME_NOW, Int64(1 * Double(NSEC_PER_SEC)))
                    dispatch_after(delayTime, dispatch_get_main_queue()) {
                        let alert = UIAlertController(title: "Selected Address", message: "\(place.formattedAddress!)", preferredStyle: UIAlertControllerStyle.Alert)
                        alert.addAction(UIAlertAction(title: "Okay", style: UIAlertActionStyle.Default, handler: nil))
                        self.presentViewController(alert, animated: true, completion: nil)
                    }
                } else {
                    print("No place details for \(placeID)")
                }
            })
        default:
            print("wtf")
        }
    }
    
    func didFailAutocompleteWithError(error: NSError) {
        print(error.localizedDescription)
    }
}