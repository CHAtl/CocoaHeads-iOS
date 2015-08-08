//
//  Meeting.swift
//  CocoaHeads
//
//  Created by Liam Butler-Lawrence on 7/24/15.
//  Copyright © 2015 Liam Butler-Lawrence. All rights reserved.
//

import CoreData

class Meeting: NSManagedObject {
    
    @NSManaged var title: String
    @NSManaged var information: String
    @NSManaged var date: NSDate
    @NSManaged var ckRecordID: String
    @NSManaged var location: String
    
    var dateGroup: Int {
        let year = NSCalendar.currentCalendar().component(.Year, fromDate: date)
        let month = NSCalendar.currentCalendar().component(.Month, fromDate: date)
        return year * 12 + month
    }
    
    class func stringFromDateGroup(dateGroup: Int) -> String {
        let month = dateGroup % 12
        let year = (dateGroup - month) / 12
        
        let months = [
            1: "January",
            2: "February",
            3: "March",
            4: "April",
            5: "May",
            6: "June",
            7: "July",
            8: "August",
            9: "September",
            10: "October",
            11: "November",
            0: "December"
        ]
        
        guard let monthString = months[month] else {
            fatalError("Could not determine month with integer \(month)")
        }
        return monthString + " \(year)"
        
    }
    
    static func entityName() -> String {
        return "Meeting"
    }
}
