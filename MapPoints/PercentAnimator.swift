//
//  PercentAnimator.swift
//  MapPoints
//
//  Created by Evgeny Karev on 10.05.17.
//  Copyright © 2017 Evgeny Karev. All rights reserved.
//

import Foundation
import UIKit

struct AnimationState {
    static func affineTransformMake(rotationAngle: Double, transitionX: Double, transitionY: Double) -> CGAffineTransform {
        return CGAffineTransform(rotationAngle: CGFloat(rotationAngle)).concatenating(CGAffineTransform(translationX: CGFloat(transitionX), y: CGFloat(transitionY)))
    }
    
    var alpha: Double
    
    private var _transform: CGAffineTransform

    private mutating func recalcTransform() {
        _transform = AnimationState.affineTransformMake(rotationAngle: rotationAngle, transitionX: transitionX, transitionY: transitionY)
    }

    var rotationAngle: Double {
        didSet {
            recalcTransform()
        }
    }

    var transitionX: Double{
        didSet {
            recalcTransform()
        }
    }

    var transitionY: Double{
        didSet {
            recalcTransform()
        }
    }
    
    init(alpha: Double, rotationAngle: Double, transitionX: Double, transitionY: Double) {
        self.alpha = min(max(0, alpha), 1)

        self.rotationAngle = rotationAngle
        self.transitionX = transitionX
        self.transitionY = transitionY
        
        // init transform
        self._transform = AnimationState.affineTransformMake(rotationAngle: rotationAngle, transitionX: transitionX, transitionY: transitionY)
    }
    
    var transform: CGAffineTransform {
        return self._transform
    }
}

class PercentAnimator {
    static func radians(fromDegrees degrees: Double) -> Double {
        return Double.pi * degrees / 180.0
    }
    
    private var startState: AnimationState
    private var endState: AnimationState

    var startAlpha: CGFloat {
        return CGFloat(startState.alpha)
    }
    
    var startTransform: CGAffineTransform {
        return startState.transform
    }
    
    var endAlpha: CGFloat {
        return CGFloat(endState.alpha)
    }
    
    var endTransform: CGAffineTransform {
        return endState.transform
    }
    

    init(startState: AnimationState) {
        self.startState = startState

        self.endState = AnimationState(alpha: 1, rotationAngle: 0, transitionX: 0, transitionY: 0)
    }
    
    convenience init(alpha: Double, rotationAngle: Double, transitionX: Double, transitionY: Double) {
        let startState = AnimationState(alpha: alpha, rotationAngle: rotationAngle, transitionX: transitionX, transitionY: transitionY)
        
        self.init(startState: startState)
    }
    
    func setEndState(_ endState: AnimationState) {
        self.endState = endState
    }
    
    func state(forPercent percent: Double) -> AnimationState {
        let percent = min(max(0, percent), 1)
        
        let alpha = startState.alpha + (endState.alpha - startState.alpha) * percent

        let rotationAngle = startState.rotationAngle + (endState.rotationAngle - startState.rotationAngle) * percent
        let transitionX = startState.transitionX + (endState.transitionX - startState.transitionX) * percent
        let transitionY = startState.transitionY + (endState.transitionY - startState.transitionY) * percent

        let state = AnimationState(alpha: alpha, rotationAngle: rotationAngle, transitionX: transitionX, transitionY: transitionY)
        
        return state
    }
    
    func transform(forPercent percent: Double) -> CGAffineTransform {
        let percent = min(max(0, percent), 1)
        
        let rotationAngle = startState.rotationAngle + (endState.rotationAngle - startState.rotationAngle) * percent
        let transitionX = startState.transitionX + (endState.transitionX - startState.transitionX) * percent
        let transitionY = startState.transitionY + (endState.transitionY - startState.transitionY) * percent
        
        return AnimationState.affineTransformMake(rotationAngle: rotationAngle, transitionX: transitionX, transitionY: transitionY)
    }
    
    func alpha(forPercent percent: Double) -> CGFloat {
        let percent = min(max(0, percent), 1)
        
        let alpha = startState.alpha + (endState.alpha - startState.alpha) * percent
        
        return CGFloat(alpha)
    }
}
