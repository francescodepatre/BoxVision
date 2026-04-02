import SwiftUI

struct ResultsView: View {
    let image: UIImage?
    let detections: [Detection]
    
    // Calcolo statistiche
    private var averageConfidence: Double {
        guard !detections.isEmpty else { return 0 }
        let total = detections.reduce(0.0) { $0 + Double($1.confidence) }
        return total / Double(detections.count)
    }
    
    private var uniqueClasses: Int {
        Set(detections.map { $0.label }).count
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                
                // 1. Immagine con Bounding Boxes
                if let image = image {
                    GeometryReader { geo in
                        let screenWidth = geo.size.width
                        let aspect = image.size.width / image.size.height
                        let renderedHeight = screenWidth / aspect

                        ZStack(alignment: .topLeading) {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                                .frame(width: screenWidth, height: renderedHeight)
                                .cornerRadius(16)

                            ForEach(detections) { det in
                                BoundingBoxView(
                                    detection: det,
                                    renderedSize: CGSize(width: screenWidth, height: renderedHeight)
                                )
                            }
                        }
                    }
                    .aspectRatio(image.size.width / image.size.height, contentMode: .fit)
                    .padding(.horizontal)
                }

                // 2. Stats Row (Griglia 3 colonne)
                HStack(spacing: 12) {
                    StatCard(value: "\(detections.count)", label: "objects")
                    StatCard(value: String(format: "%.0f%%", averageConfidence * 100), label: "avg conf")
                    StatCard(value: "\(uniqueClasses)", label: "classes")
                }
                .padding(.horizontal)

                // 3. Detection List
                VStack(alignment: .leading, spacing: 12) {
                    Text("Detections")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.secondary)
                        .padding(.horizontal)

                    if detections.isEmpty {
                        Text("No detections found.")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding()
                    } else {
                        VStack(spacing: 8) {
                            ForEach(detections) { det in
                                DetectionRow(detection: det)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .padding(.vertical)
        }
        .background(Color(white: 0.98))
        .navigationTitle("Results")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Componenti Supporto

struct StatCard: View {
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 18, weight: .bold, design: .rounded))
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color.white)
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gray.opacity(0.1), lineWidth: 1))
    }
}

struct DetectionRow: View {
    let detection: Detection
    
    // Colore dinamico basato sull'etichetta (come nel mockup)
    var color: Color {
        switch detection.label.lowercased() {
        case "person": return Color.red
        case "car": return Color.blue
        case "dog": return Color.green
        default: return Color.orange
        }
    }
    
    var body: some View {
        HStack {
            HStack(spacing: 10) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(color)
                    .frame(width: 10, height: 10)
                
                Text(detection.label)
                    .font(.system(size: 15, weight: .medium))
            }
            
            Spacer()
            
            Text(String(format: "%.0f%%", detection.confidence * 100))
                .font(.system(size: 15, weight: .semibold, design: .monospaced))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.white)
        .cornerRadius(12)
    }
}

struct BoundingBoxView: View {
    let detection: Detection
    let renderedSize: CGSize

    var color: Color {
        switch detection.label.lowercased() {
        case "person": return Color.red
        case "car": return Color.blue
        case "dog": return Color.green
        default: return Color.orange
        }
    }

    var body: some View {
        let rect = detection.boundingBox
        // Vision coordina (0,0) in basso a sinistra, SwiftUI in alto a sinistra
        let width = rect.width * renderedSize.width
        let height = rect.height * renderedSize.height
        let x = rect.origin.x * renderedSize.width
        let y = (1 - rect.origin.y - rect.height) * renderedSize.height

        ZStack(alignment: .topLeading) {
            // Box
            RoundedRectangle(cornerRadius: 4)
                .stroke(color, lineWidth: 2)
                .frame(width: width, height: height)

            // Label sopra il box
            Text("\(detection.label) \(String(format: "%.0f%%", detection.confidence * 100))")
                .font(.system(size: 9, weight: .bold))
                .foregroundColor(.white)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(color)
                .cornerRadius(3)
                .offset(y: -14) // Sposta sopra la linea del box
        }
        .offset(x: x, y: y)
    }
}
