import UIKit

final class PassthroughView: UIView {
    
    var touchableViews: [UIView] = []

    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        for view in touchableViews {
            let p = convert(point, to: view)
            if view.bounds.contains(p) {
                return true
            }
        }
        return false
    }
}

