import Foundation

public enum FileAction: Equatable, Sendable {
    // MARK: - Shift (Конвертация)
    case convertVideo(VideoTargetFormat)
    case convertImage(ImageTargetFormat)
    case convertPDF(PDFTargetFormat)
    case convertData(DataTargetFormat)
    case convertDocument(DocTargetFormat)
    
    // MARK: - Control (Магия)
    case magicVideo(VideoMagicAction)
    case magicImage(MagicAction)
    case magicPDF(PDFMagicAction)
    case magicData(DataMagicAction)
    case magicDoc(DocMagicAction)
    
    // MARK: - Option (Скорость / Масштаб / Действия)
    case videoSpeed(Double)
    case imageScale(Double)
    case optionPDF(PDFOptionAction)
    case optionData(DataOptionAction)
    
    // MARK: - Command (Кроп / Кадрирование / Команды)
    case cropVideo(VideoCropMode)
    case cropImage(CropRatio)
    case commandPDF(PDFCommandAction)
    case commandData(DataCommandAction)
}
