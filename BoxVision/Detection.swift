//
//  Detection.swift
//  BoxVision
//
//  Created by Francesco De Patre on 02/04/26.
//

import Foundation

struct Detection: Identifiable {
    let id = UUID()
    let label: String
    let confidence: Float
    let boundingBox: CGRect
}
