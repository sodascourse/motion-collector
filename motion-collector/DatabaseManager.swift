//
//  DatabaseManager.swift
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
import Async
import SQLite

struct AccelerometerTable {
    static let table = Table("accelerometer")
    static let itemId = Expression<Int64>("id")
    static let xValue = Expression<Double>("x")
    static let yValue = Expression<Double>("y")
    static let zValue = Expression<Double>("z")
    static let timestamp = Expression<Double>("timestamp")
}

class DatabaseManager {

    let fileName: String
    var filePath: String {
        let documentFolder = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true).first!
        let filePath = (documentFolder as NSString).stringByAppendingPathComponent("\(self.fileName).sqlite3")
        return filePath
    }

    var databaseConnection: Connection?

    private let dispatchQueue: dispatch_queue_t

    init(fileName: String) {
        self.fileName = fileName

        let qeueAttr = dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_SERIAL, QOS_CLASS_BACKGROUND, -1)
        self.dispatchQueue = dispatch_queue_create("tw.sodas.db-manager", qeueAttr)

        self.openDatabase()
    }

    // MARK: - Method

    private func performOnDispatchQueue(closure: () -> Void) {
        Async.customQueue(self.dispatchQueue, block: closure)
    }

    private func openDatabase() {
        self.performOnDispatchQueue {
            do {
                self.databaseConnection = try Connection(self.filePath)

                try self.databaseConnection!.run(AccelerometerTable.table.create(ifNotExists: true) { t in
                    t.column(AccelerometerTable.itemId, primaryKey: .Autoincrement)
                    t.column(AccelerometerTable.xValue)
                    t.column(AccelerometerTable.yValue)
                    t.column(AccelerometerTable.zValue)
                    t.column(AccelerometerTable.timestamp)
                })

                try self.databaseConnection!.run(AccelerometerTable.table.createIndex([AccelerometerTable.timestamp],
                    ifNotExists: true))
            } catch {
                print("Cannot create database")
                exit(1)
            }
        }
    }

    func addAccelerometerData(xValue xValue: Double, yValue: Double, zValue: Double) {
        if self.databaseConnection == nil {
            return
        }
        self.performOnDispatchQueue {
            do {
                try self.databaseConnection!.run(AccelerometerTable.table.insert(
                    AccelerometerTable.xValue <- xValue,
                    AccelerometerTable.yValue <- yValue,
                    AccelerometerTable.zValue <- zValue,
                    AccelerometerTable.timestamp <- NSDate().timeIntervalSince1970
                ))
            } catch {
                print("Cannot insert data")
                exit(1)
            }
        }
    }
}
