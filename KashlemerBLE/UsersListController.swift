//
//  UsersListController.swift
//  KashlemerBLE
//
//  Created by Pavel Aristov on 04.04.18.
//  Copyright © 2018 aristovz. All rights reserved.
//

import UIKit

class UsersListController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    
    var users: [User] = []
    
    let refreshControl = UIRefreshControl()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        refreshControl.addTarget(self, action: #selector(refresh(_:)), for: .valueChanged)
        
        if #available(iOS 10.0, *) {
            tableView.refreshControl = refreshControl
        } else {
            tableView.backgroundView = refreshControl
        }
        
        refresh(refreshControl)
    }
    
    @objc func refresh(_ refreshControl: UIRefreshControl) {
        API.UserModule.getAll(requestEnd: { (result) in
            self.refreshControl.endRefreshing()
            
            guard let users = result else {
                return
            }
            
            self.users = users
            self.tableView.reloadData()
        })
    }
}

extension UsersListController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return users.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "userCell") else {
            return UITableViewCell()
        }
        
        let currentUser = users[indexPath.row]
        
        cell.textLabel?.text = "\(currentUser.surname) \(currentUser.name) \(currentUser.patronymic ?? "")"
        
        var age = "---"
        if let bday = currentUser.birthday {
            age = "\(bday.age) \(bday.age.ageString)"
        }
        
        let height = currentUser.height == nil ? "---" : "\(Int(currentUser.height!))"
        let weight = currentUser.weight == nil ? "---" : "\(Int(currentUser.weight!))"
        
        cell.detailTextLabel?.text = "возраст: \(age), рост: \(height) см, вес: \(weight) кг"
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        tableView.deselectRow(at: indexPath, animated: true)
        guard let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "audioListController") as? AudioListController else {
            print("Can't get audioListController")
            return
        }
        
        vc.currentUser = users[indexPath.row]
        self.navigationController?.pushViewController(vc, animated: true)
    }
}
