//
//  CloudKitModel.swift
//  CocoaHeads
//
//  Created by Liam Butler-Lawrence on 8/3/15.
//  Copyright © 2015 Liam Butler-Lawrence. All rights reserved.
//

import UIKit
import CloudKit
import CoreData

class CloudKitModel: NSObject {
    
    static private let publicDataSubscriptionID = "cloudKitCreateUpdateDeleteSubscription"
    static private let publicData = CKContainer.defaultContainer().publicCloudDatabase

    
    static func verifyCloudKitSubscription() {
        publicData.fetchSubscriptionWithID(publicDataSubscriptionID) { (subscription, error) -> Void in
            
            guard let fetchError = error else {
                print("Found subscription in CloudKit database")
                return
            }
            
            if fetchError.domain == CKErrorDomain {
                guard let fetchErrorCode = CKErrorCode(rawValue: fetchError.code) else {
                    fatalError("Could not access CloudKit error code from error from CloudKit fetch subscription operation")
                }
                switch fetchErrorCode {
                case .NetworkFailure, .NetworkUnavailable: fatalError("Could not connect to CocoaHeads servers. Please check your internet connection and try again.")
                case .UnknownItem: saveNewCloudKitSubscription()
                case .NotAuthenticated: fatalError("Could not authenticate with iCloud. Please login to iCloud in Settings and try again.") // SHOULD NOT BE FATAL, display user error
                default: fatalError("Received unexpected error from CloudKit fetch subscription operation (CloudKit error code \(fetchErrorCode.rawValue))")
                }

            } else {
                fatalError("Received error with non-CloudKit domain from CloudKit fetch subscription operation")
            }
        }
    }
    
    static private func saveNewCloudKitSubscription() {
        
        let publicDataSubscriptionPredicate = NSPredicate(format: "TRUEPREDICATE")
        let publicDataSubscriptionOptions: CKSubscriptionOptions = [.FiresOnRecordCreation, .FiresOnRecordUpdate, .FiresOnRecordDeletion]
        
        /*let publicDataSubscriptionNotificationInfo = CKNotificationInfo()
        publicDataSubscriptionNotificationInfo.alertBody = "Update to CK Cocoaheads!"
        publicDataSubscriptionNotificationInfo.alertLocalizationArgs =
        publicDataSubscriptionNotificationInfo.shouldSendContentAvailable = true
        publicDataSubscriptionNotificationInfo.desiredKeys = ["title"]*/
        
        let publicDataSubscription = CKSubscription(recordType: Meeting.entityName(), predicate: publicDataSubscriptionPredicate, subscriptionID: publicDataSubscriptionID, options: publicDataSubscriptionOptions)
        
        publicData.saveSubscription(publicDataSubscription) { (subscription, error) -> Void in
            if let saveError = error {
                print("Could not save subscription to public CloudKit database, error: \(saveError)") // EXAMINE ERROR, decide user-facing or fatal-error
                return
            }
            print("Saved subscription to CloudKit database") // REMOVE from production build
        }
    }
    
    static func updateFromCloudKitNotification(userInfo userInfo: [NSObject: AnyObject]) {
        guard let subscriptionDictionary = userInfo as? [String: NSObject] else {
            fatalError("Could not cast [NSObject: AnyObject] to [String: NSObject] for conversion to CloudKit notification")
        }
        
        let notification = CKNotification(fromRemoteNotificationDictionary: subscriptionDictionary)
        
        if notification.notificationType == .Query {
            print("received CloudKit notification from subscription")
        
            let queryNotification = notification as! CKQueryNotification
            
            guard let recordID = queryNotification.recordID else {
                fatalError("Could not access record ID of deleted record")
            }
            
            switch queryNotification.queryNotificationReason {
                
            case .RecordCreated: print("record created")
                createRecordWithID(recordID)
            case .RecordDeleted: print("record deleted")
                deleteRecordWithID(recordID)
            case .RecordUpdated: print("record updated")
                updateRecordWithID(recordID)
            }
        }
    }
    
    private static func createRecordWithID(recordID: CKRecordID) {
        
        publicData.fetchRecordWithID(recordID, completionHandler: { (record, error) -> Void in
            
            if let fetchError = error {
                fatalError("Could not fetch new record with CloudKit record ID \(recordID), error: \(fetchError)")
            }
            
            guard let meetingRecord = record else {
                fatalError("Could not access newly fetched record with CloudKit record ID \(recordID)")
            }
            
            do {
                let newMeeting: Meeting = try NSEntityDescription.insertNewObjectForEntityForName(Meeting.entityName())
                newMeeting.ckRecordID = recordID.recordName
                
                guard let meetingTitle = meetingRecord.objectForKey("title") as? String else {
                    fatalError("Could not access meeting title for newly fetched record with CloudKit record ID \(recordID)")
                }
                newMeeting.title = meetingTitle
                
                guard let meetingDate = meetingRecord.objectForKey("date") as? NSDate else {
                    fatalError("Could not access meeting date for newly fetched record with CloudKit record ID \(recordID)")
                }
                newMeeting.date = meetingDate
                
                guard let meetingInformation = meetingRecord.objectForKey("information") as? String else {
                    fatalError("Could not access meeting information for newly fetched record with CloudKit record ID \(recordID)")
                }
                newMeeting.information = meetingInformation
                
                do {
                    try CoreDataModel.managedObjectContext.save()
                } catch {
                    fatalError("Core Data save of new meeting with CloudKit record ID \(recordID) failed")
                }
            } catch {
                fatalError("Could not insert new Meeting object into Core Data managed object context")
            }
        })
    }
    
    private static func deleteRecordWithID(recordID: CKRecordID) {
        let fetchRequest = NSFetchRequest(entityName: Meeting.entityName())
        let predicate = NSPredicate(format: "%K = %@", "ckRecordID", recordID.recordName)
        fetchRequest.predicate = predicate
        
        do {
            let records = try CoreDataModel.managedObjectContext.executeFetchRequest(fetchRequest)
            guard let meetingToDelete = records.first as? Meeting else {
                fatalError("Could not access first fetch result as Meeting object")
            }
            CoreDataModel.managedObjectContext.deleteObject(meetingToDelete)
            
            do {
                try CoreDataModel.managedObjectContext.save()
            } catch {
                fatalError("Core Data save of deletion of meeting with CloudKit record ID \(recordID) failed")
            }
            
        } catch {
            fatalError("Core Data fetch for CloudKit record ID \(recordID) failed")
        }
    }
    
    private static func updateRecordWithID(recordID: CKRecordID) {
        // implement after fixing bug where updates in CK do not generate a notification
    }

}