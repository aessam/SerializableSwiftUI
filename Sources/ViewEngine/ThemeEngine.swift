import SwiftUI

public class ThemeEngine {
    public static let shared = ThemeEngine()

    public var colorDefs: [String: ColorDef] = [:]
    public var fonts: [String: FontDef] = [:]
    public var presets: [String: [String: AnyCodableValue]] = [:]

    public enum ColorDef {
        case fixed(String)
        case adaptive(light: String, dark: String)
    }

    public struct FontDef: Codable {
        public let size: CGFloat
        public let weight: String?
        public let design: String?
    }

    private struct ThemeFile: Codable {
        let colors: [String: AnyCodableValue]?
        let fonts: [String: FontDef]?
        let presets: [String: [String: AnyCodableValue]]?
    }

    public func load(from bundle: Bundle = .main) {
        guard let url = bundle.url(forResource: "theme", withExtension: "json"),
              let data = try? Data(contentsOf: url) else { return }
        guard let theme = try? JSONDecoder().decode(ThemeFile.self, from: data) else { return }

        // Parse colors — either a string or {"light": ..., "dark": ...}
        if let rawColors = theme.colors {
            for (name, value) in rawColors {
                if let str = value.stringValue {
                    colorDefs[name] = .fixed(str)
                } else if let dict = value.dictionaryValue,
                          let light = dict["light"]?.stringValue,
                          let dark = dict["dark"]?.stringValue {
                    colorDefs[name] = .adaptive(light: light, dark: dark)
                }
            }
        }

        self.fonts = theme.fonts ?? [:]
        self.presets = theme.presets ?? [:]
    }

    // For legacy compat
    public var colors: [String: String] {
        var result: [String: String] = [:]
        for (k, v) in colorDefs {
            switch v {
            case .fixed(let hex): result[k] = hex
            case .adaptive(let light, _): result[k] = light
            }
        }
        return result
    }

    public func resolveColor(_ name: String) -> Color {
        guard let def = colorDefs[name] else {
            // Not a named color — treat as raw hex
            return Color(hex: name)
        }
        switch def {
        case .fixed(let hex):
            return Color(hex: hex)
        case .adaptive(let light, let dark):
            return Color(nsColor: NSColor(name: nil) { appearance in
                let isDark = appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
                return isDark ? NSColor(Color(hex: dark)) : NSColor(Color(hex: light))
            })
        }
    }

    public func resolveFont(_ name: String) -> Font {
        guard let def = fonts[name] else { return .body }
        let weight = fontWeight(def.weight)
        let design = fontDesign(def.design)
        return Font.system(size: def.size, weight: weight, design: design)
    }

    public func preset(_ name: String) -> [String: AnyCodableValue] {
        presets[name] ?? [:]
    }

    public func applyStyle<V: View>(_ view: V, style: String?, inlineStyle: [String: AnyCodableValue]?) -> some View {
        var merged: [String: AnyCodableValue] = [:]
        if let style, let p = presets[style] {
            merged = p
        }
        if let inline = inlineStyle {
            for (k, v) in inline { merged[k] = v }
        }
        return applyProperties(view, properties: merged)
    }

    private func applyProperties<V: View>(_ view: V, properties: [String: AnyCodableValue]) -> AnyView {
        var v: AnyView = AnyView(view)
        let props = properties

        if let fontName = props["font"]?.stringValue {
            v = AnyView(v.font(resolveFont(fontName)))
        }
        if let colorName = props["foregroundColor"]?.stringValue {
            v = AnyView(v.foregroundStyle(resolveColor(colorName)))
        }
        if let bgName = props["backgroundColor"]?.stringValue {
            v = AnyView(v.background(resolveColor(bgName)))
        }
        if let padding = props["padding"] {
            if let p = padding.doubleValue {
                v = AnyView(v.padding(CGFloat(p)))
            } else if let dict = padding.dictionaryValue {
                let top = dict["top"]?.doubleValue ?? 0
                let bottom = dict["bottom"]?.doubleValue ?? 0
                let leading = dict["leading"]?.doubleValue ?? 0
                let trailing = dict["trailing"]?.doubleValue ?? 0
                v = AnyView(v.padding(EdgeInsets(top: CGFloat(top), leading: CGFloat(leading),
                                                  bottom: CGFloat(bottom), trailing: CGFloat(trailing))))
            }
        }
        if let cr = props["cornerRadius"]?.doubleValue {
            v = AnyView(v.clipShape(RoundedRectangle(cornerRadius: CGFloat(cr))))
        }
        let width = frameDimension(props["width"])
        let height = frameDimension(props["height"])
        let maxWidth = frameDimension(props["maxWidth"])
        let maxHeight = frameDimension(props["maxHeight"])
        if width != nil || height != nil || maxWidth != nil || maxHeight != nil {
            v = AnyView(v.frame(width: width, height: height))
            if maxWidth != nil || maxHeight != nil {
                v = AnyView(v.frame(maxWidth: maxWidth, maxHeight: maxHeight))
            }
        }
        if let shadow = props["shadow"]?.dictionaryValue {
            let radius = shadow["radius"]?.doubleValue ?? 0
            let x = shadow["x"]?.doubleValue ?? 0
            let y = shadow["y"]?.doubleValue ?? 0
            let color = shadow["color"]?.stringValue.map { Color(hex: $0) } ?? .black.opacity(0.2)
            v = AnyView(v.shadow(color: color, radius: CGFloat(radius), x: CGFloat(x), y: CGFloat(y)))
        }
        if let opacity = props["opacity"]?.doubleValue {
            v = AnyView(v.opacity(opacity))
        }
        if let clip = props["clipShape"]?.stringValue, clip == "circle" {
            v = AnyView(v.clipShape(Circle()))
        }
        return v
    }

    private func frameDimension(_ value: AnyCodableValue?) -> CGFloat? {
        guard let value else { return nil }
        if let s = value.stringValue, s == "infinity" { return .infinity }
        if let d = value.doubleValue { return CGFloat(d) }
        return nil
    }

    private func fontWeight(_ str: String?) -> Font.Weight {
        switch str {
        case "ultraLight": return .ultraLight
        case "thin": return .thin
        case "light": return .light
        case "regular": return .regular
        case "medium": return .medium
        case "semibold": return .semibold
        case "bold": return .bold
        case "heavy": return .heavy
        case "black": return .black
        default: return .regular
        }
    }

    private func fontDesign(_ str: String?) -> Font.Design {
        switch str {
        case "monospaced": return .monospaced
        case "rounded": return .rounded
        case "serif": return .serif
        default: return .default
        }
    }
}

extension Color {
    public init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255,
                  blue: Double(b) / 255, opacity: Double(a) / 255)
    }
}
