import UIKit

/// Define `presenter` protocol
protocol FlickrPresenterProtocol {
    // Common
    func start()
    
    // Provide data for UICollectionView
    func numberOfItems() -> Int
    func item(at index: Int) -> FlickrPhoto
    func image(for item: FlickrPhoto, completion: @escaping (UIImage) -> Void)
    
    // Process user interactions
    func notifyUserReachedBottomOfContent()
    func notifyRefreshContentRequested()
    
    // Content state
    func areRecentPhotosOver() -> Bool
}
