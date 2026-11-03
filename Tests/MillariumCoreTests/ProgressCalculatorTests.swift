//
//  ProgressCalculatorTests.swift
//  MillariumCore
//
//  Created by Ferdinand Reichart on 20.09.2026.
//


//
//  ProgressCalculatorTests.swift
//  MillariumCoreTests
//
//  Created by Ferdinand Reichart on 20.09.2026.
//

import XCTest
@testable import MillariumCore

final class ProgressCalculatorTests: XCTestCase {
    
    // MARK: - Blätter
    
    func testLeafNotCompleted() {
        let leaf = Millarium(degree: .step, title: "Step", isCompleted: false)
        XCTAssertEqual(leaf.progress, 0.0)
    }
    
    func testLeafCompleted() {
        let leaf = Millarium(degree: .step, title: "Step", isCompleted: true)
        XCTAssertEqual(leaf.progress, 1.0)
    }
    
    // MARK: - Container
    
    func testContainerOneOfTwo() {
        var container = Millarium(degree: .subchapter, title: "Sub")
        container.addChild(Millarium(degree: .step, title: "A", isCompleted: true))
        container.addChild(Millarium(degree: .step, title: "B", isCompleted: false))
        XCTAssertEqual(container.progress, 0.5)
    }
    
    func testContainerTwoOfThree() {
        var container = Millarium(degree: .subchapter, title: "Sub")
        container.addChild(Millarium(degree: .step, title: "A", isCompleted: true))
        container.addChild(Millarium(degree: .step, title: "B", isCompleted: true))
        container.addChild(Millarium(degree: .step, title: "C", isCompleted: false))
        XCTAssertEqual(container.progress, 2.0/3.0, accuracy: 0.0001)
    }
    
    // MARK: - Verschachtelt
    
    func testNestedProgress() {
        var ch = Millarium(degree: .chapter, title: "Ch")
        
        var s1 = Millarium(degree: .subchapter, title: "S1")
        s1.addChild(Millarium(degree: .step, title: "a", isCompleted: true))
        s1.addChild(Millarium(degree: .step, title: "b", isCompleted: true))
        
        var s2 = Millarium(degree: .subchapter, title: "S2")
        s2.addChild(Millarium(degree: .step, title: "c", isCompleted: false))
        s2.addChild(Millarium(degree: .step, title: "d", isCompleted: false))
        
        ch.addChild(s1)
        ch.addChild(s2)
        
        XCTAssertEqual(ch.progress, 0.5)
    }
    
    func testThreeLevelsDeep() {
        var course = Millarium(degree: .course, title: "Course")
        var ch = Millarium(degree: .chapter, title: "Ch")
        var sub = Millarium(degree: .subchapter, title: "Sub")
        sub.addChild(Millarium(degree: .step, title: "a", isCompleted: true))
        sub.addChild(Millarium(degree: .step, title: "b", isCompleted: false))
        ch.addChild(sub)
        course.addChild(ch)
        
        XCTAssertEqual(course.progress, 0.5)
    }
    
    // MARK: - Container mit Containern
    
    func testContainerWithNestedContainers() {
        var course = Millarium(degree: .course, title: "Course")
        
        var ch1 = Millarium(degree: .chapter, title: "Ch1")
        ch1.addChild(Millarium(degree: .subchapter, title: "Sub1", isCompleted: true))
        ch1.addChild(Millarium(degree: .subchapter, title: "Sub2", isCompleted: false))
        // ch1 = 0.5
        
        var ch2 = Millarium(degree: .chapter, title: "Ch2")
        ch2.addChild(Millarium(degree: .subchapter, title: "Sub3", isCompleted: true))
        ch2.addChild(Millarium(degree: .subchapter, title: "Sub4", isCompleted: true))
        // ch2 = 1.0
        
        course.addChild(ch1)
        course.addChild(ch2)
        // course = (0.5 + 1.0) / 2 = 0.75
        
        XCTAssertEqual(course.progress, 0.75)
    }
    
    // MARK: - Sonderfälle
    
    func testEmptyContainer() {
        let empty = Millarium(degree: .subchapter, title: "Empty")
        XCTAssertEqual(empty.progress, 0.0)
        XCTAssertTrue(empty.isLeaf)
    }
    
    func testCompletedLeafBecomesContainer() {
        var node = Millarium(degree: .subchapter, title: "Sub", isCompleted: true)
        XCTAssertEqual(node.progress, 1.0)
        
        node.addChild(Millarium(degree: .step, title: "Step", isCompleted: false))
        XCTAssertFalse(node.isCompleted, "Container sollte nicht mehr isCompleted sein")
        XCTAssertEqual(node.progress, 0.0, "Fortschritt wird jetzt von Kindern bestimmt")
    }
    
    func testPercentRounding() {
        XCTAssertEqual(ProgressCalculator.percent(0.5), 50)
        XCTAssertEqual(ProgressCalculator.percent(0.5333), 53)
        XCTAssertEqual(ProgressCalculator.percent(0.6666), 67)
        XCTAssertEqual(ProgressCalculator.percent(1.0), 100)
        XCTAssertEqual(ProgressCalculator.percent(0.0), 0)
    }
    
    // MARK: - Baumoperationen
    
    func testFindNode() {
        var root = Millarium(degree: .course, title: "Root")
        let child = Millarium(degree: .chapter, title: "Ch")
        let childId = child.id
        root.addChild(child)
        
        XCTAssertNotNil(root.find(id: root.id))
        XCTAssertNotNil(root.find(id: childId))
        XCTAssertNil(root.find(id: UUID()))
    }
    
    func testUpdateNode() {
        var root = Millarium(degree: .course, title: "Root")
        let child = Millarium(degree: .chapter, title: "Ch")
        let childId = child.id
        root.addChild(child)
        
        let ok = root.update(id: childId) { node in
            node.title = "Updated"
        }
        XCTAssertTrue(ok)
        XCTAssertEqual(root.find(id: childId)?.title, "Updated")
    }
    
    func testRemoveChild() {
        var root = Millarium(degree: .course, title: "Root")
        let child = Millarium(degree: .chapter, title: "Ch")
        let childId = child.id
        root.addChild(child)
        
        XCTAssertEqual(root.children.count, 1)
        root.removeChild(id: childId)
        XCTAssertEqual(root.children.count, 0)
    }
    
    // MARK: - MillariumDegree
    
    func testDegreeHierarchy() {
        XCTAssertEqual(MillariumDegree.course.deeper, .chapter)
        XCTAssertEqual(MillariumDegree.chapter.deeper, .part)
        XCTAssertEqual(MillariumDegree.part.deeper, .subchapter)
        XCTAssertEqual(MillariumDegree.subchapter.deeper, .step)
        XCTAssertEqual(MillariumDegree.step.deeper, .substep)
        XCTAssertNil(MillariumDegree.substep.deeper)
        
        XCTAssertNil(MillariumDegree.course.shallower)
        XCTAssertEqual(MillariumDegree.chapter.shallower, .course)
    }
    
    func testDegreeComparison() {
        XCTAssertTrue(MillariumDegree.course < MillariumDegree.chapter)
        XCTAssertTrue(MillariumDegree.step > MillariumDegree.subchapter)
        XCTAssertTrue(MillariumDegree.part < MillariumDegree.substep)
    }
}