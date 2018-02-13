import UIKit
import SwiftyUserDefaults
import FirebaseRemoteConfig

protocol ConfigDelegate: class {
    func configDidLoad()
}

class Config {
    static let shared = Config()
    var remoteConfig: RemoteConfig!
    weak var delegate: ConfigDelegate?
    
    let defaultValues = [
        "kinopubClientId" : Defaults[.kinopubClientId] as NSObject,
        "kinopubClientSecret" : Defaults[.kinopubClientSecret] as NSObject,
        "delayViewMarkTime" : Defaults[.delayViewMarkTime] as NSObject,
        "kinopubDomain" : Defaults[.kinopubDomain] as NSObject
                         ]

    var appVersion: String {
        if let dictionary = Bundle.main.infoDictionary {
            let version = dictionary["CFBundleShortVersionString"] as! String
            let build = dictionary["CFBundleVersion"] as! String
            return "Версия \(version), билд \(build)"
        }
        return ""
    }
    
    var kinopubClientId: String {
        return remoteConfig["kinopubClientId"].stringValue ?? kinopub.clientId
    }
    
    var kinopubClientSecret: String {
        return remoteConfig["kinopubClientSecret"].stringValue ?? kinopub.clientSecret
    }
    
    var delayViewMarkTime: TimeInterval {
        return remoteConfig["delayViewMarkTime"].numberValue as? TimeInterval ?? 180
    }
    
    var kinopubDomain: String {
        return remoteConfig["kinopubDomain"].stringValue ?? kinopub.domain
    }
    
    var clientTitle: String {
        return Defaults[.clientTitle]
    }
    
    var menuItem: Int {
        return Defaults[.menuItem]
    }
    
    var streamType: String {
        return Defaults[.streamType]
    }
    
    var logViews: Bool {
        return Defaults[.logViews]
    }
    
    var canSortSeasons: Bool {
        return Defaults[.canSortSeasons]
    }
    
    var canSortEpisodes: Bool {
        return Defaults[.canSortEpisodes]
    }
    
    var menuVisibleContentWidth: CGFloat {
        return UIDevice.current.userInterfaceIdiom == .pad ? 1.6 : 5
    }
    
    init() {
        remoteConfig = RemoteConfig.remoteConfig()
        remoteConfig.setDefaults(defaultValues)
        fetchRemoteConfig()
    }
    
    func fetchRemoteConfig() {
        #if DEBUG
            // FIXME: Remove before production!
            let remoteConfigSettings = RemoteConfigSettings(developerModeEnabled: true)
            remoteConfig.configSettings = remoteConfigSettings!
        #endif
        
        remoteConfig.fetch(withExpirationDuration: 0) { [unowned self] (status, error) in
            guard error == nil else {
                print("Error fetch remote config: \(error?.localizedDescription ?? "unknown")")
                return
            }
            self.writeInUserDefaults()
            self.remoteConfig.activateFetched()
            self.delegate?.configDidLoad()
        }
    }
    
    func writeInUserDefaults() {
        Defaults[.kinopubClientId] = remoteConfig["kinopubClientId"].stringValue!
        Defaults[.kinopubClientSecret] = remoteConfig["kinopubClientSecret"].stringValue!
        Defaults[.delayViewMarkTime] = remoteConfig["delayViewMarkTime"].numberValue as! TimeInterval
        Defaults[.kinopubDomain] = remoteConfig["kinopubDomain"].stringValue!
    }
    
    struct MenuItems: Codable, Equatable {
        let id: String
        let name: String
        let icon: String
        let tag: Int?
        
        // Content Menu
        static var mainVC: MenuItems {
            return MenuItems(id: "HomeNavVc", name: "Главная", icon: "Main", tag: nil)
        }
        static var filmsVC: MenuItems {
            return MenuItems(id: "ItemNavVC", name: "Фильмы", icon: "Movies", tag: TabBarItemTag.movies.rawValue)
        }
        static var seriesVC: MenuItems {
            return MenuItems(id: "ItemNavVC", name: "Сериалы", icon: "Series", tag: TabBarItemTag.shows.rawValue)
        }
        static var cartoonsVC: MenuItems {
            return MenuItems(id: "ItemNavVC", name: "Мультфильмы", icon: "Cartoons", tag: TabBarItemTag.cartoons.rawValue)
        }
        static var docMoviesVC: MenuItems {
            return MenuItems(id: "ItemNavVC", name: "Документальные фильмы", icon: "Documentary Movie", tag: TabBarItemTag.documovie.rawValue)
        }
        static var docSeriesVC: MenuItems {
            return MenuItems(id: "ItemNavVC", name: "Документальные сериалы", icon: "Documentary Series", tag: TabBarItemTag.docuserial.rawValue)
        }
        static var tvShowsVC: MenuItems {
            return MenuItems(id: "ItemNavVC", name: "ТВ шоу", icon: "Television", tag: TabBarItemTag.tvshow.rawValue)
        }
        static var concertsVC: MenuItems {
            return MenuItems(id: "ItemNavVC", name: "Концерты", icon: "Concert", tag: TabBarItemTag.concert.rawValue)
        }
        static var collectionsVC: MenuItems {
            return MenuItems(id: "CollectionsNavVC", name: "Подборки", icon: "Collection", tag: TabBarItemTag.collections.rawValue)
        }
        static var movies4kVC: MenuItems {
            return MenuItems(id: "ItemNavVC", name: "4K", icon: "4K", tag: TabBarItemTag.movies4k.rawValue)
        }
        static var movies3dVC: MenuItems {
            return MenuItems(id: "ItemNavVC", name: "3D", icon: "3D", tag: TabBarItemTag.movies3d.rawValue)
        }
        static var tvSportVC: MenuItems {
            return MenuItems(id: "SportNavVC", name: "Спортивные каналы", icon: "Sports", tag: nil)
        }
        
        // User Menu
        static var watchlistVC: MenuItems {
            return MenuItems(id: "ItemNavVC", name: "Я смотрю", icon: "Eye", tag: TabBarItemTag.watchlist.rawValue)
        }
        static var bookmarksVC: MenuItems {
            return MenuItems(id: "BokmarksNavVC", name: "Закладки", icon: "Folder", tag: nil)
        }
        static var downloadsVC: MenuItems {
            return MenuItems(id: "DownloadNavVC", name: "Загрузки", icon: "Download", tag: nil)
        }
        
        // Settings Menu
        static var settingsVC: MenuItems {
            return MenuItems(id: "SettingsNavVC", name: "Настройки", icon: "Settings", tag: nil)
        }
        
        static let hiddenMenuItemsDefault = [movies4kVC, movies3dVC]
        static let configurableMenuItems = [filmsVC, seriesVC, cartoonsVC, docMoviesVC, docSeriesVC, tvShowsVC, concertsVC, collectionsVC, movies4kVC, movies3dVC, tvSportVC]
        static let jsonFileForHiddenMenuItems = "configMenu.json"
        
        static let userMenu = [watchlistVC, bookmarksVC, downloadsVC]
        static let contentMenu = [mainVC] + Config.shared.loadConfigMenu()
        static let settingsMenu = [settingsVC]
        static let all = userMenu + contentMenu + settingsMenu
        
        static func ==(lhs: Config.MenuItems, rhs: Config.MenuItems) -> Bool {
            return lhs.name == rhs.name
        }
    }
    
//    let contentMenu = [MenuItems.mainVC] + loadConfigMenu()
//    let allMenu = MenuItems.userMenu + Config.shared.contentMenu + MenuItems.settingsMenu
}

extension Config {
    func saveConfigMenu(_ menu: [MenuItems]) {
        Storage.store(menu, to: .documents, as: Config.MenuItems.jsonFileForHiddenMenuItems)
    }
    
    func loadConfigMenu() -> [MenuItems] {
        checkFileExist(Config.MenuItems.jsonFileForHiddenMenuItems)
        var configMenu = Config.MenuItems.configurableMenuItems
        let json = Storage.retrieve(Config.MenuItems.jsonFileForHiddenMenuItems, from: .documents, as: [MenuItems].self)
        configMenu = configMenu.filter { !json.contains($0) }
        return configMenu
    }
    
    func getHiddenMenuItems() -> [MenuItems] {
        return Storage.retrieve(Config.MenuItems.jsonFileForHiddenMenuItems, from: .documents, as: [MenuItems].self)
    }
    
    func checkFileExist(_ file: String) {
        if !Storage.fileExists(file, in: .documents) {
            saveConfigMenu(Config.MenuItems.hiddenMenuItemsDefault)
        }
    }
}
