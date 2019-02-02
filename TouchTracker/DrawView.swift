//
//  DrawView.swift
//  TouchTracker
//
//  Created by Sam Reaves on 1/26/19.
//  Copyright © 2019 Sam Reaves Digital. All rights reserved.
//

import UIKit

class DrawView: UIView, UIGestureRecognizerDelegate {
    var currentLines = [NSValue: Line]()
    var finishedLines = [Line]()
    var selectedLineIndex: Int? {
        didSet {
            if selectedLineIndex == nil {
                let menu = UIMenuController.shared
                menu.setMenuVisible(false, animated: true)
            }
        }
    }
    var moveRecognizer: UIPanGestureRecognizer!
    var longPressRecognizer: UILongPressGestureRecognizer!
    
    @IBInspectable var finishedLineColor: UIColor = UIColor.black {
        didSet {
            setNeedsDisplay()
        }
    }
    
    @IBInspectable var currentLinesColor: UIColor = UIColor.red {
        didSet {
            setNeedsDisplay()
        }
    }
    
    @IBInspectable var lineThickness: CGFloat = 10 {
        didSet {
            setNeedsDisplay()
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        /* Add double tap UIGestureRecognizer */
        let doubleTapRecognizer = UITapGestureRecognizer(target: self,
                                                         action: #selector(DrawView.doubleTap(_:)))
        doubleTapRecognizer.delaysTouchesBegan = true
        doubleTapRecognizer.numberOfTapsRequired = 2
        addGestureRecognizer(doubleTapRecognizer)
        
        /* Add single tap UIGestureRecognizer */
        let tapRecognizer = UITapGestureRecognizer(target: self,
                                                   action: #selector(DrawView.tap(_:)))
        tapRecognizer.delaysTouchesBegan = true
        tapRecognizer.require(toFail: doubleTapRecognizer)
        addGestureRecognizer(tapRecognizer)
        
        /* Add long press UIGestureRecognizer */
        longPressRecognizer = UILongPressGestureRecognizer(target: self,
                                                         action: #selector(DrawView.longPress(_:)))
        addGestureRecognizer(longPressRecognizer)
        
        
        /* Set UIPanRecognizer */
        moveRecognizer = UIPanGestureRecognizer(target: self,
                                                action: #selector(DrawView.moveLine(_:)))
        moveRecognizer.cancelsTouchesInView = false
        moveRecognizer.delegate = self
        addGestureRecognizer(moveRecognizer)
        
    }
    
    @objc func tap(_ gestureRecognizer: UIGestureRecognizer) {
        let point = gestureRecognizer.location(in: self)
        selectedLineIndex = indexOfLine(at: point)
        
        let menu = UIMenuController.shared
        
        if selectedLineIndex != nil {
            /* Make DrawView the target of menu action messages */
            becomeFirstResponder()
            
            let deleteItem = UIMenuItem(title: "delete", action: #selector(DrawView.deleteLine(_:)))
            menu.menuItems = [deleteItem]
            
            /* Tell the menu item where it should show */
            let targetRect = CGRect(x: point.x, y: point.y, width: 2, height: 2)
            menu.setTargetRect(targetRect, in: self)
            menu.setMenuVisible(true, animated: true)
        }
        else {
            menu.setMenuVisible(false, animated: true)
        }
        
        setNeedsDisplay()
    }
    
    @objc func doubleTap(_ gestureRecognizer: UIGestureRecognizer) {
        selectedLineIndex = nil
        currentLines.removeAll()
        finishedLines.removeAll()
        
        setNeedsDisplay()
    }
    
    @objc func longPress(_ gestureRecognizer: UIGestureRecognizer) {
        if gestureRecognizer.state == .began {
            let point = gestureRecognizer.location(in: self)
            selectedLineIndex = indexOfLine(at: point)
            
            if selectedLineIndex != nil {
                currentLines.removeAll()
            }
        } else if gestureRecognizer.state == .ended {
            selectedLineIndex = nil
        }
        
        setNeedsDisplay()
    }
    
    @objc func moveLine(_ gestureRecognizer: UIPanGestureRecognizer) {
        
        guard longPressRecognizer.state == .changed else {
            return;
        }
        
        /* If a line is selected */
        if let index = selectedLineIndex {
            
            /* When the pan recognizer changes its position */
            if gestureRecognizer.state == .changed {
                
                /* Grab how far the pan shifted from its origin position */
                let translation = gestureRecognizer.translation(in: self)
                
                /* Add the translation to the current beginning and end points of the line */
                finishedLines[index].begin.x += translation.x
                finishedLines[index].begin.y += translation.y
                finishedLines[index].end.x += translation.x
                finishedLines[index].end.y += translation.y
                
                /* Reset gestureRecognizer CGPoint back to zero once a changed has been reported */
                gestureRecognizer.setTranslation(CGPoint.zero, in: self)
                
                setNeedsDisplay()
            }
        } else {
            /* If no line selected */
            return
        }
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    @objc func deleteLine(_ sender: UIMenuController) {
        if let index = selectedLineIndex {
            finishedLines.remove(at: index)
            selectedLineIndex = nil
            setNeedsDisplay()
        }
    }
    
    func stroke(_ line: Line) {
        let path = UIBezierPath()
        path.lineWidth = lineThickness
        path.lineCapStyle = .round
        
        path.move(to: line.begin)
        path.addLine(to: line.end)
        path.stroke()
    }
    
    override func draw(_ rect: CGRect) {
        finishedLineColor.setStroke()
        for line in finishedLines {
            stroke(line)
        }
        
        currentLinesColor.setStroke()
        for (_, line) in currentLines {
            stroke(line)
        }
        
        if let index = selectedLineIndex {
            UIColor.green.setStroke()
            let selectedLine = finishedLines[index]
            stroke(selectedLine)
        }
    }
    
    /* Find the index of the tapped line */
    func indexOfLine(at point: CGPoint) -> Int? {
        for (index, line) in finishedLines.enumerated() {
            /* Find a line close to the point */
            let begin = line.begin
            let end = line.end
            
            for t in stride(from: CGFloat(0), to: 1.0, by: 0.05) {
                let x = begin.x + ((end.x - begin.x) * t)
                let y = begin.y + ((end.y - begin.y) * t)
                
                /* If the tapped point is within 20 points, return this line */
                if hypot(x - point.x, y - point.y) < 20 {
                    return index
                }
            }
        }
        
        /* Return if nothing found */
        return nil
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            let location = touch.location(in: self)
            let newLine = Line(begin: location, end: location)
            let key = NSValue(nonretainedObject: touch)
            currentLines[key] = newLine
        }
        
        setNeedsDisplay()
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            let key = NSValue(nonretainedObject: touch)
            currentLines[key]?.end = touch.location(in: self)
        }

        setNeedsDisplay()
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            let key = NSValue(nonretainedObject: touch)
            
            if var line = currentLines[key] {
                line.end = touch.location(in: self)
                finishedLines.append(line)
                currentLines.removeValue(forKey: key)
            }
        }
        
        setNeedsDisplay()
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        currentLines.removeAll()
        setNeedsDisplay()
    }
    
    override var canBecomeFirstResponder: Bool {
        return true
    }
}
