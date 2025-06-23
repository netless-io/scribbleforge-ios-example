import ScribbleForge
import SwiftUI

enum StrokeWidthType: Float, CaseIterable {
    case level1 = 4
    case level2 = 14
    case level3 = 24
}

enum FontSize: Float, CaseIterable {
    case small = 24
    case medium = 44
    case large = 66
}

enum DashStyle: CaseIterable {
    case style1
    case style2
    case style3

    var imageName: String {
        switch self {
        case .style1:
            "rays"
        case .style2:
            "circle.dashed"
        case .style3:
            "circle"
        }
    }

    init(value: [Float]) {
        self = Self.allCases.first(where: { $0.values == value })!
    }

    var values: [Float] {
        switch self {
        case .style1:
            [2, 2, 2]
        case .style2:
            [8, 8, 8]
        case .style3:
            []
        }
    }
}

var colors: [UIColor] = [.green, .blue, .orange, .red, .gray]
let storkrWidths: [StrokeWidthType] = StrokeWidthType.allCases
let fontSizes: [FontSize] = FontSize.allCases
let dashStyles = DashStyle.allCases

struct PopOver: View {
    init(
        attributes: [ElementAttributesKey: Any],
        colorUpdate: ((UIColor?) -> Void)? = nil,
        strokeWidthUpdate: ((Float) -> Void)? = nil,
        fillColorUpdate: ((UIColor?) -> Void)? = nil,
        fontSizeUpdate: ((Float) -> Void)? = nil,
        dashStyleUpdate: (([Float]) -> Void)? = nil,
        headArrowUpdate: ((Bool) -> Void)? = nil,
        tailArrowUpdate: ((Bool) -> Void)? = nil
    ) {
        attributesKeys = Array(attributes.keys)
        if let colorString = attributes[.strokeColor] as? String {
            let color = UIColor(hex: colorString)
            _selectedStrokeColor = .init(wrappedValue: color)
            if !colors.contains(color) {
                colors.insert(color, at: 0)
            }
        }
        if let colorString = attributes[.fillColor] as? String {
            let color = UIColor(hex: colorString)
            _selectedFillColor = .init(wrappedValue: color)
            if !colors.contains(color) {
                colors.insert(color, at: 0)
            }
        }
        let dashArray = attributes[.dashArray] as? [Float] ?? []
        _selectedDashStyle = .init(wrappedValue: .init(value: dashArray))
        _selectedFontSize = .init(wrappedValue: attributes[.fontSize] as? Float)
        _selectedStrokeWidth = .init(wrappedValue: attributes[.strokeWidth] as? Float)
        _selectedHeadArrow = .init(wrappedValue: attributes[.headArrow] as? String == "normal")
        _selectedTailArrow = .init(wrappedValue: attributes[.tailArrow] as? String == "normal")
        strokeColorUpdate = colorUpdate
        self.strokeWidthUpdate = strokeWidthUpdate
        self.fillColorUpdate = fillColorUpdate
        self.fontSizeUpdate = fontSizeUpdate
        self.dashStyleUpdate = dashStyleUpdate
        self.headArrowUpdate = headArrowUpdate
        self.tailArrowUpdate = tailArrowUpdate
    }

    let attributesKeys: [ElementAttributesKey]
    var strokeColorUpdate: ((UIColor?) -> Void)?
    var fillColorUpdate: ((UIColor?) -> Void)?
    var strokeWidthUpdate: ((Float) -> Void)?
    var fontSizeUpdate: ((Float) -> Void)?
    var dashStyleUpdate: (([Float]) -> Void)?
    var headArrowUpdate: ((Bool) -> Void)?
    var tailArrowUpdate: ((Bool) -> Void)?
    @State var selectedStrokeColor: UIColor?
    @State var selectedFillColor: UIColor?
    @State var selectedStrokeWidth: Float?
    @State var selectedFontSize: Float?
    @State var selectedDashStyle: DashStyle?
    @State var selectedHeadArrow: Bool?
    @State var selectedTailArrow: Bool?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if attributesKeys.contains(.strokeColor) {
                Text("Stroke Color")
                HStack {
                    ForEach(colors, id: \.self) { color in
                        RoundedRectangle(cornerRadius: 2)
                            .padding(2)
                            .foregroundStyle(Color(uiColor: color))
                            .aspectRatio(1, contentMode: .fit)
                            .overlay {
                                RoundedRectangle(cornerRadius: 2)
                                    .stroke(selectedStrokeColor == color ? Color(uiColor: color) : .clear)
                            }
                            .onTapGesture {
                                selectedStrokeColor = color
                                strokeColorUpdate?(color)
                            }
                    }
                }
            }
            if attributesKeys.contains(.fillColor) {
                Text("Fill Color")
                HStack {
                    ForEach(colors, id: \.self) { color in
                        RoundedRectangle(cornerRadius: 2)
                            .padding(2)
                            .foregroundStyle(Color(uiColor: color))
                            .aspectRatio(1, contentMode: .fit)
                            .overlay {
                                RoundedRectangle(cornerRadius: 2)
                                    .stroke(selectedFillColor == color ? Color(uiColor: color) : .clear)
                            }
                            .onTapGesture {
                                selectedFillColor = color
                                fillColorUpdate?(color)
                            }
                    }
                }
            }
            if attributesKeys.contains(.strokeWidth) {
                Text("Stroke Width")
                HStack {
                    ForEach(storkrWidths, id: \.rawValue) { strokwWidth in
                        Color.clear
                            .aspectRatio(1, contentMode: .fit)
                            .frame(maxWidth: 44, maxHeight: 44)
                            .overlay {
                                Rectangle()
                                    .padding(.horizontal, 4)
                                    .frame(height: CGFloat(strokwWidth.rawValue / 2))
                            }
                            .overlay {
                                RoundedRectangle(cornerRadius: 2)
                                    .stroke((selectedStrokeWidth ?? 0) == strokwWidth.rawValue ? Color.black : Color.clear)
                            }
                            .onTapGesture {
                                selectedStrokeWidth = strokwWidth.rawValue
                                strokeWidthUpdate?(strokwWidth.rawValue)
                            }
                    }
                }
            }
            if attributesKeys.contains(.fontSize) {
                Text("Font size")
                HStack {
                    ForEach(fontSizes, id: \.self) { fontSize in
                        Color.clear
                            .aspectRatio(1, contentMode: .fit)
                            .frame(maxWidth: 44, maxHeight: 44)
                            .overlay {
                                Image(systemName: "textformat.size.larger")
                                    .font(.system(size: CGFloat(fontSize.rawValue / 2), weight: .ultraLight))
                                    .aspectRatio(1, contentMode: .fit)
                            }

                            .overlay {
                                RoundedRectangle(cornerRadius: 2)
                                    .stroke((selectedFontSize ?? 0) == fontSize.rawValue ? Color.black : Color.clear)
                            }
                            .onTapGesture {
                                selectedFontSize = fontSize.rawValue
                                fontSizeUpdate?(fontSize.rawValue)
                            }
                    }
                }
            }
            if attributesKeys.contains(.dashArray) {
                Text("Dash style")
                HStack {
                    ForEach(dashStyles, id: \.self) { dashStyle in
                        Color.clear
                            .frame(maxWidth: 44, maxHeight: 44)
                            .aspectRatio(1, contentMode: .fit)
                            .overlay {
                                Image(systemName: dashStyle.imageName)
                                    .aspectRatio(1, contentMode: .fit)
                            }

                            .overlay {
                                RoundedRectangle(cornerRadius: 2)
                                    .stroke(selectedDashStyle == dashStyle ? Color.black : Color.clear)
                            }
                            .onTapGesture {
                                selectedDashStyle = dashStyle
                                dashStyleUpdate?(dashStyle.values)
                            }
                    }
                }
            }
            if attributesKeys.contains(.headArrow) || attributesKeys.contains(.tailArrow) {
                Text("Arrow Style")
                HStack {
                    Color.clear
                        .frame(width: 44, height: 44)
                        .overlay {
                            Image(systemName: "arrow.backward")
                                .aspectRatio(1, contentMode: .fit)
                        }
                        .overlay {
                            RoundedRectangle(cornerRadius: 2)
                                .stroke(selectedHeadArrow == true ? Color.black : Color.clear)
                        }
                        .onTapGesture {
                            selectedHeadArrow?.toggle()
                            headArrowUpdate?(selectedHeadArrow ?? false)
                        }
                    
                    Color.clear
                        .frame(width: 44, height: 44)
                        .overlay {
                            Image(systemName: "arrow.forward")
                                .aspectRatio(1, contentMode: .fit)
                        }
                        .overlay {
                            RoundedRectangle(cornerRadius: 2)
                                .stroke(selectedTailArrow == true ? Color.black : Color.clear)
                        }
                        .onTapGesture {
                            selectedTailArrow?.toggle()
                            tailArrowUpdate?(selectedTailArrow ?? false)
                        }
                }
            }
        }
        .padding(.horizontal, 8)
        .font(.subheadline)
    }
}

#Preview {
    PopOver(attributes: [
        .strokeColor: "1",
        .fillColor: "1",
        .strokeWidth: "1",
        .fontSize: "1",
        .dashArray: "1",
        .headArrow: true,
        .tailArrow: false,
        .fontFamily: "1",
    ])
    .frame(width: 244)
    .background(.blue)
}
