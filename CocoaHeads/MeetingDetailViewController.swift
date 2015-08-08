//
//  MeetingDetailViewController.swift
//  CocoaHeads
//
//  Created by Liam Butler-Lawrence on 6/25/15.
//  Copyright (c) 2015 Liam Butler-Lawrence. All rights reserved.
//

import UIKit

class MeetingDetailViewController: UIViewController {
    
    @IBOutlet weak var meetingTitleLabel: UILabel?
    @IBOutlet weak var meetingInformationLabel: UILabel?
    
    var selectedMeeting: Meeting? {
        didSet { setMeetingLabels() }
    }// must be set before viewDidLoad()
    
    var meetingTitleLabelText: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setMeetingLabels()
        
        navigationItem.leftItemsSupplementBackButton = true
        navigationItem.leftBarButtonItem = splitViewController?.displayModeButtonItem()
        
        let upcomingMeetingActivityType = "com.liambutlerlawrence.upcomingCHMeeting"

        if #available(iOS 9.0, *) {
            let upcomingMeetingActivity = NSUserActivity(activityType: upcomingMeetingActivityType)
            upcomingMeetingActivity.title = "Upcoming CocoaHeads meeting"
            upcomingMeetingActivity.keywords = Set(arrayLiteral: "CocoaHeads", "Liam")
            upcomingMeetingActivity.eligibleForSearch = true
            userActivity = upcomingMeetingActivity
            upcomingMeetingActivity.becomeCurrent()
        }
    }
    
    func setMeetingLabels() {
        meetingTitleLabel?.text = selectedMeeting?.title
        meetingInformationLabel?.text = selectedMeeting?.information
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}