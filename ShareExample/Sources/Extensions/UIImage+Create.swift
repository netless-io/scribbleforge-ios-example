import UIKit

extension UIImage {
    static func createHorizontalLineImage(color: UIColor, size: CGSize, lineWidth: CGFloat = 2.0) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, false, UIScreen.main.scale)
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        
        let yPosition = size.height / 2
        let path = UIBezierPath()
        path.move(to: CGPoint(x: 0, y: yPosition))
        path.addLine(to: CGPoint(x: size.width, y: yPosition))
        
        context.setStrokeColor(color.cgColor)
        context.setLineWidth(lineWidth)
        path.stroke()
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }

    static func createHorizontalDashedLineImage(color: UIColor, size: CGSize, lineWidth: CGFloat = 2.0, dashPattern: [CGFloat]) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, false, UIScreen.main.scale)
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        
        let yPosition = size.height / 2
        let path = UIBezierPath()
        path.move(to: CGPoint(x: 0, y: yPosition))
        path.addLine(to: CGPoint(x: size.width, y: yPosition))
        
        path.setLineDash(dashPattern, count: dashPattern.count, phase: 0)
        
        context.setStrokeColor(color.cgColor)
        context.setLineWidth(lineWidth)
        path.stroke()
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }

    static func createCircleImage(color: UIColor, size: CGSize) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, false, UIScreen.main.scale)
        guard let context = UIGraphicsGetCurrentContext() else { return nil }

        context.setFillColor(color.cgColor)
        context.fillEllipse(in: CGRect(origin: .zero, size: size))
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }

    static func createCircleWithCustomRingImage(color: UIColor, size: CGSize, circleRadius: CGFloat, ringRadius: CGFloat) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, false, UIScreen.main.scale)
        guard let context = UIGraphicsGetCurrentContext() else { return nil }

        let center = CGPoint(x: size.width / 2, y: size.height / 2)

        // Draw outer ring
        context.addArc(center: center, radius: ringRadius, startAngle: 0, endAngle: .pi * 2, clockwise: true)
        context.setStrokeColor(color.cgColor)
        context.setLineWidth(2.0)
        context.strokePath()

        // Draw inner circle
        context.addArc(center: center, radius: circleRadius, startAngle: 0, endAngle: .pi * 2, clockwise: true)
        context.setFillColor(color.cgColor)
        context.fillPath()

        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }

    static func createRectangleImage(color: UIColor, size: CGSize) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, false, UIScreen.main.scale)
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        
        context.setFillColor(color.cgColor)
        context.fill(CGRect(origin: .zero, size: size))
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }

    static func createRectangleWithBorderImage(color: UIColor, size: CGSize, rectSize: CGSize, borderWidth: CGFloat = 2.0) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, false, UIScreen.main.scale)
        guard let context = UIGraphicsGetCurrentContext() else { return nil }

        // Draw filled rectangle
        let fillRect = CGRect(x: (size.width - rectSize.width) / 2, y: (size.height - rectSize.height) / 2, width: rectSize.width, height: rectSize.height)
        context.setFillColor(color.cgColor)
        context.fill(fillRect)
        
        // Draw border on top
        let borderRect = CGRect(x: borderWidth / 2, y: borderWidth / 2, width: size.width - borderWidth, height: size.height - borderWidth)
        context.setStrokeColor(color.cgColor)
        context.setLineWidth(borderWidth)
        context.stroke(borderRect)
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
}

