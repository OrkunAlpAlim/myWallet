//
//  HomeViewController.swift
//  myWallet
//
//  Created by Orkun Alp Alim on 24.06.2025.
//

import UIKit

class HomeViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

                let label = UILabel()
                label.text = "Ana Sayfa"
                label.textAlignment = .center
                label.font = UIFont.boldSystemFont(ofSize: 24)

                label.translatesAutoresizingMaskIntoConstraints = false
                view.addSubview(label)

                NSLayoutConstraint.activate([
                    label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                    label.centerYAnchor.constraint(equalTo: view.centerYAnchor)
                ])

        // Do any additional setup after loading the view.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
