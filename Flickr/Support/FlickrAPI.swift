import Alamofire

public class FlickrAPI {

    /// Simplify composing of correct URL path
    fileprivate class FlickrURLConfigurator {
        /// Return value from Info.plist by key 'FlickrAPIKey'.
        /// Example URL: https://api.flickr.com/services/rest/?method=flickr.photos.getRecent&api_key=2d5314a9a71a078d6d2ae78f4185c4af&per_page=10&page=2&format=json&nojsoncallback=1
        ///
        /// - Note: If the value is not found or it's type other than 'String'  the app will crash to prevent useless work
        private static var apiKey: String {
            return Bundle.main.object(forInfoDictionaryKey: "FlickrAPIKey") as! String
        }
        
        // MARK: - Static Query Components
        /// The main part of remote server path
        private static var baseURLComponent: String {
            return "https://api.flickr.com/services/rest/"
        }
        
        /// Provides parameter 'method' for query
        private static var getRecentPhotosMethodURLComponent: URLQueryItem {
            return URLQueryItem(name: "method", value: "flickr.photos.getRecent")
        }
        
        /// Provides parameter 'api_key' for query
        private static var apiKeyURLComponent: URLQueryItem {
            return URLQueryItem(name: "api_key", value: apiKey)
        }
        
        /// Provides parameter 'format' for query
        private static var formatURLComponent: URLQueryItem {
            return URLQueryItem(name: "format", value: "json")
        }
        
        /// Provides parameter 'nojsoncallback' for query
        private static var noJsonCallbackURLComponent: URLQueryItem {
            return URLQueryItem(name: "nojsoncallback", value: "1")
        }
        
        // MARK: - Public Interface
        /// Compose URLComponents by separated elements
        ///
        /// - Parameters:
        ///         - page: number of page like content offset
        ///         - count: number of items per page
        ///
        static func configureURLComponents(_ page: UInt, count: UInt) -> URLComponents? {
            var components = URLComponents(string: baseURLComponent)
            components?.queryItems = [getRecentPhotosMethodURLComponent,
                                      apiKeyURLComponent,
                                      formatURLComponent,
                                      noJsonCallbackURLComponent,
                                      URLQueryItem(name: "page", value: String(page)),
                                      URLQueryItem(name: "per_page", value: String(count))]
            
            return components
        }
        
        /// Compose URL for fetching specific image
        ///
        /// - parameter size: size of image: `s` - small, `m` - medium, `l` - large. Medium by default.
        ///
        static func imageURL(for item: FlickrPhoto, size: String = "m") -> URL? {
            let str = "https://farm\(item.farm).staticflickr.com/\(item.server)/\(item.id)_\(item.secret)_\(size).png"
            return URL(string: str)
        }
    }
}

// MARK: - Public Interface
extension FlickrAPI {
    
    typealias ImageCompletionHandler = (UIImage?) -> Void
    
    /// Request list of recent photos
    ///
    /// - parameter successHandler: closure that calls when each condition was satisfied
    /// - parameter failureHandler: closure that calls when one of conditions faild. The parameter of closure should be
    ///     `Error` type but for sake of simplicity it is `String` type
    ///
    static func fetchPhotos(from page: UInt,
                            by perPage: UInt,
                            successHandler: @escaping (FlickrResponse) -> Void,
                            failureHandler: @escaping (String) -> Void) {
        guard let urlComponents = FlickrURLConfigurator.configureURLComponents(page, count: perPage)
        else { return }

        request(urlComponents).validate().responseJSON(queue: DispatchQueue.global(qos: .userInitiated)) { response in
            guard let data = response.data else {
                failureHandler("Unable to retrieve data from remote response")
                return
            }
            
            let deserializedResponse: FlickrResponse
            
            do {
                deserializedResponse = try JSONDecoder().decode(FlickrResponse.self, from:data)
                successHandler(deserializedResponse)
            } catch {
                failureHandler("Unable to decode data")
            }
        }
    }
    
    static func imageURLRequest(for item: FlickrPhoto, size: String = "m") -> URLRequest? {
        guard let urlString = FlickrURLConfigurator.imageURL(for: item) else { return nil}
        return URLRequest(url: urlString)
    }
    
    static func fetchImage(_ url: URLRequest, completion: @escaping ImageCompletionHandler) {
        request(url).responseImage { response in
            completion(response.result.value)
        }
    }
}
