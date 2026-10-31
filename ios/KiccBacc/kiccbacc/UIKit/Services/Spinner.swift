//
//  Spinner.swift
//  kiccbacc
//
//  Created by Ankit Yadav on 29/06/21.
//  Copyright © 2021 APPLE. All rights reserved.
//

import UIKit

@IBDesignable
class SpinnerView : UIView {

    override var layer: CAShapeLayer {
        get {
            return super.layer as! CAShapeLayer
        }
    }

    override class var layerClass: AnyClass {
        return CAShapeLayer.self
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        layer.fillColor = nil
        layer.strokeColor = UIColor.gray.cgColor
        layer.lineWidth = 3
        setPath()
    }

    override func didMoveToWindow() {
        animate()
    }

    private func setPath() {
        layer.path = UIBezierPath(ovalIn: bounds.insetBy(dx: layer.lineWidth / 2, dy: layer.lineWidth / 2)).cgPath
    }

    struct Pose {
        let secondsSincePriorPose: CFTimeInterval
        let start: CGFloat
        let length: CGFloat
        init(_ secondsSincePriorPose: CFTimeInterval, _ start: CGFloat, _ length: CGFloat) {
            self.secondsSincePriorPose = secondsSincePriorPose
            self.start = start
            self.length = length
        }
    }

    class var poses: [Pose] {
        get {
            return [
                Pose(0.0, 0.000, 0.7),
                Pose(0.6, 0.500, 0.5),
                Pose(0.6, 1.000, 0.3),
                Pose(0.6, 1.500, 0.1),
                Pose(0.2, 1.875, 0.1),
                Pose(0.2, 2.250, 0.3),
                Pose(0.2, 2.625, 0.5),
                Pose(0.2, 3.000, 0.7),
            ]
        }
    }

    func animate() {
        var time: CFTimeInterval = 0
        var times = [CFTimeInterval]()
        var start: CGFloat = 0
        var rotations = [CGFloat]()
        var strokeEnds = [CGFloat]()

        let poses = type(of: self).poses
        let totalSeconds = poses.reduce(0) { $0 + $1.secondsSincePriorPose }

        for pose in poses {
            time += pose.secondsSincePriorPose
            times.append(time / totalSeconds)
            start = pose.start
            rotations.append(start * 2 * .pi)
            strokeEnds.append(pose.length)
        }

        times.append(times.last!)
        rotations.append(rotations[0])
        strokeEnds.append(strokeEnds[0])

        animateKeyPath(keyPath: "strokeEnd", duration: totalSeconds, times: times, values: strokeEnds)
        animateKeyPath(keyPath: "transform.rotation", duration: totalSeconds, times: times, values: rotations)

        animateStrokeHueWithDuration(duration: totalSeconds * 5)
    }

    func animateKeyPath(keyPath: String, duration: CFTimeInterval, times: [CFTimeInterval], values: [CGFloat]) {
        let animation = CAKeyframeAnimation(keyPath: keyPath)
        animation.keyTimes = times as [NSNumber]?
        animation.values = values
        animation.calculationMode = .linear
        animation.duration = duration
        animation.repeatCount = Float.infinity
        layer.add(animation, forKey: animation.keyPath)
    }

    func animateStrokeHueWithDuration(duration: CFTimeInterval) {
        let count = 36
        let animation = CAKeyframeAnimation(keyPath: "strokeColor")
        animation.keyTimes = (0 ... count).map { NSNumber(value: CFTimeInterval($0) / CFTimeInterval(count)) }
        animation.values = (0 ... count).map {
            UIColor(hue: CGFloat($0) / CGFloat(count), saturation: 1, brightness: 1, alpha: 1).cgColor
        }
        animation.duration = duration
        animation.calculationMode = .linear
        animation.repeatCount = Float.infinity
        layer.add(animation, forKey: animation.keyPath)
    }
}

class Spinner {
    static let shared = Spinner()
    
    func startSpinner(message: String, containerView: UIView, spinner: SpinnerView, spinnerLabel: UILabel, view: UIView) {
        containerView.alpha = 1
        UIView.transition(with: containerView, duration: 0.4,
                          options: .curveEaseInOut,
                          animations: {
                            containerView.alpha = 0
                            spinner.alpha = 1
                            spinnerLabel.alpha = 1
                      })
        DispatchQueue.main.asyncAfter(deadline: .now()+0.2, execute: {
            spinnerLabel.attributedText = NSMutableAttributedString()
                .medium(message, 14)
            spinnerLabel.frame = CGRect(x: view.frame.size.width  / 2, y: view.frame.size.height / 2, width: 150, height: 40)
            spinnerLabel.center.x = view.center.x
            spinnerLabel.center.y = view.center.y + 20
            spinnerLabel.textAlignment = .center
            
            spinner.frame = CGRect(x: view.frame.size.width  / 2, y: view.frame.size.height / 2, width: 30, height: 30)
            spinner.center = CGPoint(x: view.frame.size.width  / 2, y: (view.frame.size.height / 2)-20)
            view.addSubview(spinnerLabel)
            view.addSubview(spinner)
            spinner.animate()
        })
    }
    
    func stopSpinner(containerView: UIView, spinner: SpinnerView, spinnerLabel: UILabel) {
        containerView.alpha = 0
        UIView.transition(with: containerView, duration: 0.4,
                          options: .curveEaseInOut,
                          animations: {
                        containerView.alpha = 1
                        spinner.alpha = 0
                        spinnerLabel.alpha = 0
                      })
//            spinner.removeFromSuperview()
//        spinnerLabel.removeFromSuperview()
    }
    
    // hide properties
    func hideAView(viewToHide: UIView) {
        viewToHide.alpha = 1
        UIView.transition(with: viewToHide, duration: 0.4,
                          options: .curveEaseInOut,
                          animations: {
            viewToHide.alpha = 0
                      })
    }
    
    func hideALabel(labelToHide: UILabel) {
        labelToHide.alpha = 1
        UIView.transition(with: labelToHide, duration: 0.4,
                          options: .curveEaseInOut,
                          animations: {
            labelToHide.alpha = 0
                      })
    }
    
    func hideAImageView(imageViewToHide: UIImageView) {
        imageViewToHide.alpha = 1
        UIView.transition(with: imageViewToHide, duration: 0.4,
                          options: .curveEaseInOut,
                          animations: {
            imageViewToHide.alpha = 0
                      })
    }
    
    func hideAButton(buttonToHide: UIButton) {
        buttonToHide.alpha = 1
        UIView.transition(with: buttonToHide, duration: 0.4,
                          options: .curveEaseInOut,
                          animations: {
            buttonToHide.alpha = 0
                      })
    }
    
    // unhide properties
    func unHideAView(viewToUnHide: UIView) {
        viewToUnHide.alpha = 0
        UIView.transition(with: viewToUnHide, duration: 0.4,
                          options: .curveEaseInOut,
                          animations: {
            viewToUnHide.alpha = 1
                      })
    }
    
    func unHideALabel(labelToUnHide: UILabel) {
        labelToUnHide.alpha = 0
        UIView.transition(with: labelToUnHide, duration: 0.4,
                          options: .curveEaseInOut,
                          animations: {
            labelToUnHide.alpha = 1
                      })
    }
    
    func unHideAImageView(imageViewToUnHide: UIImageView) {
        imageViewToUnHide.alpha = 0
        UIView.transition(with: imageViewToUnHide, duration: 0.4,
                          options: .curveEaseInOut,
                          animations: {
            imageViewToUnHide.alpha = 1
                      })
    }
    
    func unHideAButton(buttonToUnHide: UIButton) {
        buttonToUnHide.alpha = 0
        UIView.transition(with: buttonToUnHide, duration: 0.4,
                          options: .curveEaseInOut,
                          animations: {
            buttonToUnHide.alpha = 1
                      })
    }
}
