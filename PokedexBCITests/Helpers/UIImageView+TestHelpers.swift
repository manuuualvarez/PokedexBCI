import UIKit
import Kingfisher
@testable import PokedexBCI

extension UIImageView {
    /// Loads an image for snapshot testing
    /// This method ensures that images are loaded synchronously for consistent snapshots
    func setTestImage(for pokemonName: String) {
        // Cancel any ongoing network requests
        self.kf.cancelDownloadTask()
        
        // First try to load from assets
        if let image = UIImage(named: pokemonName.lowercased()) {
            self.image = image
            return
        }
        
        // Create a more realistic Pokemon sprite
        let size = CGSize(width: 120, height: 120)
        let renderer = UIGraphicsImageRenderer(size: size)
        let pokemonImage = renderer.image { ctx in
            // Background color based on Pokemon type
            let backgroundColor: UIColor
            switch pokemonName.lowercased() {
            case "bulbasaur":
                backgroundColor = UIColor(red: 120/255, green: 200/255, blue: 80/255, alpha: 0.3)
            case "charmander":
                backgroundColor = UIColor(red: 240/255, green: 128/255, blue: 48/255, alpha: 0.3)
            case "squirtle":
                backgroundColor = UIColor(red: 104/255, green: 144/255, blue: 240/255, alpha: 0.3)
            case "pikachu":
                backgroundColor = UIColor(red: 248/255, green: 208/255, blue: 48/255, alpha: 0.3)
            default:
                backgroundColor = UIColor(red: 168/255, green: 168/255, blue: 120/255, alpha: 0.3)
            }
            
            // Fill the background
            backgroundColor.setFill()
            ctx.fill(CGRect(origin: .zero, size: size))
            
            // Draw basic shapes to create a simplified Pokemon silhouette
            _ = ctx.cgContext
            
            switch pokemonName.lowercased() {
            case "bulbasaur":
                // Draw body (green rounded rectangle)
                let bodyPath = UIBezierPath(roundedRect: CGRect(x: 25, y: 50, width: 70, height: 50), cornerRadius: 20)
                UIColor(red: 0.2, green: 0.8, blue: 0.4, alpha: 1.0).setFill()
                bodyPath.fill()
                
                // Draw plant bulb
                let bulbPath = UIBezierPath(ovalIn: CGRect(x: 40, y: 20, width: 40, height: 40))
                UIColor(red: 0.1, green: 0.6, blue: 0.3, alpha: 1.0).setFill()
                bulbPath.fill()
                
                // Draw face
                let eyePath = UIBezierPath(ovalIn: CGRect(x: 40, y: 60, width: 10, height: 10))
                UIColor.white.setFill()
                eyePath.fill()
                
            case "charmander":
                // Draw body (orange rounded rectangle)
                let bodyPath = UIBezierPath(roundedRect: CGRect(x: 25, y: 45, width: 70, height: 55), cornerRadius: 20)
                UIColor(red: 1.0, green: 0.6, blue: 0.2, alpha: 1.0).setFill()
                bodyPath.fill()
                
                // Draw tail with flame
                let tailPath = UIBezierPath()
                tailPath.move(to: CGPoint(x: 25, y: 70))
                tailPath.addLine(to: CGPoint(x: 15, y: 50))
                tailPath.addLine(to: CGPoint(x: 5, y: 30))
                tailPath.addLine(to: CGPoint(x: 15, y: 40))
                tailPath.addLine(to: CGPoint(x: 25, y: 60))
                tailPath.close()
                UIColor(red: 1.0, green: 0.4, blue: 0.1, alpha: 1.0).setFill()
                tailPath.fill()
                
                // Draw flame
                let flamePath = UIBezierPath(ovalIn: CGRect(x: 0, y: 20, width: 15, height: 20))
                UIColor(red: 1.0, green: 0.2, blue: 0.1, alpha: 1.0).setFill()
                flamePath.fill()
                
                // Draw face
                let eyePath = UIBezierPath(ovalIn: CGRect(x: 40, y: 55, width: 10, height: 10))
                UIColor.white.setFill()
                eyePath.fill()
                
            case "squirtle":
                // Draw shell (brown rounded rectangle)
                let shellPath = UIBezierPath(roundedRect: CGRect(x: 30, y: 40, width: 60, height: 60), cornerRadius: 30)
                UIColor(red: 0.6, green: 0.4, blue: 0.2, alpha: 1.0).setFill()
                shellPath.fill()
                
                // Draw body (blue circle)
                let bodyPath = UIBezierPath(ovalIn: CGRect(x: 35, y: 30, width: 50, height: 60))
                UIColor(red: 0.2, green: 0.6, blue: 1.0, alpha: 1.0).setFill()
                bodyPath.fill()
                
                // Draw face
                let eyePath = UIBezierPath(ovalIn: CGRect(x: 50, y: 45, width: 10, height: 10))
                UIColor.white.setFill()
                eyePath.fill()
                
            case "pikachu":
                // Draw body (yellow rounded rectangle)
                let bodyPath = UIBezierPath(roundedRect: CGRect(x: 30, y: 50, width: 60, height: 50), cornerRadius: 20)
                UIColor(red: 1.0, green: 0.9, blue: 0.0, alpha: 1.0).setFill()
                bodyPath.fill()
                
                // Draw ears
                let leftEarPath = UIBezierPath()
                leftEarPath.move(to: CGPoint(x: 40, y: 50))
                leftEarPath.addLine(to: CGPoint(x: 30, y: 15))
                leftEarPath.addLine(to: CGPoint(x: 45, y: 30))
                leftEarPath.close()
                UIColor(red: 1.0, green: 0.9, blue: 0.0, alpha: 1.0).setFill()
                leftEarPath.fill()
                
                let rightEarPath = UIBezierPath()
                rightEarPath.move(to: CGPoint(x: 80, y: 50))
                rightEarPath.addLine(to: CGPoint(x: 90, y: 15))
                rightEarPath.addLine(to: CGPoint(x: 75, y: 30))
                rightEarPath.close()
                UIColor(red: 1.0, green: 0.9, blue: 0.0, alpha: 1.0).setFill()
                rightEarPath.fill()
                
                // Draw face
                let eyePath = UIBezierPath(ovalIn: CGRect(x: 45, y: 60, width: 10, height: 10))
                UIColor.black.setFill()
                eyePath.fill()
                
                // Draw cheeks
                let cheekPath = UIBezierPath(ovalIn: CGRect(x: 35, y: 75, width: 10, height: 10))
                UIColor(red: 1.0, green: 0.3, blue: 0.3, alpha: 1.0).setFill()
                cheekPath.fill()
                
            default:
                // Generic Pokemon
                let bodyPath = UIBezierPath(ovalIn: CGRect(x: 35, y: 40, width: 50, height: 50))
                UIColor.lightGray.setFill()
                bodyPath.fill()
                
                let headPath = UIBezierPath(ovalIn: CGRect(x: 45, y: 20, width: 30, height: 30))
                UIColor.white.setFill()
                headPath.fill()
                
                let eyePath = UIBezierPath(ovalIn: CGRect(x: 50, y: 25, width: 8, height: 8))
                UIColor.black.setFill()
                eyePath.fill()
            }
            
            // Draw Pokemon ID number
            let pokemonId: String
            switch pokemonName.lowercased() {
            case "bulbasaur": pokemonId = "#001"
            case "charmander": pokemonId = "#004"
            case "squirtle": pokemonId = "#007"
            case "pikachu": pokemonId = "#025"
            default: pokemonId = "#???"
            }
            
            let idAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 12),
                .foregroundColor: UIColor.darkGray
            ]
            
            let idSize = pokemonId.size(withAttributes: idAttributes)
            let idRect = CGRect(
                x: (size.width - idSize.width) / 2,
                y: size.height - idSize.height - 5,
                width: idSize.width,
                height: idSize.height
            )
            
            pokemonId.draw(in: idRect, withAttributes: idAttributes)
        }
        
        self.image = pokemonImage
        self.backgroundColor = .clear
        self.contentMode = .scaleAspectFit
    }
} 
