import Foundation
import UIKit
import Display
import AsyncDisplayKit
import SwiftSignalKit
import LegacyComponents

private let emojiFont = Font.regular(28.0)
private let textFont = Font.regular(15.0)

final class CallControllerKeyPreviewNode: ASDisplayNode {
    private let keyTextNode: ASTextNode
    private let headTextNode: ASTextNode
    private let infoTextNode: ASTextNode
    private let separatorNode: ASDisplayNode
    private let okButtonNode: ASButtonNode
    
    private let dismiss: () -> Void
    
    init(keyText: String, infoText: String, dismiss: @escaping () -> Void) {
        self.keyTextNode = ASTextNode()
        self.keyTextNode.displaysAsynchronously = false
        self.headTextNode = ASTextNode()
        self.headTextNode.displaysAsynchronously = false
        self.infoTextNode = ASTextNode()
        self.infoTextNode.displaysAsynchronously = false
        self.separatorNode = ASDisplayNode()
        self.separatorNode.displaysAsynchronously = false
        self.okButtonNode = ASButtonNode()
        self.okButtonNode.displaysAsynchronously = false
        self.dismiss = dismiss
        
        super.init()
        
        self.view.backgroundColor = UIColor.lightGray.withAlphaComponent(0.5)
        self.view.layer.cornerRadius = 20
        
        self.keyTextNode.attributedText = NSAttributedString(string: keyText, attributes: [NSAttributedString.Key.font: Font.regular(38.0), NSAttributedString.Key.kern: 11.0 as NSNumber])
        
        self.headTextNode.attributedText = NSAttributedString(string: "This call is end-to end encrypted", font: Font.bold(16.0), textColor: UIColor.white)
        
        self.infoTextNode.attributedText = NSAttributedString(string: infoText, font: Font.regular(16.0), textColor: UIColor.white, paragraphAlignment: .center)
        
        self.separatorNode.backgroundColor = UIColor.black.withAlphaComponent(0.1)
        
        self.okButtonNode.setTitle("OK", with: Font.regular(20.0), with: .white, for: .normal)
        self.okButtonNode.addTarget(self, action: #selector(okPressed), forControlEvents: .touchUpInside)
        
        //self.view.addSubview(self.effectView)
        self.addSubnode(self.keyTextNode)
        self.addSubnode(self.headTextNode)
        self.addSubnode(self.infoTextNode)
        self.addSubnode(self.separatorNode)
        self.addSubnode(self.okButtonNode)
    }
    
    override func didLoad() {
        super.didLoad()
        
        self.view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.tapGesture(_:))))
    }
    
    func updateLayout(size: CGSize, transition: ContainedViewLayoutTransition) {
        
        let keyTextSize = self.keyTextNode.measure(size)
        transition.updateFrame(node: self.keyTextNode, frame: CGRect(origin: CGPoint(x: floor((size.width - keyTextSize.width) / 2.0) + 6.0, y: 20.0), size: keyTextSize))
        
        let headTextSize = self.headTextNode.measure(CGSize(width: size.width - 32.0, height: CGFloat.greatestFiniteMagnitude))
        transition.updateFrame(node: self.headTextNode, frame: CGRect(origin: CGPoint(x: floor((size.width - headTextSize.width) / 2.0), y: 75.0), size: headTextSize))
        
        let infoTextSize = self.infoTextNode.measure(CGSize(width: size.width - 32.0, height: CGFloat.greatestFiniteMagnitude))
        transition.updateFrame(node: self.infoTextNode, frame: CGRect(origin: CGPoint(x: floor((size.width - infoTextSize.width) / 2.0), y: 105.0), size: infoTextSize))
        
        transition.updateFrame(node: self.separatorNode, frame: CGRect(origin: CGPoint(x: 0, y: 165), size: CGSize(width: self.frame.width, height: 1.0)))
        
        let okButtonSize = self.okButtonNode.measure(CGSize(width: size.width - 32.0, height: CGFloat.greatestFiniteMagnitude))
        transition.updateFrame(node: self.okButtonNode, frame: CGRect(origin: CGPoint(x: floor((size.width - okButtonSize.width) / 2.0), y: 180), size: okButtonSize))
    }
    
    func animateIn(from rect: CGRect, fromNode: ASDisplayNode) {
        self.keyTextNode.layer.animatePosition(from: CGPoint(x: rect.midX, y: rect.midY), to: self.keyTextNode.layer.position, duration: 0.3, timingFunction: kCAMediaTimingFunctionSpring)
        if let transitionView = fromNode.view.snapshotView(afterScreenUpdates: false) {
            self.view.addSubview(transitionView)
            transitionView.layer.animateAlpha(from: 1.0, to: 0.0, duration: 0.2, removeOnCompletion: false)
            transitionView.layer.animatePosition(from: CGPoint(x: rect.midX, y: rect.midY), to: self.keyTextNode.layer.position, duration: 0.3, timingFunction: kCAMediaTimingFunctionSpring, removeOnCompletion: false, completion: { [weak transitionView] _ in
                transitionView?.removeFromSuperview()
            })
            transitionView.layer.animateScale(from: 1.0, to: self.keyTextNode.frame.size.width / rect.size.width, duration: 0.3, timingFunction: kCAMediaTimingFunctionSpring, removeOnCompletion: false)
        }
        self.keyTextNode.layer.animateAlpha(from: 0.0, to: 1.0, duration: 0.15)
        
        self.keyTextNode.layer.animateScale(from: rect.size.width / self.keyTextNode.frame.size.width, to: 1.0, duration: 0.3, timingFunction: kCAMediaTimingFunctionSpring)
        
        self.infoTextNode.layer.animateAlpha(from: 0.0, to: 1.0, duration: 0.3)
        self.headTextNode.layer.animateAlpha(from: 0.0, to: 1.0, duration: 0.3)
        self.okButtonNode.layer.animateAlpha(from: 0.0, to: 1.0, duration: 0.3)
        self.view.layer.animateAlpha(from: 0.0, to: 1.0, duration: 0.3)
    }
    
    func animateOut(to rect: CGRect, toNode: ASDisplayNode, completion: @escaping () -> Void) {
        self.keyTextNode.layer.animatePosition(from: self.keyTextNode.layer.position, to: CGPoint(x: rect.midX, y: -70.0), duration: 0.3, timingFunction: kCAMediaTimingFunctionSpring, removeOnCompletion: false, completion: { _ in
            completion()
        })
        self.keyTextNode.layer.animateScale(from: 1.0, to: rect.size.width / (self.keyTextNode.frame.size.width - 2.0), duration: 0.3, timingFunction: kCAMediaTimingFunctionSpring, removeOnCompletion: false)
        
        self.keyTextNode.layer.animateAlpha(from: 1.0, to: 0.0, duration: 0.15, removeOnCompletion: false)
        self.infoTextNode.layer.animateAlpha(from: 1.0, to: 0.0, duration: 0.3, removeOnCompletion: false)
    }
    
    @objc func tapGesture(_ recognizer: UITapGestureRecognizer) {
        if case .ended = recognizer.state {
            self.dismiss()
        }
    }
    
    @objc func okPressed(_ sender: ASButtonNode) {
        self.dismiss()
    }
}
