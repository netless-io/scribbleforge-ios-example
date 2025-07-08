import ScribbleForge
import UIKit

extension WhiteboardToolType {
    var containStrokeColor: Bool {
        switch self {
        case .curve, .arrow, .ellipse, .line, .rectangle, .text, .triangle: true
        default: false
        }
    }

    var containStrokeWidth: Bool {
        switch self {
        case .curve, .arrow, .ellipse, .line, .rectangle, .triangle: true
        default: false
        }
    }
    
    var containFillColor: Bool {
        switch self {
        case .ellipse, .triangle, .rectangle: true
        default: false
        }
    }
    
    var containTextSize: Bool {
        self == .text
    }

    var containClean: Bool {
        self == .eraser
    }

    var containsSubMenu: Bool {
        containStrokeColor || containTextSize || containStrokeWidth || containClean
    }

    var isShape: Bool {
        switch self {
        case .rectangle: true
        case .ellipse: true
        case .triangle: true
        case .arrow: true
        case .line: true
        default: false
        }
    }

    var isFillable: Bool {
        switch self {
        case .ellipse: true
        case .rectangle: true
        case .triangle: true
        default: false
        }
    }

    var image: UIImage? {
        let config = UIImage.SymbolConfiguration(pointSize: 18, weight: .semibold)
        let image = UIImage(systemName: systemImage, withConfiguration: config)
        return image
    }
    
    var systemImage: String {
        let image: String
        switch self {
        case .selector:
            image = "lasso"
        case .curve:
            image = "scribble.variable"
        case .text:
            image = "textformat.alt"
        case .eraser:
            image = "eraser.fill"
        case .ellipse:
            return "circle"
        // image = containFillColor ? "circle.fill" : "circle"
        case .laser:
            image = "dot.circle.and.hand.point.up.left.fill"
        case .rectangle:
            return "rectangle"
        //  image = containFillColor ? "rectangle.fill" : "rectangle"
        case .line:
            image = "line.diagonal"
        case .triangle:
            return "triangle"
//                image = containFillColor ? "triangle.fill" : "triangle"
        case .arrow:
            image = "arrow.backward"
        case .grab:
            image = "hand.draw.fill"
        case .pointer:
            image = "cursorarrow.rays"
        }
        return image
    }
}
