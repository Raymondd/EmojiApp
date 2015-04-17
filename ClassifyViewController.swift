//
//  ViewController.swift
//  EmojiDraw
//
//  Created by Raymond Martin on 4/14/15.
//  Copyright (c) 2015 Raymond Martin. All rights reserved.
//

import UIKit


class ClassifyViewController: UIViewController, UITextFieldDelegate {
    var lastPoint = CGPoint.zeroPoint
    var swiped = false
    var brushWidth: CGFloat = 10.0
    var opacity: CGFloat = 1.0
    var predNum = 0;
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var actualValue: UITextField!
    
    @IBAction func submitPressed(sender: AnyObject) {
        //turn it into an image and send it to python server to add to our training set
        var value = actualValue.text
        
    }

    @IBAction func didChanged(sender: UITextField) {
        if(countElements(actualValue.text) > 1){
            actualValue.text = String(actualValue.text.substringToIndex(advance(actualValue.text.startIndex, 1)))
        }
    }

    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.actualValue.delegate = self;
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func touchesBegan(touches: NSSet, withEvent event: UIEvent) {
        var touches = touches.allObjects
        swiped = false
        if let touch = touches.first as? UITouch {
            lastPoint = touch.locationInView(self.view)
        }
    }
    
    func drawLineFrom(fromPoint: CGPoint, toPoint: CGPoint) {
        
        // 1
        UIGraphicsBeginImageContext(view.frame.size)
        let context = UIGraphicsGetCurrentContext()
        imageView.image?.drawInRect(CGRect(x: 0, y: 0, width: view.frame.size.width,  height: view.frame.size.height))
        
        // 2
        CGContextMoveToPoint(context, fromPoint.x, fromPoint.y)
        CGContextAddLineToPoint(context, toPoint.x, toPoint.y)
        
        // 3
        CGContextSetLineCap(context, kCGLineCapRound)
        CGContextSetLineWidth(context, brushWidth)
        CGContextSetBlendMode(context, kCGBlendModeNormal)
        
        // 4
        CGContextStrokePath(context)
        
        // 5
        imageView.image = UIGraphicsGetImageFromCurrentImageContext()
        imageView.alpha = opacity
        UIGraphicsEndImageContext()
        
    }
    
    override func touchesMoved(touches: NSSet, withEvent event: UIEvent) {
        // 6
        var touches = touches.allObjects
        swiped = true
        if let touch = touches.first as? UITouch {
            let currentPoint = touch.locationInView(view)
            drawLineFrom(lastPoint, toPoint: currentPoint)
            
            // 7
            lastPoint = currentPoint
        }
    }
    
    override func touchesEnded(touches: NSSet, withEvent event: UIEvent) {
        var touches = touches.allObjects
        
        if !swiped {
            // draw a single point
            drawLineFrom(lastPoint, toPoint: lastPoint)
        }
        
    }
    
    func textFieldShouldReturn(textField: UITextField!) -> Bool {
        self.view.endEditing(true)
        return false
    }
    
}


