//
//  PacmanPageControl.swift
//  PacmanPageControl-Demo
//
//  Created by ooatuoo on 2017/3/25.
//  Copyright © 2017年 ooatuoo. All rights reserved.
//

import UIKit

class PacmanPageControl: UIView {

    public var dotColorStyle: DotColorStyle = .random(hue: .random, luminosity: .light)
    public var pacmanColorStyle: PacmanColorStyle = .changeWithDot
    
    public var pacmanDiameter:  CGFloat = 12
    public var dotDiameter:     CGFloat = 5
    public var dotInterval:     CGFloat = 0
    
    public var lastContentOffsetX: CGFloat = 0

    fileprivate var progress: CGFloat = 0
    fileprivate var pacmanOriginX: CGFloat = 0
    
    fileprivate var dotLayers:  [CAShapeLayer] = []
    fileprivate var pacmanLayer: PacmanLayer!
    
    fileprivate var pageCount: Int!
    fileprivate var dotColors: [UIColor] = []
    
    enum DotColorStyle {
        case same(UIColor)
        case different([UIColor])
        case random(hue: Hue, luminosity: Luminosity)
    }
    
    enum PacmanColorStyle {
        case fixed(UIColor)
        case changeWithDot
    }
    
    init(frame: CGRect, pageCount: Int) {
        super.init(frame: frame)
        
        self.pageCount = pageCount
    }
    
    override func didMoveToSuperview() {
        super.didMoveToSuperview()

        if dotInterval == 0 {
            dotInterval = dotDiameter * 1.2
        }
        
        switch dotColorStyle {
            
        case .same(let color):
            dotColors = Array(repeating: color, count: pageCount)
            
        case .different(let colors):
            
            for _ in 0 ..< (pageCount / colors.count) {
                dotColors.append(contentsOf: colors)
            }
            
            dotColors.append(contentsOf: colors.prefix(pageCount % colors.count))
            
        case .random(let hue, let luminosity):
            
            dotColors = randomColors(count: pageCount, hue: hue, luminosity: luminosity)
        }
        
        setSubLayers()
    }
    
    fileprivate func setSubLayers() {
        
        let dotTotalWidth = dotDiameter * CGFloat(pageCount) + dotInterval * CGFloat(pageCount - 1)
        let dotOriginY = (frame.height - dotDiameter) / 2
        let dotOriginX = (frame.width - dotTotalWidth) / 2
        pacmanOriginX = dotOriginX + dotDiameter / 2 - pacmanDiameter / 2

        var dotFrame = CGRect(x: dotOriginX, y: dotOriginY, width: dotDiameter, height: dotDiameter)
        
        dotLayers = (0..<pageCount).map { index in
            let layer = CAShapeLayer()
            layer.frame = dotFrame
            layer.fillColor = dotColors[index].cgColor
            dotFrame.origin.x += dotDiameter + dotInterval
            
            update(dotLayer: layer, at: index)
            self.layer.addSublayer(layer)
            return layer
        }
        
        pacmanLayer = PacmanLayer()
        pacmanLayer.frame = CGRect(x: pacmanOriginX, y: (frame.height - pacmanDiameter) / 2, width: pacmanDiameter, height: pacmanDiameter)
        pacmanLayer.contentsScale = UIScreen.main.scale
        
        if case let .fixed(color) = pacmanColorStyle {
            pacmanLayer.color = color
        } else {
            pacmanLayer.color = dotColors[0]
        }
        
        layer.addSublayer(pacmanLayer)
        pacmanLayer.setNeedsDisplay()
    }
    
    fileprivate func update(dotLayer: CAShapeLayer, at index: Int) {
        
        guard progress >= 0 && progress <= CGFloat(pageCount - 1) else { return }
        
        let originRect = CGRect(x: 0, y: 0, width: dotDiameter, height: dotDiameter)
        
        let offset = abs(progress - CGFloat(index))
        let x = offset > 1 ? 1 : offset
        let insetDis = dotDiameter / 2 * (x * x - 2 * x + 1)
        
        let scaleRect = originRect.insetBy(dx: insetDis, dy: insetDis)
        dotLayer.path = UIBezierPath(ovalIn: scaleRect).cgPath
    }
    
    public func scroll(with scrollView: UIScrollView) {
        
        let total = scrollView.contentSize.width - scrollView.bounds.width
        let offset = scrollView.contentOffset.x
        
        progress = offset / total * CGFloat(pageCount - 1)
        
        if lastContentOffsetX < scrollView.contentOffset.x {
            pacmanLayer.direction = .right
        } else if lastContentOffsetX > scrollView.contentOffset.x {
            pacmanLayer.direction = .left
        }
        
        let factor = min(1, max(0, abs(scrollView.contentOffset.x - lastContentOffsetX) / scrollView.frame.size.width))
        
        if case .changeWithDot = pacmanColorStyle, factor == 1 {
            pacmanLayer.color = dotColors[Int(progress)]
        }
        
        pacmanLayer.position.x = pacmanOriginX + pacmanDiameter / 2 + progress * (dotDiameter + dotInterval)
        pacmanLayer.factor = factor
        
        for (index, layer) in dotLayers.enumerated() {
            update(dotLayer: layer, at: index)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

