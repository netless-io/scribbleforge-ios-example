import UIKit

extension UIColor {
    func almostSame(as other: UIColor?) -> Bool {
        guard let other,
              let components1 = cgColor.components,
              let components2 = other.cgColor.components,
              components1.count == components2.count
        else { return false }
        let result = components1.enumerated().reduce(into: 0) { partialResult, r in
            let d = abs(components2[r.offset] - r.element)
            partialResult += d
        }
        return result < 0.1
    }
    
    static var randomColor: UIColor {
        return UIColor(
            red: CGFloat.random(in: 0 ... 1),
            green: CGFloat.random(in: 0 ... 1),
            blue: CGFloat.random(in: 0 ... 1),
            alpha: 1
        )
    }
}
