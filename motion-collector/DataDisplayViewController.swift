//
//  DataDisplayViewController.swift
//  motion-collector
//
//  Copyright 2016 Tien-Che Tsai
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//


import UIKit
import CoreMotion

class DataDisplayViewController: UITableViewController {

    static let dateFormatter: NSDateFormatter = {
        let formatter = NSDateFormatter()
        formatter.dateStyle = .ShortStyle
        formatter.timeStyle = .MediumStyle
        return formatter
    }()

    static let numberFormatter: NSNumberFormatter = {
        let formatter = NSNumberFormatter()
        formatter.maximumFractionDigits = 5
        formatter.minimumFractionDigits = 5
        formatter.minimumIntegerDigits = 1
        return formatter
    }()

    @IBOutlet weak var xValueLabel: UILabel!
    @IBOutlet weak var yValueLabel: UILabel!
    @IBOutlet weak var zValueLabel: UILabel!

    @IBOutlet weak var sinceDateLabel: UILabel!
    @IBOutlet weak var durationLabel: UILabel!

    @IBOutlet weak var triggerButtonItem: UIBarButtonItem!

    var startCollectingDate: NSDate? {
        didSet {
            if let startCollectingDate = self.startCollectingDate {
                let dateString = DataDisplayViewController.dateFormatter.stringFromDate(startCollectingDate)
                self.sinceDateLabel.text = dateString
            } else {
                self.sinceDateLabel.text = "--"
            }
            self.tableView.reloadData()  // Ask the table view to redraw
        }
    }

    var collectingTimer: NSTimer? {
        didSet {
            if self.collectingTimer == nil {
                self.durationLabel.text = "--"
            } else {
                self.durationLabel.text = "0"
            }
            self.tableView.reloadData()  // Ask the table view to redraw
        }
    }

    func collectingTimerFired(timer: NSTimer) {
        let duration = NSDate().timeIntervalSinceDate(self.startCollectingDate!)
        self.durationLabel.text = "\(Int(duration))"
        self.tableView.reloadData()  // Ask the table view to redraw
    }

    var collectingData: Bool = false {
        didSet {
            if self.collectingData {
                // Update the trigger button
                self.triggerButtonItem.title = "Stop"
                // Update starting date
                self.startCollectingDate = NSDate()
                // Setup the timer to update `duration` label
                let selector = #selector(DataDisplayViewController.collectingTimerFired(_:))
                self.collectingTimer =
                    NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: selector,
                                                           userInfo: nil, repeats: true)
                // Go
                MotionManager.sharedInstance.startAccelerometerUpdates()
            } else {
                MotionManager.sharedInstance.stopAccelerometerUpdates()

                self.triggerButtonItem.title = "Start"

                self.startCollectingDate = nil

                self.collectingTimer?.invalidate()
                self.collectingTimer = nil

                self.updateXYZLabels(xValue: 0, yValue: 0, zValue: 0)
            }
        }
    }

    @IBAction func dataCollectorTrigger(sender: AnyObject) {
        self.collectingData = !self.collectingData
    }

    func updateXYZLabels(xValue xValue: Double, yValue: Double, zValue: Double) {
        let numberFormatter = DataDisplayViewController.numberFormatter
        self.xValueLabel.text = numberFormatter.stringFromNumber(xValue)
        self.yValueLabel.text = numberFormatter.stringFromNumber(yValue)
        self.zValueLabel.text = numberFormatter.stringFromNumber(zValue)
        self.tableView.reloadData()  // Ask the table view to redraw
    }

    // MARK: - Object and View Lifecycle

    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Register to receive notification about application will resign active
        // We should stop collecting data then
        let notificationCenter = NSNotificationCenter.defaultCenter()
        notificationCenter.addObserver(self,
                                       selector: #selector(DataDisplayViewController.applicationWillResignActive(_:)),
                                       name: UIApplicationWillResignActiveNotification,
                                       object: UIApplication.sharedApplication())
        // Register notification to get data update
        let selector = #selector(DataDisplayViewController.motionManagerDidUpdateAccelerometerData(_:))
        notificationCenter.addObserver(self,
                                       selector: selector,
                                       name: MotionManager.accelerometerDidUpdateNotification,
                                       object: MotionManager.sharedInstance)
    }

    // MARK: - Notifications

    func applicationWillResignActive(notification: NSNotification) {
        // Stop collecting data when user closes this app
        self.collectingData = false
    }

    func motionManagerDidUpdateAccelerometerData(notification: NSNotification) {
        // Since the data is collected asynchronously, sometimes after we set `collectingData` to false,
        // the data would still be sent back (for a little while).
        if !self.collectingData {
            return
        }
        // Update label
        if let data = notification.userInfo?[MotionManager.accelerometerUserInfoKey] as? CMAccelerometerData {
            let acceleration = data.acceleration
            self.updateXYZLabels(xValue: acceleration.x, yValue: acceleration.y, zValue: acceleration.z)
        }
    }
}
