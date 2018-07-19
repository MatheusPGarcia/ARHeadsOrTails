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

    var coinNode: SCNNode?
    var startPosition: SCNVector3?

    override func viewDidLoad() {
        super.viewDidLoad()

        configureLighting()
        addTapGestureToSceneView()

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

        arSceneView.session.run(configuration)

        arSceneView.delegate = self
        arSceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints]
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

        guard let coinScene = SCNScene(named: "ship.scn"),
            let coinNode = coinScene.rootNode.childNode(withName: "ship", recursively: false)
            else { return }

        coinNode.position = position

        self.coinNode = coinNode
        arSceneView.scene.rootNode.addChildNode(coinNode)
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

        print("you are in swipe area")
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
