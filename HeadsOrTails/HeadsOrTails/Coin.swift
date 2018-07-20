//
//  Coin.swift
//  HeadsOrTails
//
//  Created by Matheus Garcia on 20/07/18.
//  Copyright © 2018 Matheus Garcia. All rights reserved.
//

import UIKit

enum Coin {
    case heads
    case tails

    func change(coin: Coin) -> Coin {

        if coin == Coin.heads {
            return Coin.tails
        } else {
            return Coin.heads
        }
    }
}
