import UIKit

protocol FlickrViewProtocol: AnyObject {
    func showMessage(title: String, body: String?)
    
    // UICollectionView content
    func updateContent()
    func insertItems(at indexPaths:[IndexPath])
}

// Decorate UIViewController behaviour
extension FlickrViewProtocol where Self: UIViewController {
    func showMessage(title: String, body: String?) {
        let alert = UIAlertController(title: title,
                                      message: body,
                                      preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Cancel",
                                      style: .cancel,
                                      handler: { action in
                                        self.dismiss(animated: true, completion: nil)
        }))
        
        present(alert, animated: true, completion: nil)
    }
}
