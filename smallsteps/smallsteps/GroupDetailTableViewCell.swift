//
//  GroupDetailTableViewCell.swift
//  smallsteps
//
//  Created by Jin Sun Park on 11/06/2018.
//  Copyright © 2018 group29. All rights reserved.
//

import UIKit

class GroupDetailTableViewCell: UITableViewCell {
    

    @IBOutlet weak var groupNameLabel: UILabel!
    
    @IBOutlet weak var meetingTimeLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
