//
//  PostListViewController.swift
//  IosSolid
//
//  Created by Grigory Sapogov on 23.12.2023.
//

import UIKit

class PostListViewController: UIViewController {

    var presenter: PostListViewPresenter!
    
    private var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Posts"
        self.view.backgroundColor = .systemBackground
        self.presenter.view = self
        self.setupTableView()
        self.layout()
    }

    private func setupTableView() {
        
        self.tableView = UITableView()
        self.tableView.dataSource = self
        self.tableView.refreshControl = UIRefreshControl()
        self.tableView.refreshControl?.addTarget(self, action: #selector(refresh), for: .valueChanged)
        self.tableView.register(UINib(nibName: "PostCell", bundle: nil), forCellReuseIdentifier: "PostCell")
        
    }
    
    @objc
    private func refresh() {
        
        self.presenter.update()
        
    }
    
    private func layout() {
        
        self.tableView.translatesAutoresizingMaskIntoConstraints = false
        
        self.view.addSubview(tableView)
        
        self.tableView.leadingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.leadingAnchor).isActive = true
        self.tableView.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor).isActive = true
        self.tableView.trailingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.trailingAnchor).isActive = true
        self.tableView.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor).isActive = true
        
    }
    
    private func endRefreshing() {
        self.tableView.refreshControl?.endRefreshing()
    }
    
    func updateView() {
        
        self.endRefreshing()
        self.tableView.reloadData()
        
    }
    
    func showError(error: Error) {
        
        print(error)
        
    }
    
}

extension PostListViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        self.presenter.posts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "PostCell", for: indexPath) as? PostCell else { return UITableViewCell() }
        
        let post = self.presenter.posts[indexPath.row]
        
        cell.setup(post: post)
        
        return cell
        
    }

}
