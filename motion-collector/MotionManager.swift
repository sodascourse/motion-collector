//
//  MotionManager.swift
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

import Foundation
import UIKit
import CoreMotion
import Async

class MotionManager {
    static let accelerometerDidUpdateNotification = "MotionManagerAccelerometerDidUpdateNotification"
    static let accelerometerUserInfoKey = "accelerometer"

    static var sharedInstance = MotionManager()

    private let motionManager = CMMotionManager()
    private let dataProcessDispatchQueue: dispatch_queue_t = {
        let dispatchQueueAttr = dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_SERIAL,
                                                                        QOS_CLASS_USER_INTERACTIVE, -1)
        return dispatch_queue_create("tw.sodas.motion-collector.data-process", dispatchQueueAttr)
    }()
    private let dataProcessOperationQueue: NSOperationQueue

    private init() {
        self.motionManager.accelerometerUpdateInterval = 0.1
        self.dataProcessOperationQueue = NSOperationQueue()
        self.dataProcessOperationQueue.underlyingQueue = self.dataProcessDispatchQueue
    }

    deinit {
        self.stopAccelerometerUpdates()
    }

    func startAccelerometerUpdates() {
        if self.motionManager.accelerometerActive {
            return
        }
        self.motionManager.startAccelerometerUpdatesToQueue(self.dataProcessOperationQueue) {
            (accelerometerData: CMAccelerometerData?, error: NSError?) in
            if let _accelerometerData = accelerometerData {
                // Post notification
                let notification = NSNotification(name: MotionManager.accelerometerDidUpdateNotification,
                                                  object: self,
                                                  userInfo: [
                                                    MotionManager.accelerometerUserInfoKey: _accelerometerData
                                                  ])
                Async.main {
                    NSNotificationQueue.defaultQueue().enqueueNotification(notification, postingStyle: .PostNow)
                }
            }
        }
    }

    func stopAccelerometerUpdates() {
        if !self.motionManager.accelerometerActive {
            return
        }
        self.motionManager.stopAccelerometerUpdates()
    }
}
