import SwiftUI
import PhotosUI
import Photos


struct TestPHAssertFromPhotoPicker: View {
    @State private var selectedPhotosPickerItem: PhotosPickerItem?
    @State var selectedImage: UIImage? = nil
    @State private var enabled = false
    
    @State var aperture: Double = 0.0
    @State var shutterSpeed: Double = 0.0
    @State var exposureTime: Double = 0.0 // 曝光时间
    @State var isoSpeed: Int = 0 // iosspeed
    
    
    var body: some View {
        VStack{
                // 单张照片
                if let image = selectedImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 400, height: 300)
                        .transition(.opacity)
                }else{
                    Image("IMG_0782")  //占位
                        .resizable()
                        .scaledToFit()
                        .frame(width: 400, height: 300)
                        .transition(.opacity)
                }
            
            VStack{
                Text("aperture: \(aperture)")
                Text("shutterSpeed: \(shutterSpeed)")
                Text("exposureTime: \(exposureTime)")
                Text("isoSpeed: \(isoSpeed)")
            }
            
            
            PhotosPicker(selection: $selectedPhotosPickerItem, matching: .any(of: [.images]), photoLibrary: .shared()) {
                
                
                Text("Select photos")
                
            }
            .disabled(!enabled)
            .onChange(of: selectedPhotosPickerItem) { newItem in
                setImage(from: selectedPhotosPickerItem)
                if let newItem = newItem, let localID = newItem.itemIdentifier {
                    let result = PHAsset.fetchAssets(withLocalIdentifiers: [localID], options: nil)
                    if let asset = result.firstObject {
//                        print("Got " + asset.debugDescription)
                        let fetchOptions = PHContentEditingInputRequestOptions()
                        fetchOptions.canHandleAdjustmentData = {(adjustmentData: PHAdjustmentData) -> Bool in
                            return true
                        }
                        asset.requestContentEditingInput(with: fetchOptions){ (input, _) in
                            guard let input = input else {return}
                            guard let url = input.fullSizeImageURL else { return }
                            let imageSource = CGImageSourceCreateWithURL(url as CFURL, nil)
                            let metaData = CGImageSourceCopyPropertiesAtIndex(imageSource!, 0, nil) as? [CFString: Any]
                            if let exifData = metaData?[kCGImagePropertyExifDictionary] as? [CFString: Any]{
                                    ///光圈值
                                aperture = exifData[kCGImagePropertyExifApertureValue] as? Double ?? 0.0
                                    ///The shutter speed value.快门速度
                                shutterSpeed = exifData[kCGImagePropertyExifShutterSpeedValue] as? Double ?? 0.0
                                    ///The exposure time.  曝光时间
                                exposureTime = exifData[kCGImagePropertyExifExposureTime] as? Double ?? 0.0
                                    ///The ISO speed ratings
                                let isoSpeedArray = exifData[kCGImagePropertyExifISOSpeedRatings] as? [Int]
                                isoSpeed = isoSpeedArray?.first ?? 0
                            }
                            
                        }
                    }
                    
                    Task {
                        if let data = try? await newItem.loadTransferable(type: Data.self) {
                            let _ =  UIImage(data: data)
                        }
                    }
                }
            }
        }
        .onAppear {
            PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
                enabled = status == .authorized
            }
        }
    }
    
        // 选择单张照片
        private func setImage(from selection: PhotosPickerItem?) {
            guard let selection else { return }
            Task {
                do {
                    let data = try await selection.loadTransferable(type: Data.self)
                    guard let data, let uiImage = UIImage(data: data) else {
                        throw URLError(.badServerResponse)
                    }
                    selectedImage = uiImage
       
                } catch {
                    print(error)
                }
            }
        }
}

@available (iOS 16, *)
struct TestPHAssertFromPhotoPicker_Previews: PreviewProvider {
    static var previews: some View {
        TestPHAssertFromPhotoPicker()
    }
}
