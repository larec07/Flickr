import UIKit

class FlickrPhotoListViewController: UIViewController {

    var presenter: FlickrPresenterProtocol!
    
    @IBOutlet var collectionView: UICollectionView!
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        initialize()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        initialize()
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupRefreshControl()

        presenter.start()
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        collectionView.collectionViewLayout.invalidateLayout()
        
        // Scroll to upper visible item after transition will complete
        if let topVisibleItemIndexPath = collectionView.indexPathsForVisibleItems.min() {
            coordinator.animate(alongsideTransition: { [weak collectionView] context in
            collectionView?.scrollToItem(at: topVisibleItemIndexPath,
                                         at: .top,
                                         animated: true)},
                                completion: nil)
        }
    }
}

// MARK: - UICollectionViewDataSource
extension FlickrPhotoListViewController: UICollectionViewDataSource {
    
    static let CellId = "FlickrPhotoCellId"
    static let FooterId = "FooterId"
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return presenter.numberOfItems()
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: Self.CellId,
                                                      for: indexPath) as! FlickrCollectionViewCell
        let data = presenter.item(at: indexPath.item)
        cell.titleLabel.text = data.title
        
        presenter.image(for: data) { image in
            cell.imageView.image = image
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let supView = collectionView.dequeueReusableSupplementaryView(ofKind: kind,
                                                                     withReuseIdentifier: Self.FooterId,
                                                                     for: indexPath)
        return supView
    }
}

// MARK: - UICollectionViewDelegate
extension FlickrPhotoListViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, willDisplaySupplementaryView view: UICollectionReusableView, forElementKind elementKind: String, at indexPath: IndexPath) {
       
        if elementKind == UICollectionView.elementKindSectionFooter,
            let footer = view as? FlickrCollectionViewLoadingFooter {
                presenter.notifyUserReachedBottomOfContent()
                footer.isVisible = true
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didEndDisplayingSupplementaryView view: UICollectionReusableView, forElementOfKind elementKind: String, at indexPath: IndexPath) {
        
        if elementKind == UICollectionView.elementKindSectionFooter,
            let footer = view as? FlickrCollectionViewLoadingFooter {
                footer.isVisible = false
        }
    }
}

// MARK: - UICollectionViewDelegateFlowLayout
extension FlickrPhotoListViewController: UICollectionViewDelegateFlowLayout {
    var interItemSpacing: CGFloat {
        return 4.0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        // 3 photo on width
        
        let width = collectionView.bounds.width/3 - 2 * interItemSpacing
        
        // 4:3 ratio
        let height = width * 3 / 4
        
        return CGSize(width: width, height: height)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return interItemSpacing
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 4.0, left: 0.0, bottom: 4.0, right: 0.0)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        return presenter.areRecentPhotosOver() ?
                CGSize.zero :
                CGSize(width: collectionView.bounds.width, height: 50.0)
    }
}

// MARK: - FlickrViewProtocol
extension FlickrPhotoListViewController: FlickrViewProtocol {
    func updateContent() {
        DispatchQueue.main.async {
            self.collectionView.reloadSections(IndexSet(arrayLiteral: 0))
            
            // There is only one case when refresh control in refreshing state - user pulled collection view.
            // So in that scenario here explicitly time to ends refreshing
            self.collectionView.refreshControl?.endRefreshing()
        }
    }
    
    func insertItems(at indexPaths:[IndexPath]) {
        DispatchQueue.main.async {
            self.collectionView.insertItems(at: indexPaths)
        }
    }
}

// MARK: - Private interface
extension FlickrPhotoListViewController {
    
    private func initialize() {
        presenter = FlickrPresenter(view: self)
    }
    
    private func setupRefreshControl() {
        collectionView.refreshControl = UIRefreshControl()
        collectionView.refreshControl?.addTarget(self,
                                                 action: #selector(refreshControlValueDidChange),
                                                 for: UIControl.Event.valueChanged)
    }
    
    @objc private func refreshControlValueDidChange(control: UIControl) {
        presenter.notifyRefreshContentRequested()
    }
}
