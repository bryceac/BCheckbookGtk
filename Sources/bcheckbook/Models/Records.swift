//
//  GetRecords.swift
//  Checkbook
//
//  Created by Bryce Campbell on 5/27/21.
//

import Foundation

class Records {
    var items: [Record]
    
    var sortedRecords: [Record] {
        return items.sorted { firstRecord, secondRecord in
            firstRecord.event.date < secondRecord.event.date
        }
    }
    
    var balances: [Record: Double] {
        return sortedRecords.reduce(into: [Record: Double]()) { balances, record in
            guard let databaseManager = DB.shared.manager else { return }
            balances[record] = try? databaseManager.balance(for: record)
        }
    }
    
    init(withRecords records: [Record] = []) {
        items = records
    }
    
    func add(_ record: Record) {
        items.append(record)
    }
    
    func add(_ records: [Record]) {
        items += records
    }
    
    func remove(at index: Int) {
        items.remove(at: index)
    }
    
    func remove(_ record: Record) {
        guard let RECORD_INDEX = self.items.firstIndex(of: record) else { return }
        
        self.remove(at: RECORD_INDEX)
    }
    
    func clear() {
        items.removeAll()
    }
}
