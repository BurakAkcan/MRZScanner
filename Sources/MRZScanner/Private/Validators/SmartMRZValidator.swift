//
//  File.swift
//  MRZScanner
//
//  Created by Burak AKCAN on 27.03.2025.
//

import MRZParser
import Foundation

struct SmartMRZValidator: Validator {
  func getValidatedResults(from possibleLines: [[String]]) -> ValidatedResults {
    for format in MRZFormat.allCases {
      var validLines = ValidatedResults()
      
      for (index, lineSet) in possibleLines.enumerated() {
        guard index < format.linesCount else { break } // Önemli güvenlik kontrolü
        
        var foundValidLine = false
        for line in lineSet {
          let trimmed = line.filter { !$0.isWhitespace }
          let corrected = correctLine(trimmed, for: format, atLineIndex: index)
          
          if corrected.count == format.lineLength {
            validLines.append(.init(result: corrected, index: index))
            foundValidLine = true
            break
          }
        }
        
        if !foundValidLine {
          break // Geçerli satır bulunamazsa sonraki formatı dene
        }
      }
      
      if validLines.count == format.linesCount {
        return validLines
      }
    }
    return []
  }
  
  private func correctLine(_ line: String, for format: MRZFormat, atLineIndex index: Int) -> String {
    var characters = Array(line)
    
    guard characters.count >= format.lineLength else {
      return line // Uzunluk yetersizse orijinali döndür
    }
    
    if format == .td1 {
      switch index {
      case 0:
        // Güvenli aralık kontrolleri eklendi
        safeCorrectRange(&characters, 0..<2, using: replaceDigits)
        safeCorrectRange(&characters, 2..<5, using: replaceDigits)
        safeCorrectRange(&characters, 5..<8, using: replaceLetters)
        safeCorrectRange(&characters, 9..<14, using: replaceLetters)
        safeCorrectRange(&characters, 15..<30, using: replaceLetters)
        
        // 8. index için güvenli kontrol
        safeCharacterCorrection(&characters, index: 8, using: replaceDigits)
        
      case 1:
        safeCorrectRange(&characters, 0..<6, using: replaceLetters)
        safeCorrectRange(&characters, 7..<8, using: replaceDigits)
        safeCorrectRange(&characters, 8..<14, using: replaceLetters)
        safeCorrectRange(&characters, 15..<18, using: replaceDigits)
        safeCorrectRange(&characters, 18..<29, using: replaceLetters)
        
      default: break
      }
    }
    
    return String(characters)
  }
  
  // MARK: - Güvenli Düzeltme Fonksiyonları
  private func safeCorrectRange(
    _ characters: inout [Character],
    _ range: Range<Int>,
    using correction: (Character) -> Character
  ) {
    let clampedRange = range.clamped(to: 0..<characters.count)
    for i in clampedRange {
      characters[i] = correction(characters[i])
    }
  }
  
  private func safeCharacterCorrection(
    _ characters: inout [Character],
    index: Int,
    using correction: (Character) -> Character
  ) {
    guard characters.indices.contains(index) else { return }
    characters[index] = correction(characters[index])
  }
  
  // MARK: - OCR Düzeltme Mantığı
  private func replaceLetters(_ char: Character) -> Character {
    switch char {
    case "O", "Q", "U", "D": return "0"
    case "I", "L", "|": return "1"
    case "Z": return "2"
    case "B": return "8"
    case "S": return "5"
    case "G": return "6"
    default: return char
    }
  }
  
  private func replaceDigits(_ char: Character) -> Character {
    switch char {
    case "0": return "O"
    case "1": return "I"
    case "2": return "Z"
    case "5": return "S"
    case "6": return "G"
    case "8": return "B"
    default: return char
    }
  }
}
