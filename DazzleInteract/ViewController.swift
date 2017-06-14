//
//  ViewController.swift
//  DazzleInteract
//
//  Created by zjbpha on 2017/6/13.
//  Copyright © 2017年 Dazzle Interactive. All rights reserved.
//

import UIKit
import CoreText
import CoreGraphics
import CoreFoundation

class ViewController: UIViewController,UITableViewDelegate,UITableViewDataSource {
    
    @available(iOS 2.0, *)
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 25
    }
    
    @available(iOS 2.0, *)
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell_id = "cellid"
        var cell = tableView.dequeueReusableCell(withIdentifier: cell_id);
        if cell == nil {
            cell = UITableViewCell(style: .default, reuseIdentifier: cell_id)
            cell?.textLabel?.text = "\(indexPath.row)"
        }
        
        cell?.textLabel?.text = "\(indexPath.row)"
        cell?.textLabel?.textAlignment = .center
        return cell!
    }
    

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        let table = UITableView(frame: UIScreen.main.bounds, style: .plain);
        table.delegate = self
        table.dataSource = self;
        self.view.addSubview(table);
        table.di_addHeaderRefresh(navigationBar: true) {
            
        }
        
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

typealias ActionHandler = () -> Void
class DIRefreshView: UIView {
    
    weak var weakScroll: UIScrollView?
    var height: CGFloat = 0
    var action: ActionHandler?
    var animationLayer: CALayer?
    var pathLayer: CAShapeLayer?
    var originOffset: CGFloat = 0
    
    var process: CGFloat = 0 {
        didSet {
            progressValueChanged(progress: process)
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    convenience init(scrollview: UIScrollView, navi: Bool = false, height: CGFloat, action: @escaping ActionHandler) {
        let width = UIScreen.main.bounds.size.width
        self.init(frame: CGRect(x: 0.0, y: -CGFloat(height), width: CGFloat(width), height: CGFloat(height)))
        self.weakScroll = scrollview
        self.weakScroll?.addObserver(self, forKeyPath: "contentOffset", options: .new, context: nil)
        self.weakScroll?.panGestureRecognizer.addObserver(self, forKeyPath: "state", options: .new, context: nil)
        self.height = height
        self.action = action
        self.originOffset = navi ? 64 : 20
        self.animationLayer = CALayer()
        if let layer = self.animationLayer {
            animationLayer?.frame = CGRect(x: 0, y: 0, width: CGFloat(width), height: CGFloat(height));
            self.layer.addSublayer(layer)
            addPullAnimation()
        }
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        self.weakScroll?.removeObserver(self, forKeyPath: "contentOffset")
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        
        if keyPath == "contentOffset" {
            guard let contentOffset = change?[.newKey] as? CGPoint else {
                return
            }
            if contentOffset.y + originOffset < 0 {
                let _min = min(fabs(contentOffset.y + originOffset)/height, 1.0)
                let _max = max(0.0, _min)
                self.process = _max
            }
        } else if keyPath == "state" {
            guard let _state = change?[.newKey] as? Int else {
                return
            }
            let state = UIGestureRecognizerState(rawValue: _state)
            if state == .cancelled || state == .ended {
                UIView.animate(withDuration: 0.25, animations: {
                    self.weakScroll?.contentInset = UIEdgeInsetsMake(44, 0, 0, 0)
                }, completion: { (finish) in
                    if finish {
                        DispatchQueue.global(qos: DispatchQoS.background.qosClass).async {
                            sleep(3)
                            DispatchQueue.main.async {
                                UIView.animate(withDuration: 0.25, animations: {
                                    self.weakScroll?.contentInset = UIEdgeInsetsMake(0, 0, 0, 0)
                                }, completion: { (end) in
                                    if (end) { self.process = 0.0 }
                                })
                            }
                        }
                    }
                })
            }
        }
    }
    
    func progressValueChanged(progress: CGFloat) {
        if let path = self.pathLayer {
            path.strokeEnd = process
        }
    }
    
    func addPullAnimation() {
        let shapelayer = getShapeLayer()
        shapelayer.strokeEnd = 0.0
        self.pathLayer = shapelayer
        if let alayer = self.animationLayer {
            shapelayer.position = CGPoint(x:self.bounds.size.width/2.0,
                                         y:self.bounds.size.height/2.0)
            alayer.addSublayer(shapelayer)
        }
    }
    
    func getShapeLayer() -> CAShapeLayer {
        let letter_path = getLetterPaths(letter: "Dazzle Interactive")
        let path = UIBezierPath()
        path.move(to: .zero)
        if let letter_path_value = letter_path {
            path.append(UIBezierPath(cgPath: letter_path_value))
        }
        
        let shape = CAShapeLayer()
        shape.bounds = path.cgPath.boundingBox
        shape.isGeometryFlipped = true
        shape.path = path.cgPath
        shape.strokeColor = UIColor(colorLiteralRed: 234.0/255, green: 84.0/255, blue: 87.0/255, alpha: 1.0).cgColor
        shape.fillColor = nil
        shape.lineWidth = 1.0
        shape.lineJoin = kCALineJoinBevel;
        
        return shape
    }
    
    func getLetterPaths(letter: String) -> CGPath? {
        if letter.isEmpty { return nil }
        let attributeString = NSMutableAttributedString(string: letter)
        attributeString.setAttributes([kCTFontAttributeName as NSAttributedStringKey:UIFont.boldSystemFont(ofSize: 20)],
                                      range: NSRange(location: 0, length: letter.characters.count))
        
        let ctline = CTLineCreateWithAttributedString(attributeString)
        let runs = CTLineGetGlyphRuns(ctline)
        let run_count = CFArrayGetCount(runs)
        let letters = CGMutablePath()
        for run_item in (0..<run_count) {
            //https://forums.developer.apple.com/thread/11171
            guard let _run = CFArrayGetValueAtIndex(runs, run_item) else {
                continue
            }
            let run = unsafeBitCast(_run, to: CTRun.self)
            
            let gyph_count = CTRunGetGlyphCount(run)
            let runFont = unsafeBitCast(CFDictionaryGetValue(CTRunGetAttributes(run), unsafeBitCast(kCTFontAttributeName, to: UnsafeRawPointer.self)), to: CTFont.self)
            
            for glyph_item in (0..<gyph_count) {
                let range = CFRangeMake(glyph_item, 1)
                var glyp: CGGlyph = 0
                var position: CGPoint = .zero
                CTRunGetPositions(run, range, &position)
                CTRunGetGlyphs(run, range, &glyp)
                
                let letter = CTFontCreatePathForGlyph(runFont, glyp, nil)
                let transform = CGAffineTransform(translationX: position.x, y: position.y)
                if let letterpath = letter {
                    letters.addPath(letterpath, transform: transform)
                }
                
            }
        }
        return letters
    }
    
}

//https://stackoverflow.com/questions/25426780/how-to-have-stored-properties-in-swift-the-same-way-i-had-on-objective-c
public final class ObjectAssociation<T: AnyObject> {
    private let policy: objc_AssociationPolicy
    /// - Parameter policy: An association policy that will be used when linking objects.
    public init(policy: objc_AssociationPolicy = .OBJC_ASSOCIATION_RETAIN_NONATOMIC) {
        self.policy = policy
    }
    /// Accesses associated object.
    /// - Parameter index: An object whose associated object is to be accessed.
    public subscript(index: AnyObject) -> T? {
        get { return objc_getAssociatedObject(index, Unmanaged.passUnretained(self).toOpaque()) as! T? }
        set { objc_setAssociatedObject(index, Unmanaged.passUnretained(self).toOpaque(), newValue, policy) }
    }
}

fileprivate extension UIScrollView {
    
    private static let association = ObjectAssociation<DIRefreshView>()
    var di_header: DIRefreshView? {
        get { return UIScrollView.association[self] }
        set { UIScrollView.association[self] = newValue }
    }
    
    func di_addHeaderRefresh(navigationBar: Bool,actionHandler: @escaping ActionHandler) {
        self.di_header = DIRefreshView(scrollview: self, height: 44.0, action: actionHandler)
        if let header = self.di_header {
            self.insertSubview(header, at: 0)
        }
    }
    
}




