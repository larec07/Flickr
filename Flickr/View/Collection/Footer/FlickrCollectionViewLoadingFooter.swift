import UIKit

class FlickrCollectionViewLoadingFooter: UICollectionReusableView {
    @IBOutlet var spinner: UIActivityIndicatorView!
    
    public var isVisible = false {
        didSet {
            if isVisible {
                spinner.startAnimating()
            } else {
                spinner.stopAnimating()
            }
        }
    }
}
