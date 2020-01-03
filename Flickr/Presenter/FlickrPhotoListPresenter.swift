import AlamofireImage

class FlickrPresenter {
    
    /// Support stucture. Stores content navigation info. Update data each successfull request.
    ///
    /// `page` - current page
    /// `pages` - number of pages of the specified size
    /// `perPage`- number of items on 1 page
    /// `total` - total number of items
    ///
    struct FlickrRemoteContentnavigation {
        let page: UInt
        let pages: UInt
        let perPage: UInt
        let total: UInt
        
        init(page: UInt = 0,
             pages: UInt = 0,
             perPage: UInt = 0,
             total: UInt = 0) {
            self.page = page
            self.pages = pages
            self.perPage = perPage
            self.total = total
        }
        
        init(contentNavigationInfo: FlickrPhotos) {
            self.init(page: contentNavigationInfo.page,
                      pages: contentNavigationInfo.pages,
                      perPage: contentNavigationInfo.perpage,
                      total: contentNavigationInfo.total)
        }
    }
    
    // Define how new data must be merged with old
    enum MergeDataMethod {
        case add, update
    }
    
    private var photos = [FlickrPhoto]()
    
    private var contentNavigationInfo = FlickrRemoteContentnavigation()
    
    private weak var view: FlickrViewProtocol?
    
    private let defaultPhotosRequestPortion: UInt = 40
    
    private let imageCache = AutoPurgingImageCache()
    
    init(view: FlickrViewProtocol) {
        self.view = view
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(applicationWillTerminate(notification:)),
                                               name: UIApplication.willTerminateNotification,
                                               object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self,
                                                  name: UIApplication.willTerminateNotification,
                                                  object: nil)
    }
}

// Public Interface
extension FlickrPresenter: FlickrPresenterProtocol {
    static private let kUserDefaultsPhotosKey = "kPhotosKey"
    // MARK: - Common
    func start() {
        // Retrieve data from UserDefaults
        // Unarchive it
        // Check for is it Array<Dictionary<String, Any>>
        if let previousSessionData = UserDefaults.standard.data(forKey: Self.kUserDefaultsPhotosKey),
            let decoded = NSKeyedUnarchiver.unarchiveObject(with: previousSessionData),
            let previousSessionPhotos = decoded as? [[String: Any]] {
            // Array count not so large so pass through 2 times
            let parsedOldPhotos = previousSessionPhotos.map{FlickrPhoto(from: $0)}.compactMap{$0}
            
                if parsedOldPhotos.count > 0{
                    photos = parsedOldPhotos
                    view?.updateContent()
                    UserDefaults.standard.removeObject(forKey: Self.kUserDefaultsPhotosKey)
                    return
            }
        }
        
        fetchPhotos(from: 1,
                    by: defaultPhotosRequestPortion,
                    successHandler: { response in
                        self.processRecentPhotosResponse(response, mergeMethod: .update)
                    },
                    failureHandler: { errorDescription in
                        self.showMessage(body: errorDescription)
            }
        )
    }
    
    // MARK: - UICollectionView data providing
    func numberOfItems() -> Int {
        return photos.count
    }
    
    func item(at index: Int) -> FlickrPhoto {
        return photos[index]
    }
    
    func image(for item: FlickrPhoto, completion: @escaping (UIImage) -> Void) {
        // Just wrap completion calling in main thread
        func callCompletionMainThread(image: UIImage) {
            DispatchQueue.main.async {
                completion(image)
            }
        }
        
        guard let request = FlickrAPI.imageURLRequest(for: item) else { return }
        
        // If image exists in cache - get it from cache, else let fetch it from network
        if let cachedImage = imageCache.image(for: request, withIdentifier: String(item.id)) {
            callCompletionMainThread(image: cachedImage)
        } else {
            FlickrAPI.fetchImage(request, completion: { image in
                if let image = image {
                    callCompletionMainThread(image: image)
                    self.imageCache.add(image, for: request, withIdentifier: String(item.id))
                }
            })
        }
    }
    
    // MARK: - User interactions
    func notifyUserReachedBottomOfContent() {
        // 1 - Reject first the content hasn't been filled yet
        // 2 - Do nothing in case all photos was fetched already
        guard contentNavigationInfo.page > 0,
            photos.count > 0,
            !areRecentPhotosOver()
            else { return }
        
        let page = contentNavigationInfo.page + 1
        fetchPhotos(from: page,
                    by: defaultPhotosRequestPortion,
                    successHandler: { response in
                        self.processRecentPhotosResponse(response, mergeMethod: .add)
                    },
                    failureHandler: { errorDescription in
                        self.showMessage(body: errorDescription)
                    })
    }
    
    func notifyRefreshContentRequested() {
        fetchPhotos(from: 1,
                    by: defaultPhotosRequestPortion,
                    successHandler: { response in
                        self.processRecentPhotosResponse(response, mergeMethod: .update)
                    },
                    failureHandler: { errorDescription in
                        self.showMessage(body: errorDescription)
        })
    }
    
    func areRecentPhotosOver() -> Bool {
        return photos.count >= contentNavigationInfo.total
    }
}

// Private Interface
// MARK: - Fetch data
extension FlickrPresenter {
    private func fetchPhotos(from page: UInt,
                             by count: UInt,
                             successHandler: @escaping (FlickrResponse) -> Void,
                             failureHandler: @escaping (String) -> Void) {
        
        FlickrAPI.fetchPhotos(from: page,
                              by: count,
                              successHandler: successHandler,
                              failureHandler: failureHandler)
    }
    
    private func fetchImage(for item: FlickrPhoto, completion: @escaping (UIImage) -> Void) {
        
    }
}

// MARK: - Process response data
extension FlickrPresenter {
    private func processRecentPhotosResponse(_ response: FlickrResponse, mergeMethod: MergeDataMethod) {
        contentNavigationInfo = FlickrRemoteContentnavigation(contentNavigationInfo: response.photos)
        
        let newPhotos = response.photos.photo
        
        guard newPhotos.count > 0 else { return }
        
        switch mergeMethod {
        
        // Append new data
        case .add:
            let photosCount = photos.count
            
            photos += newPhotos
            
            let indexPaths = (photosCount..<photos.count).map{ index in
                IndexPath(item: index, section: 0)
            }
            
            DispatchQueue.main.async {
                self.view?.insertItems(at: indexPaths)
            }
            
        // Purge cache and clear photos data
        case .update:
            removeAllData()
            photos = newPhotos
            DispatchQueue.main.async {
                self.view?.updateContent()
            }
        }
    }
    
    private func showMessage(body: String) {
        DispatchQueue.main.async {
            self.view?.showMessage(title: "Warning", body: body)
        }
    }
}

// MARK: - Managing image cache
extension FlickrPresenter {
    private func removeAllData() {
        // Each time remove first element
        (0..<photos.count).forEach{_ in remove(at: 0)}
    }
    
    @discardableResult private func remove(at index: Int) -> FlickrPhoto {
        assert(index < photos.count, "Out of bounds")
        
        let item = photos[index]
        
        // Remove image from cache first then remove according photo data from `photos`
        if let request = FlickrAPI.imageURLRequest(for: item) {
            DispatchQueue.global(qos: .utility).async {
                self.imageCache.removeImage(for: request, withIdentifier: String(item.id))
            }
        }
        
        return photos.remove(at: index)
    }
    
    private func finishSession() {
        let photosCount = photos.count
        
        guard photosCount > 0 else { return }
        
        // For example defaultPhotosRequestPortion = 40.
        // Remove object at index 40 element (photos.count - 40) times. Array shift elements after remove,
        // so all elements after 39 index will be removed
        let boundingElement = Int(defaultPhotosRequestPortion)
        (boundingElement..<photosCount).forEach {_ in remove(at: boundingElement)}
        
        let encodedPhotos = NSKeyedArchiver.archivedData(withRootObject: photos.map{$0.dictionary})
        
        UserDefaults.standard.set(encodedPhotos, forKey: Self.kUserDefaultsPhotosKey)
    }
}

// MARK: - Notifications
extension FlickrPresenter {
    @objc func applicationWillTerminate(notification: NSNotification) {
        finishSession()
    }
}
