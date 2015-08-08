//
//  MeetingListTableViewController.swift
//  CocoaHeads
//
//  Created by Liam Butler-Lawrence on 6/25/15.
//  Copyright (c) 2015 Liam Butler-Lawrence. All rights reserved.
//

import UIKit
import CloudKit
import CoreData
//import CoreSpotlight
import MobileCoreServices

extension NSFetchedResultsController {
    
    // MARK: Methods revised with generics and throws
    
    enum FetchedResultsError: ErrorType {
        case CouldNotFetchObject
    }
    
    func typedObjectAtIndexPath<T>(indexPath: NSIndexPath) throws -> T {
        guard let object = objectAtIndexPath(indexPath) as? T else {
            throw FetchedResultsError.CouldNotFetchObject
        }
        return object
    }
}

// MARK: -
// MARK: -

class MeetingListTableViewController: UITableViewController, NSFetchedResultsControllerDelegate {
    
    // MARK: Global variables & constants
    
    let reusableCellIdentifier = "MeetingListReusableCell"
    let detailNavigationControllerIdentifier = "DetailNavigationController"
    let detailViewControllerIdentifier = "MeetingDetailViewController"
    
    lazy var fetchedResultsController: NSFetchedResultsController = {
        let dateKeyString = "date"
        let dateGroupKeyString = "dateGroup"
        
        let fetchRequest = NSFetchRequest(entityName: Meeting.entityName())
        let sortDescriptor = NSSortDescriptor(key: dateKeyString, ascending: true)
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        let controller = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: CoreDataModel.managedObjectContext, sectionNameKeyPath: dateGroupKeyString, cacheName: nil)
        controller.delegate = self
        
        do {
            try controller.performFetch()
        } catch {
            // Error access? Print info?
            fatalError("Could not perform fetch using fetched results controller")
        }
        return controller
    }()
    
    // MARK: - Fetched Results Controller delegate
    
    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        tableView.beginUpdates()
    }
    
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        tableView.endUpdates()
    }
    
    func controller(controller: NSFetchedResultsController, didChangeSection sectionInfo: NSFetchedResultsSectionInfo, atIndex sectionIndex: Int, forChangeType type: NSFetchedResultsChangeType) {
        switch type {
        case .Insert: tableView.insertSections(NSIndexSet(index: sectionIndex), withRowAnimation: .Automatic)
        case .Delete: tableView.deleteSections(NSIndexSet(index: sectionIndex), withRowAnimation: .Automatic)
        default: fatalError("Unrecognized type of section change to fetched results controller")
        }
    }
    
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: NSManagedObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        switch type {
        case .Insert: tableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: .Automatic)
        case .Delete: tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: .Automatic)
        case .Update: print("Should update row at index path \(indexPath!)")
        case .Move: print("Should move row at index path \(indexPath!)")
        }
    }
    

    // MARK: - UIViewController overrides
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //inputTempData()
        //retrieveCloudKitData()
        
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        //self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table View delegate & data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        guard let sections = fetchedResultsController.sections else {
            fatalError("Could not retrieve sections using fetched results controller")
        }
        print("Sections: \(sections.count)")
        return sections.count
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let sections = fetchedResultsController.sections else {
            fatalError("Could not retrieve sections using fetched results controller")
        }
        return sections[section].numberOfObjects
    }
    

    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(reusableCellIdentifier, forIndexPath: indexPath) as UITableViewCell
        
        do {
            let meeting: Meeting = try fetchedResultsController.typedObjectAtIndexPath(indexPath)
            cell.textLabel?.text = meeting.title
        } catch {
            fatalError("Could not retrieve meeting #\(indexPath.row) from Core Data as Meeting object")
        }
        
        return cell
    }
    
    override func tableView(tableView: UITableView, sectionForSectionIndexTitle title: String, atIndex index: Int) -> Int {
        return fetchedResultsController.sectionForSectionIndexTitle(title, atIndex: index)
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        print(section)
        guard let sections = fetchedResultsController.sections else {
            fatalError("Could not retrieve sections using fetched results controller")
        }
        guard let dateGroup = Int(sections[section].name) else {
            fatalError("Could not convert section name to integer")
        }
        return Meeting.stringFromDateGroup(dateGroup)
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        do {
            let meeting: Meeting = try fetchedResultsController.typedObjectAtIndexPath(indexPath)
            if splitViewController!.collapsed {
                // ALL iPhones in portrait and all except 6+ in landscape
                // need to instantiate detail VC from storyboard
                // should present WITHOUT nav controller
                
                guard let meetingDetailViewController = storyboard!.instantiateViewControllerWithIdentifier(detailViewControllerIdentifier) as? MeetingDetailViewController else {
                    fatalError("Could not access newly instantiated view controller as MeetingDetailViewController")
                }
                meetingDetailViewController.selectedMeeting = meeting
                splitViewController!.showDetailViewController(meetingDetailViewController, sender: nil)
                
            } else {
                // ALL iPad orientations and iPhone 6+ landscape
                // need to retrieve detail VC from split VC
                // must present WITH nav controller
                
                guard let meetingDetailViewController = (splitViewController!.viewControllers.last as!UINavigationController).viewControllers.first as? MeetingDetailViewController else {
                    fatalError("Could not access split view's controller as MeetingDetailViewController")
                }
                meetingDetailViewController.selectedMeeting = meeting
                
            }
        } catch {
            fatalError("Could not retrieve selected meeting from Core Data as Meeting object")
        }
    }

    /*
    // Override to support conditional editing of the table view.
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return NO if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            // Delete the row from the data source
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        } else if editingStyle == .Insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return NO if you do not want the item to be re-orderable.
        return true
    }
    */

    
    /*
    // MARK - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
    }
    */
    
    // MARK: - Temporary (to move or delete)


    
    func retrieveCloudKitData()
    {
        let publicData = CKContainer.defaultContainer().publicCloudDatabase
        publicData.fetchRecordWithID(CKRecordID(recordName: "3e8134c0-74d0-4708-9681-3f9f4fb7ec32"), completionHandler: { (record, error) -> Void in
            /*guard let validRecord = record else
            {
                NSLog(error!.description);
                return
            }
                    
            if #available(iOS 9.0, *) {
                let attributeSet = CSSearchableItemAttributeSet(itemContentType: kUTTypeImage as String)
                attributeSet.title = validRecord["title"] as? String
                attributeSet.contentDescription = validRecord["information"] as? String
                        
                let searchableItem = CSSearchableItem(uniqueIdentifier: "\(validRecord.recordID)", domainIdentifier: validRecord.recordType, attributeSet: attributeSet)
                CSSearchableIndex.defaultSearchableIndex().indexSearchableItems([searchableItem], completionHandler: { (error) -> Void in
                    if let validError = error
                    {
                        NSLog(validError.description)
                    }
                })
            }*/
        })
    }
    
    
    func inputTempData() {
        guard let newMeeting = NSEntityDescription.insertNewObjectForEntityForName(Meeting.entityName(), inManagedObjectContext: CoreDataModel.managedObjectContext) as? Meeting else {
            fatalError("Could not create meeting object for meeting entity as fake data")
        }
        newMeeting.title = "CH Meeting"
        newMeeting.date = NSDate(timeIntervalSinceNow: 0)
        do {
            try CoreDataModel.managedObjectContext.save()
        } catch {
            fatalError("Could not save fake data")
        }
    }
}