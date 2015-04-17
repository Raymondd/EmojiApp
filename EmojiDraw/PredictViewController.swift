//
//  ViewController.swift
//  EmojiDraw
//
//  Created by Raymond Martin on 4/14/15.
//  Copyright (c) 2015 Raymond Martin. All rights reserved.
//

let SERVER_URL = "http://162.243.242.172:8000"

import UIKit

class PredictViewController: UIViewController,  UITextFieldDelegate, NSURLSessionDelegate{
    //drawing vars
    var lastPoint = CGPoint.zeroPoint
    var swiped = false
    var predNum = 0;
    let brushWidth: CGFloat = 20.0
    let opacity: CGFloat = 1.0
    let algos = ["KMeans", "SVM"]
    
    //setting up an alert system
    let alert = UIAlertView()
    
    //outlets to UI elements
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var prediction: UILabel!
    @IBOutlet weak var actualValue: UITextField!
    @IBOutlet weak var usableView: UIImageView!
    @IBOutlet weak var kmeansSlider: UISlider!
    @IBOutlet weak var algoSegment: UISegmentedControl!
    @IBOutlet weak var acc: UILabel!
    
    
    //networking vars
    var session = NSURLSession()
    var floatValue = 1.0
    var currentDSID = 1

    @IBAction func algoChanged(sender: AnyObject) {
        if(algoSegment.titleForSegmentAtIndex(algoSegment.selectedSegmentIndex) == "SVM"){
            kmeansSlider.enabled = false
        }else{
            kmeansSlider.enabled = true
        }
    }
    
    @IBAction func sliderChanged(sender: AnyObject) {
        algoSegment.setTitle("KMeans(K=\(Int(kmeansSlider.value)))", forSegmentAtIndex: 0)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.actualValue.delegate = self;
        prediction.text = "*"
        
        //connecting to our server
        var sessionConfig = NSURLSessionConfiguration.ephemeralSessionConfiguration()
        
        sessionConfig.timeoutIntervalForRequest = 5.0
        sessionConfig.timeoutIntervalForResource = 8.0
        sessionConfig.HTTPMaximumConnectionsPerHost = 1
        
        self.session = NSURLSession(configuration: sessionConfig, delegate: self, delegateQueue:NSOperationQueue.mainQueue())
        
        self.kmeansSlider.maximumValue = 10
        self.kmeansSlider.minimumValue = 1
        self.kmeansSlider.value = 5
    }
    
    @IBAction func submitPressed(sender: AnyObject) {
        //turn it into an image and send it to python server to add to our training set
        if(countElements(actualValue.text) == 1){
            let value = actualValue.text
            let image = getDrawing()
            sendFeatureDrawing(image, label: value)
        }else{
            alert.title = "Fill Out Label"
            alert.addButtonWithTitle("OK")
            alert.show()
        }
    }
    
    
    @IBAction func textChanged(sender: AnyObject) {
        if(countElements(actualValue.text) > 1){
            actualValue.text = String(actualValue.text.substringToIndex(advance(actualValue.text.startIndex, 1)))
        }
    }
    
    @IBAction func clearPressed(sender: AnyObject) {
        imageView.image = nil
        prediction.text = "*"
        acc.text = "0.0"
    }
    
    func predictDrawing(){
        let image = getDrawing()
        prediction.text = "*"
        predictDrawing(image)
    }
    

    
    
    @IBAction func traindModelPressed(sender: AnyObject) {
        updateModel()
    }
    
    func sendFeatureDrawing(drawing: UIImage, label: String) {
        
        //setting up our URL
        let baseURL = "\(SERVER_URL)/AddDataPoint"
        let postUrl = NSURL(string: "\(baseURL)")
        
        //resize the image and encode it into a .png
        let imageData: NSData = UIImagePNGRepresentation(RBResizeImage(drawing, scaleFactor: 0.5))
        let imageData2: String = imageData.base64EncodedStringWithOptions(NSDataBase64EncodingOptions(rawValue: 0))
        
        //create our dictionary to upload our feature data with
        let jsonUpload: NSDictionary = ["feature": imageData2, "label": label,"dsid":currentDSID]
        //turn our dictionary into a json object
        var jsonError: NSError? = nil
        var requestBody:NSData? = NSJSONSerialization.dataWithJSONObject(jsonUpload, options:NSJSONWritingOptions.PrettyPrinted, error:&jsonError);
        
        // create a custom HTTP POST request
        var request = NSMutableURLRequest(URL: postUrl!)
        
        request.HTTPMethod = "POST"
        request.HTTPBody = requestBody
        
        let postTask : NSURLSessionDataTask = self.session.dataTaskWithRequest(request,
            completionHandler:{(data, response, error) in
                if((response) != nil){
                    //unpacking needed data
                    NSLog("Response:\n%@",response)
                    
                    
                    var jsonError: NSError?
                    var jsonDictionary: NSDictionary = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.MutableContainers, error: &jsonError) as NSDictionary
                    
                    NSLog("\n\nJSON Data:\n%@",jsonDictionary)
                    
                    dispatch_async(dispatch_get_main_queue(),{
                        self.alert.title = "Feature Has Been Added"
                        self.alert.message = ""
                        self.alert.addButtonWithTitle("OK")
                        self.alert.show()
                        self.imageView.image = nil
                    })
                    
                }else{
                    dispatch_async(dispatch_get_main_queue(),{
                        self.alert.title = "Cannot Talk To Server"
                        self.alert.message = "Please Try Again Later."
                        self.alert.addButtonWithTitle("OK")
                        self.alert.show()
                    })
                }
        })
        
        postTask.resume() // start the task
        
    }
    
    func predictDrawing(drawing: UIImage){
        //setting up our URL
        let baseURL = "\(SERVER_URL)/PredictOne"
        let postUrl = NSURL(string: "\(baseURL)")
        
        //converting our image into a format we can send in a json object
        let imageData: NSData = UIImagePNGRepresentation(RBResizeImage(drawing, scaleFactor: 0.5))
        let imageData_64: String = imageData.base64EncodedStringWithOptions(NSDataBase64EncodingOptions(rawValue: 0))
        
        //create our dictionary to upload our feature data with
        let jsonUpload: NSDictionary = ["feature": imageData_64, "dsid":currentDSID]
        //turn our dictionary into a json object
        var jsonError: NSError? = nil
        var requestBody:NSData? = NSJSONSerialization.dataWithJSONObject(jsonUpload, options:NSJSONWritingOptions.PrettyPrinted, error:&jsonError);
        
        // create a custom HTTP POST request
        var request = NSMutableURLRequest(URL: postUrl!)
        
        request.HTTPMethod = "POST"
        request.HTTPBody = requestBody
        
        let postTask : NSURLSessionDataTask = self.session.dataTaskWithRequest(request,
            completionHandler:{(data, response, error) in
                //print the response and getting the prediction we need
                if((response) != nil){
                    //unpacking needed data
                    NSLog("Response:\n%@",response)
                    
                    var jsonError: NSError?
                    var jsonDictionary: NSDictionary = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.MutableContainers, error: &jsonError) as NSDictionary

                    print(jsonDictionary)
                    
                    let predictionLabel = jsonDictionary.valueForKey("prediction") as String!
                    let pred = predictionLabel
                    NSLog("PREDICTION: " + pred)
                    
                    var probLabel = jsonDictionary.valueForKey("prob") as String!
                    NSLog("PROB: " + probLabel)
                    
                    //changing our UI on the main thread
                    dispatch_async(dispatch_get_main_queue(),{
                        //fill in our prediction text box with our actual prediction
                        self.prediction.text = pred
                        self.acc.text = probLabel.substringToIndex(advance(probLabel.startIndex, 4))
                    })
                }else{
                    dispatch_async(dispatch_get_main_queue(),{
                        self.alert.title = "Cannot Talk To Server"
                        self.alert.message = "Please Try Again Later."
                        self.alert.addButtonWithTitle("OK")
                        self.alert.show()
                    })
                }
                
                
        })
        
        postTask.resume() // start the task
        
        
    }
    
    func fetchNewID(){
        //setting up our URL
        let baseURL = "\(SERVER_URL)/GetNewDatasetId"
        
        let getUrl = NSURL(string: "\(baseURL)")
        var request: NSURLRequest = NSURLRequest(URL: getUrl!)
        let dataTask : NSURLSessionDataTask = self.session.dataTaskWithRequest(request,
            completionHandler:{(data, response, error) in
                if(response != nil){
                    //unpacking needed data
                    NSLog("Response:\n%@",response)
                    var jsonError: NSError?
                    
                    var jsonDictionary: NSDictionary = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.MutableContainers, error: &jsonError) as NSDictionary
                    print(jsonDictionary)
                    
                    //let dsidLabel = "5"
                    let dsidLabel = jsonDictionary.valueForKey("dsid") as String!
                    self.currentDSID = (dsidLabel as NSString).integerValue
                    
                    dispatch_async(dispatch_get_main_queue(),{
                        //self.DSISLabel.text = dsidLabel
                    })
                    
                }else{
                    dispatch_async(dispatch_get_main_queue(),{
                        self.alert.title = "Cannot Talk To Server"
                        self.alert.message = "Please Try Again Later."
                        self.alert.addButtonWithTitle("OK")
                        self.alert.show()
                    })
                }
        })
        
        dataTask.resume()
        
    }
    
    func updateModel(){
        //setting up our URL
        let baseURL = "\(SERVER_URL)/UpdateModel?dsid=\(Int(currentDSID))&aglorithmSelection=\(Int(algoSegment.selectedSegmentIndex))&kNeighbors=\(Int(kmeansSlider.value))"
        let getUrl = NSURL(string: "\(baseURL)")
        
        print(getUrl)
        
        // create a custom HTTP GET request
        var request = NSMutableURLRequest(URL: getUrl!)
        
        let dataTask : NSURLSessionDataTask = self.session.dataTaskWithRequest(request,
            completionHandler:{(data, response, error) in
                if(response != nil){
                    //unpacking needed data
                    NSLog("Response:\n%@",response)
                    var jsonError: NSError?
                    var jsonDictionary: NSDictionary = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.MutableContainers, error: &jsonError) as NSDictionary
                    print(jsonDictionary)
                    
                    self.alert.title = "Model Trained"
                    self.alert.message = ""
                    self.alert.addButtonWithTitle("OK")
                    self.alert.show()
                    
                }else{
                    dispatch_async(dispatch_get_main_queue(),{
                        self.alert.title = "Cannot Talk To Server"
                        self.alert.message = "Please Try Again Later."
                        self.alert.addButtonWithTitle("OK")
                        self.alert.show()
                    })
                }
        })
        
        dataTask.resume() // start the task
        
    }
    
    
    
    
    
    //functions to handle drawing onto our screen----------------------------
    func getDrawing() -> UIImage{
        UIGraphicsBeginImageContext(self.usableView.frame.size)
        self.view.layer.renderInContext(UIGraphicsGetCurrentContext())
        //view.layer.renderInContext(UIGraphicsGetCurrentContext())
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return image;
    }
    
   override func touchesBegan(touches: NSSet, withEvent event: UIEvent) {
    var touches = touches.allObjects
    swiped = false
        if let touch = touches.first as? UITouch {
            lastPoint = touch.locationInView(self.view)
        }
    }
    
    func drawLineFrom(fromPoint: CGPoint, toPoint: CGPoint) {
        
        // settup context
        UIGraphicsBeginImageContext(view.frame.size)
        let context = UIGraphicsGetCurrentContext()
        imageView.image?.drawInRect(CGRect(x: 0, y: 0, width: view.frame.size.width,  height: view.frame.size.height))
        
        // find where to draw
        CGContextMoveToPoint(context, fromPoint.x, fromPoint.y)
        CGContextAddLineToPoint(context, toPoint.x, toPoint.y)
        
        // set properties of line
        CGContextSetLineCap(context, kCGLineCapRound)
        CGContextSetLineWidth(context, brushWidth)
        CGContextSetBlendMode(context, kCGBlendModeNormal)
        
        // apply context
        CGContextStrokePath(context)
        
        //save the image
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
        
        predictDrawing()
        
    }

    func textFieldShouldReturn(textField: UITextField!) -> Bool {
        self.view.endEditing(true)
        return false
    }
    
    
    //this function is adapted from https://gist.github.com/hcatlin/180e81cd961573e3c54d
    //it reszes an image based on an input scale factor
    func RBResizeImage(image: UIImage, scaleFactor: CGFloat) -> UIImage {
        let size = image.size
        
        // Figure out what our orientation is, and use that to form the rectangle
        var newSize: CGSize
        newSize = CGSizeMake(size.width * scaleFactor,  size.height * scaleFactor)
        
        // This is the rect that we've calculated out and this is what is actually used below
        let rect = CGRectMake(0, 0, newSize.width, newSize.height)
        
        // Actually do the resizing to the rect using the ImageContext stuff
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.drawInRect(rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage
    }


}

