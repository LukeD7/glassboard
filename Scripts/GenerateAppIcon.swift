import AppKit

guard CommandLine.arguments.count == 3 else {
    print("Usage: swift GenerateAppIcon.swift <input_image> <output_iconset_dir>")
    exit(1)
}

let inputPath = CommandLine.arguments[1]
let outputDir = CommandLine.arguments[2]

guard let image = NSImage(contentsOfFile: inputPath) else {
    print("Error: Could not load image at \(inputPath)")
    exit(1)
}

// Ensure output directory exists
try? FileManager.default.createDirectory(atPath: outputDir, withIntermediateDirectories: true)

// Standard macOS icon set spec
// (Size in points, Scale)
let specs: [(Int, Int)] = [
    (16, 1), (16, 2),
    (32, 1), (32, 2),
    (128, 1), (128, 2),
    (256, 1), (256, 2),
    (512, 1), (512, 2)
]

for (pointSize, scale) in specs {
    let pixelSize = pointSize * scale
    let newSize = NSSize(width: pixelSize, height: pixelSize)
    
    // Create a new image context
    let targetImage = NSImage(size: newSize)
    targetImage.lockFocus()
    
    // 1. Calculate aspect-fit rect
    // We want to center the image within the square canvas without stretching
    let inputSize = image.size
    let aspect = inputSize.width / inputSize.height
    
    var drawRect = NSRect.zero
    let canvasSize = CGFloat(pixelSize)
    
    if aspect > 1 {
        // Wider than tall: Width fills canvas, height is calculated
        let scaledHeight = canvasSize / aspect
        drawRect = NSRect(x: 0, 
                          y: (canvasSize - scaledHeight) / 2, 
                          width: canvasSize, 
                          height: scaledHeight)
    } else {
        // Taller than wide: Height fills canvas, width is calculated
        let scaledWidth = canvasSize * aspect
        drawRect = NSRect(x: (canvasSize - scaledWidth) / 2, 
                          y: 0, 
                          width: scaledWidth, 
                          height: canvasSize)
    }
    
    // 2. Draw with high quality interpolation
    NSGraphicsContext.current?.imageInterpolation = .high
    image.draw(in: drawRect, from: .zero, operation: .copy, fraction: 1.0)
    
    targetImage.unlockFocus()
    
    // 3. Save as PNG
    let scaleSuffix = scale == 2 ? "@2x" : ""
    let filename = "icon_\(pointSize)x\(pointSize)\(scaleSuffix).png"
    let url = URL(fileURLWithPath: outputDir).appendingPathComponent(filename)
    
    if let tiff = targetImage.tiffRepresentation,
       let bitmap = NSBitmapImageRep(data: tiff),
       let png = bitmap.representation(using: .png, properties: [:]) {
        try? png.write(to: url)
        print("Generated \(filename)")
    } else {
        print("Failed to generate \(filename)")
    }
}
