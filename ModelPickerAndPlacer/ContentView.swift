//
//  ContentView.swift
//  ModelPickerAndPlacer
//
//  Created by 村中光一 on 2023/01/15.
//

import SwiftUI
import RealityKit
import ARKit
import FocusEntity

struct ContentView : View {
    
    @State private var isPlacementEnabled = false
    @State private var selectedModel: Model?
    @State private var modelConfirmedForPlacement: Model?
    
    private var models: [Model] = {
        
        // Dynamically get our model filenames
        let filemanager = FileManager.default
        
        guard let path = Bundle.main.resourcePath, let
                files = try?
                filemanager.contentsOfDirectory(atPath: path) else {
                return []
        }
        
        var availableModels: [Model] = []
        for filename in files where
            filename.hasSuffix(".usdz") {
                let modelName = filename.replacingOccurrences(of: ".usdz", with: "")
                let model = Model(modelName: modelName)
                
                availableModels.append(model)
        }
        
        return availableModels
    }()
    
    var body: some View {
        
        ZStack(alignment: .bottom) {
            ARViewContainer(modelConfirmedForPlacement: self.$modelConfirmedForPlacement)
            
            if self.isPlacementEnabled {
                PlacementButtonsView(isPlacementEnabled: self.$isPlacementEnabled, selectedModel: self.$selectedModel, modelConfirmedForPlacement: self.$modelConfirmedForPlacement)
            } else  {
                ModelPickerView(isPlacementEnabled: self.$isPlacementEnabled, selectedModel: self.$selectedModel, models: self.models)
            }
        }
    }
}

// ARビュー
struct ARViewContainer: UIViewRepresentable {
    @Binding var modelConfirmedForPlacement: Model?
    
    func makeUIView(context: Context) -> ARView {
        
        let arView = CustomARView(frame: .zero)//ARView(frame: .zero)
        
        return arView
    }
    
    //
    func updateUIView(_ uiView: ARView, context: Context) {
        
        if let model = self.modelConfirmedForPlacement {
                
            if let modelEntity = model.modelEntity {
                
                print("DEBUG: adding model to scene - \(model.modelName)")
                
                let anchorEntity = AnchorEntity(plane: .any)
                anchorEntity.addChild(modelEntity.clone(recursive: true))
                
                uiView.scene.addAnchor(anchorEntity)
            } else {
                print("DEBUG: Unable to load modelEntity for \(model.modelName)")
            }
            
            
            DispatchQueue.main.async {
                self.modelConfirmedForPlacement = nil
            }
        }
    }
    
}

class CustomARView: ARView {
    
    // 動画の変更点: とりあえずFocusEntityクラスを呼び出し
    var focusSquare: FocusEntity?
    
    required init(frame frameRect: CGRect) {
        super.init(frame: frameRect)
        
        // ここでインスタンス化したらええんちゃうの？
        self.focusSquare = FocusEntity(on: self, focus: .classic)
        
        // 動画から変更あり⚠️
        focusSquare!.delegate = self
        focusSquare!.setAutoUpdate(to: true)
        
        self.setupARView()
    }
    
    @MainActor required dynamic init?(coder decoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
//    @objc required dynamic init?(coder decoder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
//    }
    
    // ARViewの呼び出し
    func setupARView() {
        
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal, .vertical]
        config.environmentTexturing = .automatic
        
        // もしデバイスがLiDARに対応していたら...
        if ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh) {
            config.sceneReconstruction = .mesh
        }
        
        // ここがself.xxx.session.runでない理由は？
        self.session.run(config)
        
    }
}

extension CustomARView: FocusEntityDelegate {
    func toTrackingState() {
        print("tracking")
    }
    
    func toInitializingState() {
        print("initializing")
    }
    
}

struct ModelPickerView: View {
    
    @Binding var isPlacementEnabled: Bool
    @Binding var selectedModel: Model?
    
    var models: [Model]
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            
            HStack(spacing: 22) {
                
                ForEach(0 ..< self.models.count) {
                    index in
                    Button(action: {
                        print("DEBUG: selected model with name \(self.models[index].modelName)")
                        
                        // モデルの代入
                        self.selectedModel = self.models[index]
                        
                        // PlacementButtonsViewの表示
                        self.isPlacementEnabled = true
                    }) {
                        Image(uiImage: self.models[index].image)
                            .resizable()
                            .frame(height: 80)
                            .aspectRatio(1/1, contentMode: .fit)
                            .background(Color.white)
                            .cornerRadius(13)
                    }
                    // .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .padding(18)
        .background(Color.black.opacity(0.5))
    }
}

struct PlacementButtonsView: View {
    
    @Binding var isPlacementEnabled: Bool
    @Binding var selectedModel: Model?
    @Binding var modelConfirmedForPlacement: Model?
    
    var body: some View {
        
        HStack {
            // Cancel Buttoon
            Button(action: {
                print("DEBUG: model placement canceled.")
                
                resetPlacementParameters()
            }) {
                Image(systemName: "xmark")
                    .frame(width: 60, height: 60)
                    .font(.title)
                    .background(Color.white.opacity(0.75))
                    .cornerRadius(30)
                    .padding(20)
            }
            
            // Confirm Button
            Button(action: {
                print("DEBUG: model placement confirmed.")
                
                // Confirmボタンを押したら、選んだモデルの名前を格納
                self.modelConfirmedForPlacement = self.selectedModel
                
                resetPlacementParameters()
            }) {
                Image(systemName: "checkmark")
                    .frame(width: 60, height: 60)
                    .font(.title)
                    .background(Color.white.opacity(0.75))
                    .cornerRadius(30)
                    .padding(20)
            }
        }
    }
    
    func resetPlacementParameters() {
        self.isPlacementEnabled = false
        self.selectedModel = nil
    }
    
}

#if DEBUG
struct ContentView_Previews : PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
#endif
