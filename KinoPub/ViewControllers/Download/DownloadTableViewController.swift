//
//  DownloadTableViewController.swift
//  KinoPub
//
//  Created by Евгений Дац on 06.08.17.
//  Copyright © 2017 Evgeny Dats. All rights reserved.
//

import UIKit
import NTDownload
import LKAlertController
import AVFoundation
import InteractiveSideMenu
import NotificationBannerSwift

class DownloadTableViewController: UITableViewController, SideMenuItemContent {
    fileprivate let mediaManager = Container.Manager.media
    
//    var progress: Float = 0.0
    let control = UIRefreshControl()
    var selectedIndexPath : IndexPath!
    
    var downed = [NTDownloadTask]()
    var downing = [NTDownloadTask]()
    
    @IBOutlet weak var moreButton: UIBarButtonItem!

    override func viewDidLoad() {
        super.viewDidLoad()

        config()
        initdata()
        
//        NTDownloadManager.shared.resumeAllTask()
        
        // Pull to refresh
        control.addTarget(self, action: #selector(initdata), for: UIControl.Event.valueChanged)
        control.tintColor = UIColor.kpOffWhite
        if #available(iOS 10.0, *) {
            tableView?.refreshControl = control
        } else {
            tableView?.addSubview(control)
        }
    }

    
    func config() {
        title = "Загрузки"
        tableView.backgroundColor = UIColor.kpBackground
        
        NTDownloadManager.shared.delegate = self
        tableView.register(UINib(nibName: String(describing: DownloadingTableViewCell.self), bundle: Bundle.main), forCellReuseIdentifier: String(describing: DownloadingTableViewCell.self))
        tableView.register(UINib(nibName: String(describing: DowloadedTableViewCell.self), bundle: Bundle.main), forCellReuseIdentifier: String(describing: DowloadedTableViewCell.self))
        tableView.tableFooterView = UIView(frame: CGRect.zero)
        tableView.estimatedRowHeight = 100
        tableView.rowHeight = UITableView.automaticDimension
        tableView.separatorColor = UIColor.kpOffWhiteSeparator
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 15, bottom: 0, right: 15)
        
        navigationItem.leftBarButtonItem = UIBarButtonItem.init(image: UIImage(named: "Kinopub (Menu)")?.withRenderingMode(.alwaysTemplate), style: .plain, target: self, action: #selector(showMenu))
        print(NTDocumentPath)
    }
    
    @objc func initdata() {
        self.downed = NTDownloadManager.shared.finishedList
        self.downing = NTDownloadManager.shared.unFinishedList
        tableView.reloadData()
        control.endRefreshing()
    }
    
    @objc func showMenu() {
        if let navigationViewController = self.navigationController as? SideMenuItemContent {
            navigationViewController.showSideMenu()
        }
    }
    
    func showMoreAction(_ sender: Any) {
        ActionSheet(blurStyle: .dark).tint(.kpOffWhite)
            .addAction("Приостановить все", style: .default) { (_) in
                NTDownloadManager.shared.pauseAllTask()
            }
            .addAction("Запустить все", style: .default) { (_) in
                NTDownloadManager.shared.resumeAllTask()
            }
            .addAction("Удалить все", style: .destructive) { [weak self] (_) in
                self?.removeAllTask()
            }
            .addAction("Отменить", style: .cancel)
            .setBarButtonItem(sender as! UIBarButtonItem)
            .show()
        if #available(iOS 10.0, *) { Helper.hapticGenerate(style: .medium) }
    }
    
    func removeAllTask() {
        Alert(message: "Удалить все загрузки?", blurStyle: .dark).tint(.kpOffWhite).textColor(.kpOffWhite)
        .addAction("Да", style: .destructive) { [weak self] (_) in
            NTDownloadManager.shared.removeAllTask()
            self?.initdata()
        }
        .addAction("Нет", style: .cancel)
        .show()
        if #available(iOS 10.0, *) { Helper.hapticGenerate(style: .medium) }
    }
    
    @IBAction func showMoreMenu(_ sender: Any) {
        showMoreAction(sender)
    }
}

// MARK: UITableViewDatasource Handler Extension
extension DownloadTableViewController {
    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 2
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        if downing.count == 0, downed.count == 0 {
            Helper.EmptyMessage(message: "Здесь будут ваши локальные файлы", viewController: self)
            moreButton.isEnabled = false
        } else {
            tableView.backgroundView = nil
            moreButton.isEnabled = true
        }
        switch section {
        case 0: return downing.count
        case 1: return downed.count
        default: return 0
        }
        
    }
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            let cell = self.tableView.dequeueReusableCell(withIdentifier: DownloadingTableViewCell.reuseIdentifier, for: indexPath) as! DownloadingTableViewCell
            
            cell.fileInfo = downing[indexPath.row]
//            cell.progressView.isHidden = false
            
            return cell
        case 1:
            let cell = self.tableView.dequeueReusableCell(withIdentifier: DowloadedTableViewCell.reuseIdentifier, for: indexPath) as! DowloadedTableViewCell
            
            cell.fileInfo = downed[indexPath.row]
            
            return cell
        default:
            return UITableViewCell()
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0:
            return downing.count > 0 ? "ЗАГРУЖАЕТСЯ" : nil
        case 1:
            return downed.count > 0 ? "ЗАГРУЖЕНО" : nil
        default:
            return nil
        }
    }
    
    override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        view.tintColor = UIColor.kpBackground
        let header = view as! UITableViewHeaderFooterView
        header.textLabel?.textColor = UIColor.kpGreyishBrown
        header.textLabel?.font = header.textLabel?.font.withSize(12)
    }
    
//    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
//        let headerView = UIView(frame: CGRect(x: 0, y: 0, width: tableView.bounds.size.width, height: 30))
//        headerView.backgroundColor = UIColor.kpBackground
//        return headerView
//    }
}

// MARK: UITableViewDelegate Handler Extension

extension DownloadTableViewController {
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedIndexPath = indexPath
        if indexPath.section == 0 {
            playPauseTask(at: indexPath)
        }
        if indexPath.section == 1 {
            openInPlayer()
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        if indexPath.section == 1 {
            let delete = UITableViewRowAction(style: UITableViewRowAction.Style.destructive, title: "Удалить") { [weak self] (_, indexPath) in
                guard let strongSelf = self else { return }
                NTDownloadManager.shared.removeTask(downloadTask: strongSelf.downed[indexPath.row])
                strongSelf.downed.remove(at: indexPath.row)
                strongSelf.tableView.deleteRows(at: [indexPath], with: .fade)
            }
            
            let share = UITableViewRowAction(style: .default, title: "Поделиться", handler: { [weak self] (action, indexPath) in
                guard let strongSelf = self else { return }
                let fileUrl = URL(fileURLWithPath: "\(NTDocumentPath)/\(strongSelf.downed[indexPath.row].fileName)")
//                let str = self.downed[indexPath.row].fileName
                
                let activityViewController = UIActivityViewController(activityItems: [fileUrl], applicationActivities: nil)
                activityViewController.popoverPresentationController?.sourceView = strongSelf.tableView.cellForRow(at: indexPath)
                strongSelf.present(activityViewController, animated: true, completion: nil)
            })
            
            delete.backgroundColor = .kpGreyishTwo
            share.backgroundColor = .kpMarigold
            
            return [delete, share]
        } else if indexPath.section == 0 {
            let delete = UITableViewRowAction(style: UITableViewRowAction.Style.destructive, title: "Удалить") { [weak self] (_, indexPath) in
                guard let strongSelf = self else { return }
                NTDownloadManager.shared.removeTask(downloadTask: strongSelf.downing[indexPath.row])
                strongSelf.downing.remove(at: indexPath.row)
                strongSelf.tableView.deleteRows(at: [indexPath], with: .fade)
            }
            
            delete.backgroundColor = .kpGreyishTwo
            return [delete]
        } else {
            return nil
        }
    }
    
}

extension DownloadTableViewController {
//    func showActionController(at indexPath: IndexPath) {
//        let action = ActionSheet().tint(.kpBlack)
//        
//        if downing[selectedIndexPath.row].status == .NTDownloading {
//            action.addAction("Пауза", style: .default, handler: { [weak self] (_) in
//                guard let strongSelf = self else { return }
//                NTDownloadManager.shared.pauseTask(downloadTask: strongSelf.downing[strongSelf.selectedIndexPath.row])
//            })
//        }
//        if downing[selectedIndexPath.row].status == .NTPauseDownload {
//            action.addAction("Продолжить", style: .default, handler: { [weak self] (_) in
//                guard let strongSelf = self else { return }
//                NTDownloadManager.shared.resumeTask(downloadTask: strongSelf.downing[strongSelf.selectedIndexPath.row])
//            })
//        }
//        action.addAction("Удалить", style: .destructive) { [weak self] (_) in
//            self?.showConfirmAlert()
//        }
//        action.addAction("Отмена", style: .cancel)
//        action.setPresentingSource(tableView.cellForRow(at: indexPath)!)
//        action.show()
//        Helper.hapticGenerate(style: .medium)
//    }
    
    func playPauseTask(at indexPath: IndexPath) {
        if downing[indexPath.row].status == .NTDownloading {
            NTDownloadManager.shared.pauseTask(downloadTask: downing[indexPath.row])
        } else if downing[indexPath.row].status == .NTPauseDownload {
            NTDownloadManager.shared.resumeTask(downloadTask: downing[indexPath.row])
        }
    }
    
    func showConfirmAlert() {
        Alert(message: "Удалить?", blurStyle: .dark).tint(.kpOffWhite).textColor(.kpOffWhite)
        .addAction("Да", style: .destructive) { [weak self] (_) in
            guard let strongSelf = self else { return }
            NTDownloadManager.shared.removeTask(downloadTask: strongSelf.downing[strongSelf.selectedIndexPath.row])
            strongSelf.downing.remove(at: strongSelf.selectedIndexPath.row)
            strongSelf.tableView.deleteRows(at: [strongSelf.selectedIndexPath], with: .fade)
        }
        .addAction("Нет", style: .cancel)
        .show()
        if #available(iOS 10.0, *) { Helper.hapticGenerate(style: .medium) }
    }
    
    func openInPlayer() {
        var mediaItem = MediaItem()
        mediaItem.url = URL(fileURLWithPath: "\(NTDocumentPath)/\(self.downed[selectedIndexPath.row].fileName)")
        mediaItem.title = downed[selectedIndexPath.row].fileName.replacingOccurrences(of: ".mp4", with: "").replacingOccurrences(of: ";", with: "").replacingOccurrences(of: ".", with: " ")
        mediaManager.playVideo(mediaItems: [mediaItem], userinfo: nil)
    }
}

// MARK: - NTDownloadManagerDelegate

extension DownloadTableViewController: NTDownloadManagerDelegate {
    func downloadRequestFinished(downloadTask: NTDownloadTask) {
        let title = downloadTask.fileName.replacingOccurrences(of: ".mp4", with: "").replacingOccurrences(of: ";", with: "").replacingOccurrences(of: ".", with: " ")
        let banner = NotificationBanner(title: "Завершено", subtitle: "\(title) успешно загружен", style: .success)
        banner.duration = 3
        banner.show(queuePosition: .front)
        initdata()
    }
    
    func addDownloadRequest(downloadTask: NTDownloadTask) {
        initdata()
    }
    
    func downloadRequestUpdateProgress(downloadTask: NTDownloadTask) {
        let cellArr = self.tableView.visibleCells
        for obj in cellArr {
            if obj.isKind(of: DownloadingTableViewCell.self) {
                let cell = obj as! DownloadingTableViewCell
                if cell.fileInfo?.fileURL == downloadTask.fileURL {
                    cell.fileInfo = downloadTask
                }
            }
        }
    }
    
    func downloadRequestDidFailedWithError(error: Error, downloadTask: NTDownloadTask) {
        let title = downloadTask.fileName.replacingOccurrences(of: ".mp4", with: "").replacingOccurrences(of: ";", with: "").replacingOccurrences(of: ".", with: " ")
        Helper.showError("При загрузке \(title) произошла ошибка: \(error.localizedDescription)")
        initdata()
    }
    
    func downloadRequestDidPaused(downloadTask: NTDownloadTask) {
        let cellArr = self.tableView.visibleCells
        for obj in cellArr {
            if obj.isKind(of: DownloadingTableViewCell.self) {
                let cell = obj as! DownloadingTableViewCell
                if cell.fileInfo?.fileURL == downloadTask.fileURL {
                    cell.changeIcon()
                }
            }
        }
    }
    
    func downloadRequestDidStarted(downloadTask: NTDownloadTask) {
        let cellArr = self.tableView.visibleCells
        for obj in cellArr {
            if obj.isKind(of: DownloadingTableViewCell.self) {
                let cell = obj as! DownloadingTableViewCell
                if cell.fileInfo?.fileURL == downloadTask.fileURL {
                    cell.changeIcon()
                }
            }
        }
    }
}
