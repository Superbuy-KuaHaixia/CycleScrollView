//
//  ViewController.swift
//  ImageCycleTest
//
//  Created by wood on 2020/3/27.
//  Copyright © 2020 wood. All rights reserved.
//

import UIKit

class ViewController: UIViewController, CycleScrollViewDelegate {
    
    func cycleScrollView(_ cycleScrollView: CycleScrollView, didSelectItem index: Int) {
        print(index)
    }
    

    @IBOutlet weak var cycleScrollView: CycleScrollView!
    override func viewDidLoad() {
        super.viewDidLoad()
        cycleScrollView.delegate = self
        cycleScrollView.imagePaths = ["https://img1.superbuy.com/images/daigou-admin/2020/03/23/a77b3abd-14ad-4c85-af6f-fe5e377babf5.png", "https://img1.superbuy.com/images/daigou-admin/2020/03/19/773e00b1-8001-4057-8378-e5e64f96274a.jpg", "https://img1.superbuy.com/images/daigou-admin/2020/03/23/a77b3abd-14ad-4c85-af6f-fe5e377babf5.png"]
    }

    
}

