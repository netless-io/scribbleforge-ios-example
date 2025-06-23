import ScribbleForge
import SwiftUI

private let keys = ["viewport", "elements", "max"]
struct RasterizeOptionPickView: View {
    var confirm: ((RasterizeOption)->Void)?
    @State var optionKey: String = keys[0]
    @State var scale: Float = 1
    @State var page: Int = 0
    @State var width: CGFloat = 1920
    @State var height: CGFloat = 1080
    var body: some View {
        VStack {
            Picker("Option", selection: $optionKey) {
                ForEach(keys, id: \.self) { key in
                    Text(key)
                }
            }
            HStack {
                // scale like style: "1.1"
                Text("Scale: \(scale.formatted())")
                Slider(value: $scale, in: 0.1...3, step: 0.1) {
                    Text("Scale")
                }
            }
            HStack {
                Text("Page")
                Picker("", selection: $page) {
                    ForEach(0...9, id: \.self) { id in
                        Text((id+1).description)
                    }
                }
            }
            if optionKey == "elements" {
                HStack {
                    HStack {
                        Text("Width:")
                        TextField("Width", value: $width, formatter: NumberFormatter())
                    }
                }
                HStack {
                    Text("Height:")
                    TextField("Height", value: $height, formatter: NumberFormatter())
                }
            }
            Button("Confirm") {
                let p = PageIdentifier.index(page)
                let option: RasterizeOption
                switch optionKey {
                case "viewport": option = .viewport(page: p, scale: CGFloat(scale))
                case "elements": option = .elementsBounds(page: p, maxWidth: width, maxHeight: height)
                case "max": option = .maxBounds(page: p, scale: CGFloat(scale))
                default: option = .viewport(page: p, scale: CGFloat(scale))
                }
                confirm?(option)
            }
            .buttonStyle(BorderedProminentButtonStyle())
        }
        .padding()
    }
}

#Preview {
    RasterizeOptionPickView()
}
