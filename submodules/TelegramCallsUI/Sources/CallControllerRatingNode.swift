import Foundation
import UIKit
import Display
import AsyncDisplayKit
import SwiftSignalKit
import LegacyComponents
import Postbox
import TelegramCore
import TelegramPresentationData
import TelegramVoip
import AccountContext
import AppBundle

final class CallControllerRatingNode: ASDisplayNode {
    private let rateContainerNode: ASDisplayNode
    private let starContainerNode: ASDisplayNode
    private let headTextNode: ASTextNode
    private let infoTextNode: ASTextNode
    private let starNodes: [ASButtonNode]
    private let closeButton: ASButtonNode
    private let closeButtonFrame: ASDisplayNode
    
    var rating: Int?
    let account: Account
    let callId: CallId
    let parent: CallControllerNode
    
    init(account: Account, callId: CallId, parent: CallControllerNode) {
        self.rateContainerNode = ASDisplayNode()
        self.starContainerNode = ASDisplayNode()
        
        self.headTextNode = ASTextNode()
        self.infoTextNode = ASTextNode()
        
        var starNodes: [ASButtonNode] = []
        for _ in 0 ..< 5 {
            starNodes.append(ASButtonNode())
        }
        self.starNodes = starNodes
        
        self.closeButtonFrame = ASDisplayNode()
        self.closeButton = ASButtonNode()
        self.account = account
        self.callId = callId
        self.parent = parent
        
        super.init()
        
        self.rateContainerNode.backgroundColor = UIColor.lightGray.withAlphaComponent(0.3)
        self.rateContainerNode.layer.cornerRadius = 20
        
        self.addSubnode(rateContainerNode)
        
        self.headTextNode.attributedText = NSAttributedString(string: "Rate this call", font: Font.bold(16.0), textColor: UIColor.white)
        self.infoTextNode.attributedText = NSAttributedString(string: "Please rate the quality of this call", font: Font.regular(16.0), textColor: UIColor.white)
        self.rateContainerNode.addSubnode(headTextNode)
        self.rateContainerNode.addSubnode(infoTextNode)
        
        self.rateContainerNode.addSubnode(self.starContainerNode)
        for node in self.starNodes {
            node.addTarget(self, action: #selector(self.starPressed(_:)), forControlEvents: .touchDown)
            node.addTarget(self, action: #selector(self.starReleased(_:)), forControlEvents: .touchUpInside)
            self.starContainerNode.addSubnode(node)
            
            node.setImage(generateTintedImage(image: UIImage(bundleImageName: "Call/Star"), color: UIColor.white), for: [])
            let highlighted = generateTintedImage(image: UIImage(bundleImageName: "Call/StarHighlighted"), color: UIColor.white)
            node.setImage(highlighted, for: [.selected])
            node.setImage(highlighted, for: [.selected, .highlighted])
        }
        
        self.closeButtonFrame.backgroundColor = UIColor.white
        self.closeButtonFrame.layer.cornerRadius = 10
        self.addSubnode(self.closeButtonFrame)
        
        self.closeButton.setTitle("Close", with: Font.regular(16.0), with: UIColor.black, for: .normal)
        self.closeButton.addTarget(self, action: #selector(self.closePressed(_:)), forControlEvents: .touchDown)
        self.closeButton.backgroundColor = UIColor.lightGray.withAlphaComponent(0.3)
        self.closeButton.layer.cornerRadius = 10
        self.addSubnode(self.closeButton)
    }
    
    override func didLoad() {
        super.didLoad()

        self.starContainerNode.view.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(self.panGesture(_:))))
    }
    
    func updateLayout(size: CGSize, transition: ContainedViewLayoutTransition) {
        
        transition.updateFrame(node: self.rateContainerNode, frame: CGRect(x: 0, y: 0, width: size.width, height: 140))
        let headTextSize = self.headTextNode.measure(size)
        transition.updateFrame(node: self.headTextNode, frame: CGRect(x: floor((size.width - headTextSize.width) / 2.0), y: 20, width: headTextSize.width, height: headTextSize.height))
        let infoTextSize = self.infoTextNode.measure(size)
        transition.updateFrame(node: self.infoTextNode, frame: CGRect(x: floor((size.width - infoTextSize.width) / 2.0), y: 50, width: infoTextSize.width, height: infoTextSize.height))
        
        let starSize = CGSize(width: 42.0, height: 42.0)
        for i in 0 ..< self.starNodes.count {
            let node = self.starNodes[i]
            transition.updateFrame(node: node, frame: CGRect(x: starSize.width * CGFloat(i), y: 0.0, width: starSize.width, height: starSize.height))
        }
        let starContainerSize = CGSize(width: 210.0, height: 42.0)
        self.starContainerNode.frame = CGRect(x: floor((size.width - starContainerSize.width) / 2.0), y: 80, width: starContainerSize.width, height: starContainerSize.height)
           
        transition.updateFrame(node: self.closeButtonFrame, frame: CGRect(x: 0, y: 210, width: size.width, height: 50))
        transition.updateFrame(node: self.closeButton, frame: CGRect(x: 0, y: 210, width: size.width, height: 50))
    }
    
    func animateIn() {
        
        let currentButtonFrame = self.closeButtonFrame.frame
        let newButtonFrame = CGRect(x: currentButtonFrame.width, y: currentButtonFrame.origin.y, width: 0, height: currentButtonFrame.height)
        self.closeButtonFrame.layer.animateFrame(from: currentButtonFrame, to: newButtonFrame, duration: 6) { [weak self] (completed) in
            if !completed {
                return
            }
            
            guard let strongSelf = self else {
                return
            }

            strongSelf.parent.callEnded?(true)
            strongSelf.parent.isRatingNodePresented = false
            strongSelf.parent.animateOut(completion: {})
        }
        
    }
    
    @objc func closePressed(_ sender: ASButtonNode) {
        self.parent.callEnded?(true)
        self.parent.isRatingNodePresented = false
        self.parent.animateOut(completion: {})
    }
    
    @objc func panGesture(_ gestureRecognizer: UIPanGestureRecognizer) {
        let location = gestureRecognizer.location(in: self.starContainerNode.view)
        var selectedNode: ASButtonNode?
        for node in self.starNodes {
            if node.frame.contains(location) {
                selectedNode = node
                break
            }
        }
        if let selectedNode = selectedNode {
            switch gestureRecognizer.state {
                case .began, .changed:
                    self.starPressed(selectedNode)
                case .ended:
                    self.starReleased(selectedNode)
                case .cancelled:
                    self.resetStars()
                default:
                    break
            }
        } else {
            self.resetStars()
        }
    }
    
    private func resetStars() {
        for i in 0 ..< self.starNodes.count {
            let node = self.starNodes[i]
            node.isSelected = false
        }
    }
    
    @objc func starPressed(_ sender: ASButtonNode) {
        if let index = self.starNodes.firstIndex(of: sender) {
            self.rating = index + 1
            for i in 0 ..< self.starNodes.count {
                let node = self.starNodes[i]
                node.isSelected = i <= index
            }
            let _ = self.rateCallAndSendLogs(engine: TelegramEngine(account: self.account), callId: self.callId, starsCount: self.rating!, comment: "", userInitiated: false, includeLogs: false).start()
            self.parent.callEnded?(true)
            self.parent.isRatingNodePresented = false
            self.parent.animateOut(completion: {})
        }
    }
    
    @objc func starReleased(_ sender: ASButtonNode) {
        if let index = self.starNodes.firstIndex(of: sender) {
            self.rating = index + 1
            for i in 0 ..< self.starNodes.count {
                let node = self.starNodes[i]
                node.isSelected = i <= index
            }
        }
    }
    
    func rateCallAndSendLogs(engine: TelegramEngine, callId: CallId, starsCount: Int, comment: String, userInitiated: Bool, includeLogs: Bool) -> Signal<Void, NoError> {
        let peerId = PeerId(namespace: Namespaces.Peer.CloudUser, id: PeerId.Id._internalFromInt64Value(4244000))

        let rate = engine.calls.rateCall(callId: callId, starsCount: Int32(starsCount), comment: comment, userInitiated: userInitiated)
        if includeLogs {
            let id = Int64.random(in: Int64.min ... Int64.max)
            let name = "\(callId.id)_\(callId.accessHash).log.json"
            let path = callLogsPath(account: engine.account) + "/" + name
            let file = TelegramMediaFile(fileId: MediaId(namespace: Namespaces.Media.LocalFile, id: id), partialReference: nil, resource: LocalFileReferenceMediaResource(localFilePath: path, randomId: id), previewRepresentations: [], videoThumbnails: [], immediateThumbnailData: nil, mimeType: "application/text", size: nil, attributes: [.FileName(fileName: name)])
            let message = EnqueueMessage.message(text: comment, attributes: [], inlineStickers: [:], mediaReference: .standalone(media: file), replyToMessageId: nil, localGroupingKey: nil, correlationId: nil, bubbleUpEmojiOrStickersets: [])
            return rate
            |> then(enqueueMessages(account: engine.account, peerId: peerId, messages: [message])
            |> mapToSignal({ _ -> Signal<Void, NoError> in
                return .single(Void())
            }))
        } else if !comment.isEmpty {
            return rate
            |> then(enqueueMessages(account: engine.account, peerId: peerId, messages: [.message(text: comment, attributes: [], inlineStickers: [:], mediaReference: nil, replyToMessageId: nil, localGroupingKey: nil, correlationId: nil, bubbleUpEmojiOrStickersets: [])])
            |> mapToSignal({ _ -> Signal<Void, NoError> in
                return .single(Void())
            }))
        } else {
            return rate
        }
    }
}
