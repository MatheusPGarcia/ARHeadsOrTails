//
//  ViewController.swift
//  HeadsOrTails
//
//  Created by Matheus Garcia on 18/07/18.
//  Copyright © 2018 Matheus Garcia. All rights reserved.
//

import UIKit
import ARKit

class ViewController: UIViewController {

    @IBOutlet weak var arSceneView: ARSCNView!
    @IBOutlet weak var feedbackBox: UIView!
    @IBOutlet weak var feedbackLabel: UILabel!
    @IBOutlet weak var resultView: UIView!
    @IBOutlet weak var resultLabel: UILabel!
    @IBOutlet weak var howToView: UIView!
    
    var coinNode: SCNNode?
    var startPosition: SCNVector3?
    var coin = Coin.heads

    override func viewDidLoad() {
        super.viewDidLoad()

        configureLighting()
        addTapGestureToSceneView()

        resultView.alpha = 0
        resultView.layer.masksToBounds = true
        resultView.layer.cornerRadius = 7.5

        howToView.alpha = 0
        howToView.layer.masksToBounds = true
        howToView.layer.cornerRadius = 7.5

        let swipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(flipCoin(_:)))
        swipeGesture.direction = .up
        view.addGestureRecognizer(swipeGesture)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setUpSceneView()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        arSceneView.session.pause()
    }

    func setUpSceneView() {
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal

        arSceneView.session.run(configuration, options: [.removeExistingAnchors, .resetTracking])

        arSceneView.delegate = self
//        arSceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints]
    }

    func configureLighting() {
        arSceneView.autoenablesDefaultLighting = true
        arSceneView.automaticallyUpdatesLighting = true
    }

    func addTapGestureToSceneView() {
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(ViewController.handleTap(withGestureRecognizer:)))
        arSceneView.addGestureRecognizer(tapGestureRecognizer)
    }

    @objc func handleTap(withGestureRecognizer recognizer: UIGestureRecognizer) {

        guard coinNode != nil else {
            addCoinToSceneView(recognizer)
            return
        }

        updateCoinPosition(recognizer)
    }

    func addCoinToSceneView(_ recognizer: UIGestureRecognizer) {

        let position = getPosition(recognizer)

        guard let coinScene = SCNScene(named: "Coin.scn"),
            let coinNode = coinScene.rootNode.childNode(withName: "coin", recursively: false)
            else { return }

        coinNode.position = position

        self.coinNode = coinNode
        arSceneView.scene.rootNode.childNodes[2].isHidden = true
        arSceneView.scene.rootNode.addChildNode(coinNode)

        hideFeedbackBox()
        
        self.resultLabel.text = "Swipe up flip the coin"

        UIView.animate(withDuration: 1,
                       delay: 0,
                       options: .curveEaseIn,
                       animations: {
                        self.howToView.alpha = 1
        }, completion: nil)
        UIView.animate(withDuration: 0.5,
                       delay: 2,
                       options: .curveEaseIn,
                       animations: {
                        self.howToView.alpha = 0
        }, completion: nil)
    }

    func updateCoinPosition(_ recognizer: UIGestureRecognizer) {

        let position = getPosition(recognizer)

        coinNode?.position = position
    }

    func getPosition(_ recognizer: UIGestureRecognizer) -> SCNVector3 {

        let tapLocation = recognizer.location(in: arSceneView)
        let hitTestResults = arSceneView.hitTest(tapLocation, types: .existingPlaneUsingExtent)

        guard let hitTestResult = hitTestResults.first else { return SCNVector3() }
        let translation = hitTestResult.worldTransform.translation
        let x = translation.x
        let y = translation.y
        let z = translation.z

        let position = SCNVector3(x, y, z)
        return position
    }

    @objc func flipCoin(_ gesture: UISwipeGestureRecognizer) {

        guard coinNode != nil else { return }

        let duration: Double = 0.3
        let yDistance: CGFloat = 0.25

        let flips = CGFloat(arc4random_uniform(30) + 50)
        let flipAngle = .pi * flips

        let upAction = SCNAction.moveBy(x: 0, y: yDistance, z: 0, duration: duration)
        let downAction = SCNAction.moveBy(x: 0, y: -yDistance, z: 0, duration: duration)
        let flipAction = SCNAction.rotateBy(x: flipAngle, y: 0, z: 0, duration: (duration * 2))

        upAction.timingMode = .easeOut
        downAction.timingMode = .easeIn

        let actionsArray = [upAction, downAction]
        let animationSequence = SCNAction.sequence(actionsArray)

        coinNode?.runAction(animationSequence)
        coinNode?.runAction(flipAction)

        DispatchQueue.main.asyncAfter(deadline: .now() + (duration * 2)) {
            let result = Int(flips) % 2

            if result == 1 {
                self.coin = self.coin.change(coin: self.coin)
            }

            self.resultLabel.text = "\(self.coin)"

            UIView.animate(withDuration: 0.5, animations: {
                self.resultView.alpha = 0.5
            })
            UIView.animate(withDuration: 0.5,
                           delay: 1,
                           options: .curveEaseIn,
                           animations: {
                            self.resultView.alpha = 0
            }, completion: nil)
        }
    }
}

extension ViewController: ARSCNViewDelegate {

    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {

        guard let planeAnchor = anchor as? ARPlaneAnchor else { return }

        let width = CGFloat(planeAnchor.extent.x)
        let height = CGFloat(planeAnchor.extent.z)
        let plane = SCNPlane(width: width, height: height)

        plane.materials.first?.diffuse.contents = UIColor.transparentLightBlue

        let planeNode = SCNNode(geometry: plane)

        let x = CGFloat(planeAnchor.center.x)
        let y = CGFloat(planeAnchor.center.y)
        let z = CGFloat(planeAnchor.center.z)

        planeNode.position = SCNVector3(x, y, z)
        planeNode.eulerAngles.x = -.pi/2

        node.addChildNode(planeNode)
    }

    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor,
            let planeNode = node.childNodes.first,
            let plane = planeNode.geometry as? SCNPlane else { return }

        let width = CGFloat(planeAnchor.extent.x)
        let height = CGFloat(planeAnchor.extent.z)
        plane.width = width
        plane.height = height

        let x = CGFloat(planeAnchor.center.x)
        let y = CGFloat(planeAnchor.center.y)
        let z = CGFloat(planeAnchor.center.z)
        planeNode.position = SCNVector3(x, y, z)
    }
}

extension ViewController: ARSessionObserver {

    func sessionWasInterrupted(_ session: ARSession) {
        showFeedbackBox("Session was interrupted")
    }

    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        var message: String? = nil

        switch camera.trackingState {
        case .notAvailable:
            message = "Tracking not available"
        case .limited(.initializing):
            message = "Initializing AR session"
        case .limited(.excessiveMotion):
            message = "Too much motion"
        case .limited(.insufficientFeatures):
            message = "Not enough surface details"
        case .normal:
            if coinNode == nil {
                message = "Move to find a horizontal surface"
            }
        case .limited(.relocalizing):
            message = "Hit tests not accurates"
        }

        message != nil ? showFeedbackBox(message!) : hideFeedbackBox()
    }
}

extension ViewController {

    func showFeedbackBox(_ text: String) {
        feedbackLabel.text = text

        feedbackBox.isHidden = false

        feedbackBox.layer.masksToBounds = true
        feedbackBox.layer.cornerRadius = 7.5
    }

    func hideFeedbackBox() {
        self.feedbackBox.isHidden = true
    }
}
