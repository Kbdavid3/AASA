//
//  UIImage+Gradient.swift
//  kiccbacc
//
//  Created by ANKIT YADAV on 08/04/21.
//  Copyright © 2021 APPLE. All rights reserved.
//

import UIKit
import Foundation

func imageWithGradientBottom(img:UIImage!) -> UIImage {

    UIGraphicsBeginImageContext(img.size)
    let context = UIGraphicsGetCurrentContext()

    img.draw(at: CGPoint(x: 0, y: 0))

    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let locations:[CGFloat] = [0.0, 1.0]

    let bottom = UIColor(red: 0, green: 0, blue: 0, alpha: 0.5).cgColor
    let top = UIColor(red: 0, green: 0, blue: 0, alpha: 0).cgColor

    let colors = [top, bottom] as CFArray

    let gradient = CGGradient(colorsSpace: colorSpace, colors: colors, locations: locations)

    let startPoint = CGPoint(x: img.size.width/2, y: 0)
    let endPoint = CGPoint(x: img.size.width/2, y: img.size.height)

    context!.drawLinearGradient(gradient!, start: startPoint, end: endPoint, options: CGGradientDrawingOptions(rawValue: UInt32(0)))

    let image = UIGraphicsGetImageFromCurrentImageContext()

    UIGraphicsEndImageContext()

    return image!
}

func imageWithExtraGradientBottom(img:UIImage!) -> UIImage {

    UIGraphicsBeginImageContext(img.size)
    let context = UIGraphicsGetCurrentContext()

    img.draw(at: CGPoint(x: 0, y: 0))

    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let locations:[CGFloat] = [0.0, 1.0]

    let bottom = UIColor(red: 0, green: 0, blue: 0, alpha: 1).cgColor
    let top = UIColor(red: 0, green: 0, blue: 0, alpha: 0).cgColor

    let colors = [top, bottom] as CFArray

    let gradient = CGGradient(colorsSpace: colorSpace, colors: colors, locations: locations)

    let startPoint = CGPoint(x: img.size.width/2, y: 0)
    let endPoint = CGPoint(x: img.size.width/2, y: img.size.height)

    context!.drawLinearGradient(gradient!, start: startPoint, end: endPoint, options: CGGradientDrawingOptions(rawValue: UInt32(0)))

    let image = UIGraphicsGetImageFromCurrentImageContext()

    UIGraphicsEndImageContext()

    return image!
}


func imageWithGradientTop(img:UIImage!) -> UIImage {

    UIGraphicsBeginImageContext(img.size)
    let context = UIGraphicsGetCurrentContext()

    img.draw(at: CGPoint(x: 0, y: 0))

    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let locations:[CGFloat] = [1.0, 0.0]

    let bottom = UIColor(red: 0, green: 0, blue: 0, alpha: 1).cgColor
    let top = UIColor(red: 0, green: 0, blue: 0, alpha: 0).cgColor

    let colors = [top, bottom] as CFArray

    let gradient = CGGradient(colorsSpace: colorSpace, colors: colors, locations: locations)

    let startPoint = CGPoint(x: img.size.width/2, y: 0)
    let endPoint = CGPoint(x: img.size.width/2, y: img.size.height)

    context!.drawLinearGradient(gradient!, start: startPoint, end: endPoint, options: CGGradientDrawingOptions(rawValue: UInt32(0)))

    let image = UIGraphicsGetImageFromCurrentImageContext()

    UIGraphicsEndImageContext()

    return image!
}
