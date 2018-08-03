//
//  RelistenTests.swift
//  RelistenTests
//
//  Created by Jacob Farkas on 8/3/18.
//  Copyright © 2018 Alec Gorge. All rights reserved.
//

import XCTest
import RelistenShared

class RelistenTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testReentrantDispatchQueueSync() {
        let queue = ReentrantDispatchQueue("net.relisten.queueTest")
        let expectation = XCTestExpectation(description: "Queue Didn't Block")
        queue.sync {
            queue.sync {
                expectation.fulfill()
            }
        }
        
        self.wait(for: [expectation], timeout: 1.0)
    }
    
    func testReentrantDispatchQueueAsync() {
        let queue = ReentrantDispatchQueue("net.relisten.queueTest")
        
        let reentrantExpectation = XCTestExpectation(description: "Reentrant dispatch succeeded")
        queue.async {
            queue.async {
                reentrantExpectation.fulfill()
            }
        }
        
        let nonReentrantExpectation = XCTestExpectation(description: "Non reentrant dispatch succeeded")
        DispatchQueue.main.async {
            queue.async {
                nonReentrantExpectation.fulfill()
            }
        }
        
        self.wait(for: [reentrantExpectation, nonReentrantExpectation], timeout: 1.0)
    }
    
    func testPerformOnMainQueueSync() {
        let expectation = XCTestExpectation(description: "Queue Didn't Block")
        DispatchQueue.main.async {
            performOnMainQueueSync() {
                expectation.fulfill()
            }
        }
        
        self.wait(for: [expectation], timeout: 1.0)
    }
}
