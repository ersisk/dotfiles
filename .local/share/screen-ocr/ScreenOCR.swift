// screen-ocr <image> — print the text Vision finds in an image, one line per line.
//
// Exists so jira-to-branch can read a Jira title off the screen without a Raycast
// round trip. Vision ships with macOS, so this stays dependency-free.

import Vision
import AppKit

let args = CommandLine.arguments
guard args.count == 2, let img = NSImage(contentsOfFile: args[1]) else {
    FileHandle.standardError.write(Data("usage: screen-ocr <image>\n".utf8))
    exit(2)
}

var rect = NSRect(origin: .zero, size: img.size)
guard let cg = img.cgImage(forProposedRect: &rect, context: nil, hints: [:]) else {
    FileHandle.standardError.write(Data("screen-ocr: cannot decode \(args[1])\n".utf8))
    exit(3)
}

let request = VNRecognizeTextRequest()
// Turkish first: a Jira title read as English loses every ı, ğ and ş.
request.recognitionLanguages = ["tr-TR", "en-US"]
request.recognitionLevel = .accurate
request.usesLanguageCorrection = true

do {
    try VNImageRequestHandler(cgImage: cg).perform([request])
} catch {
    FileHandle.standardError.write(Data("screen-ocr: \(error.localizedDescription)\n".utf8))
    exit(4)
}

for observation in request.results ?? [] {
    if let line = observation.topCandidates(1).first?.string { print(line) }
}
