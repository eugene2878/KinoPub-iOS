//
//  CommentsVC.swift
//  qinoa
//
//  Created by Евгений Дац on 29.06.2018.
//  Copyright © 2018 KinoPub. All rights reserved.
//

import UIKit
import GradientLoadingBar

class CommentsVC: UIViewController {
    private let model = Container.ViewModel.comments()
    var id: String!
    let control = UIRefreshControl()
    var isHiddenSpoiler = true
    
    @IBOutlet weak var tableView: UITableView!
    
    @IBAction func spoilerButtonTapped(_ sender: Any) {
        isHiddenSpoiler.toggle()
        tableView.reloadData()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        loadData()
        configView()
        configTableView()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func loadData() {
        model.loadNoDeletedComments(for: id)
    }
    
    func configView() {
        if #available(iOS 11.0, *) {
            navigationItem.largeTitleDisplayMode = .always
        }
        model.delegate = self
        view.backgroundColor = UIColor.kpBackground
    }
    
    func configTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.estimatedRowHeight = 100
        tableView.rowHeight = UITableView.automaticDimension
        tableView.backgroundColor = UIColor.kpBackground
        tableView.tableFooterView = UIView(frame: CGRect.zero)
        tableView.register(UINib(nibName: String(describing: CommentsTableViewCell.self), bundle: Bundle.main), forCellReuseIdentifier: String(describing: CommentsTableViewCell.self))
        
        // Pull to refresh
        control.addTarget(self, action: #selector(refresh), for: UIControl.Event.valueChanged)
        control.tintColor = UIColor.kpOffWhite
        if #available(iOS 10.0, *) {
            tableView.refreshControl = control
        } else {
            tableView.addSubview(control)
        }
    }
    
    func beginLoad() {
        GradientLoadingBar.shared.show()
        control.beginRefreshing()
    }
    
    func endLoad() {
        tableView.reloadData()
        GradientLoadingBar.shared.hide()
        control.endRefreshing()
    }
    
    @objc func refresh() {
        beginLoad()
        loadData()
    }
    

    // MARK: Navigation
    static func storyboardInstance() -> CommentsVC? {
        let storyboard = UIStoryboard(name: String(describing: DetailViewController.self), bundle: nil)
        return storyboard.instantiateViewController(withIdentifier: String(describing: self)) as? CommentsVC
    }

}

extension CommentsVC: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return model.comments.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: CommentsTableViewCell.self), for: indexPath) as! CommentsTableViewCell
        cell.isHiddenSpoiler = isHiddenSpoiler
        cell.config(with: model.comments[indexPath.row])
        cell.selectionStyle = .none
        return cell
    }
}

extension CommentsVC: UITableViewDelegate {
    
}

extension CommentsVC: CommentsModelDelegate {
    func didUpdateComments() {
        endLoad()
    }
}
