//
//  MainViewController.swift
//  SwiftChip-8
//
//  Created by Brian Rojas on 8/12/17.
//  Copyright © 2017 Brian Rojas. All rights reserved.
//

import UIKit

class MainViewController: UIViewController {
    
    fileprivate var games = [URL]()
    
    @IBOutlet weak var gamesTableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loadGames()
        gamesTableView.reloadData()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "GameSegue" {
            let gameVC = segue.destination as! GameViewController
            gameVC.game = sender as? URL
            let backBarButtonItem = UIBarButtonItem(title: "Quit", style: .done, target: self, action: #selector(quit))
            navigationItem.backBarButtonItem = backBarButtonItem
        }
    }
    
    @objc private func quit() {
        dismiss(animated: true, completion: nil)
    }
    
    private func loadGames() {
        guard let games = Bundle.main.urls(forResourcesWithExtension: nil, subdirectory: "Games") else {
            return
        }
        self.games = games
    }

}

extension MainViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return games.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "GameCell")!
        cell.textLabel?.text = games[indexPath.row].lastPathComponent
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        performSegue(withIdentifier: "GameSegue", sender: games[indexPath.row])
    }
    
}
