enum ExtensionTypes {
    var supportsStillFrame: Bool {
        switch self {
        case .AnimatedImage, .Image, .Video:
            true
        default :
            false
        }
    }
    
    var systemImage: String {
        switch self {
        case .Audio:
            "waveform"
        case .Image:
            "photo"
        case .Video:
            "movieclapper"
        case .Archive:
            "zipper.page"
        case .PlainText:
            "text.document"
        case .AnimatedImage:
            "square.3.layers.3d.down.forward"
        default:
            "questionmark.folder"
        }
    }
    
    case Image
    case Video
    case AnimatedImage
    case Audio
    case Archive
    case PlainText
    case Unknown
}
