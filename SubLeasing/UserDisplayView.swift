import SwiftUI
import MapKit
import PhotosUI
import FirebaseStorage

struct UserDisplayView: View {
    struct Annotation: Identifiable {
        let id = UUID().uuidString
        var name: String
        var address: String
        var coordinate: CLLocationCoordinate2D
    }
    
    @State var location: Location
    @EnvironmentObject var locationVM: LocationViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var mapRegion = MKCoordinateRegion()
    @State private var annotations: [Annotation] = []
    let regionSize = 500.0
    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var selectedPhotos: [UIImage] = []
    @State private var uploading = false

    var body: some View {
        ScrollView(showsIndicators: true) {
            ZStack(alignment: .leading) {
                Color("BC")
                
                VStack(alignment: .leading) {
                    Rectangle()
                        .frame(width: 400, height: 90)
                        .foregroundColor(Color("BC"))
                        .ignoresSafeArea()
                    // Editable Name
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Poster Name")
                            .foregroundColor(.white)
                            .bold()
                            .padding(.top)
                            .padding(.horizontal)
                        TextField("Enter your name", text: $location.name)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .padding(.horizontal)
                    }
                    
                    // Editable Address
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Address")
                            .foregroundColor(.white)
                            .bold()
                            .padding(.top)
                            .padding(.horizontal)
                        TextField("Enter address", text: $location.address)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .padding(.horizontal)
                    }
                    
                    // Editable Price
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Asking Price")
                            .foregroundColor(.white)
                            .bold()
                            .padding(.top)
                            .padding(.horizontal)
                        Slider(value: $location.numberValue, in: 500...4500, step: 50)
                            .padding(.horizontal)
                        Text("From: $\(Int(location.numberValue)).00")
                            .foregroundColor(.white)
                            .padding(.horizontal)
                    }

                    // Parking Availability and Bedrooms
                    HStack(spacing: 20) {
                        Toggle(isOn: $location.parking) {
                            Text("Parking Available")
                                .foregroundColor(.white)
                                .bold()
                        }
                        .padding(.leading)

                        Stepper("Rooms: \(location.number_of_bedrooms)", value: $location.number_of_bedrooms, in: 1...10)
                            .padding(.trailing)
                            .foregroundColor(.white)
                            .bold()
                    }
                    .padding(.vertical)

                    // Editable Amenities
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Amenities")
                            .foregroundColor(.white)
                            .bold()
                            .padding(.top)
                            .padding(.horizontal)
                        TextField("Enter amenities", text: $location.ammenities)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .padding(.horizontal)
                    }

                    // Map View
                    VStack(alignment: .leading) {
                        Text("Location on Map")
                            .foregroundColor(.white)
                            .bold()
                            .padding(.top)
                            .padding(.horizontal)
                        Map(coordinateRegion: $mapRegion, annotationItems: annotations) { annotation in
                            MapMarker(coordinate: annotation.coordinate)
                        }
                        .frame(height: 350)
                        .cornerRadius(10)
                        .padding()
                    }

                    // Display and Delete Existing Photos
                    if !location.photoURLs.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Existing Photos")
                                .foregroundColor(.white)
                                .bold()
                                .padding(.top)
                                .padding(.horizontal)

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack {
                                    ForEach(location.photoURLs, id: \.self) { photoURL in
                                        VStack {
                                            AsyncImage(url: URL(string: photoURL)) { phase in
                                                switch phase {
                                                case .empty:
                                                    ProgressView()
                                                        .frame(width: 128, height: 128)
                                                case .success(let image):
                                                    image
                                                        .resizable()
                                                        .scaledToFill()
                                                        .frame(width: 128, height: 128)
                                                        .cornerRadius(10)
                                                case .failure:
                                                    Image(systemName: "photo")
                                                        .resizable()
                                                        .scaledToFill()
                                                        .frame(width: 128, height: 128)
                                                        .cornerRadius(10)
                                                @unknown default:
                                                    EmptyView()
                                                }
                                            }
                                            Button(action: {
                                                deletePhoto(photoURL: photoURL)
                                            }) {
                                                Image(systemName: "trash")
                                                    .foregroundColor(.red)
                                            }
                                        }
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                    }

                    // PhotosPicker for selecting and uploading new photos
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Upload Photos:")
                            .font(.headline)
                            .foregroundColor(.white)
                        PhotosPicker(selection: $selectedItems, maxSelectionCount: 10, matching: .images) {
                            Text("Select Photos")
                                .bold()
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                        .onChange(of: selectedItems) { newItems in
                            selectedPhotos = []
                            for item in newItems {
                                Task {
                                    if let data = try? await item.loadTransferable(type: Data.self),
                                       let uiImage = UIImage(data: data) {
                                        selectedPhotos.append(uiImage)
                                    }
                                }
                            }
                        }

                        // Display selected photos
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack {
                                ForEach(selectedPhotos, id: \.self) { photo in
                                    Image(uiImage: photo)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 100, height: 100)
                                        .cornerRadius(10)
                                        .clipped()
                                }
                            }
                        }
                    }
                    .padding()

                    Spacer()

                    // Save Button
                    Button("Save") {
                        uploading = true
                        Task {
                            // Upload new photos and update location data
                            let photoURLs = await uploadPhotos()
                            location.photoURLs.append(contentsOf: photoURLs)
                            await saveLocationData()
                            uploading = false
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color("BCGold"))
                    .font(.system(size: 30))
                    .bold()
                    .padding()

                }
                .padding()
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Back") {
                            dismiss()
                        }
                        .bold()
                        .foregroundColor(Color.white)
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            Task {
                                let delete = await locationVM.deleteLocation(location: location)
                                if delete {
                                    dismiss()
                                } else {
                                    print("Error deleting location")
                                }
                            }
                        } label: {
                            Image(systemName: "trash")
                        }
                        .foregroundColor(Color.white)
                    }
                }
            }
            .onAppear {
                if location.id != nil {
                    mapRegion = MKCoordinateRegion(center: location.coordinate, latitudinalMeters: regionSize, longitudinalMeters: regionSize)
                } else {
                    print("shouldn't be here")
                }
                annotations = [Annotation(name: location.name, address: location.address, coordinate: location.coordinate)]
            }
            .navigationBarBackButtonHidden()
        }
        .ignoresSafeArea()
    }
    
    // Function to save the location data
    private func saveLocationData() async {
        await locationVM.saveLocation(location: location)
        dismiss()
    }

    // Function to upload new photos and return their URLs
    private func uploadPhotos() async -> [String] {
        var photoURLs: [String] = []
        
        guard !selectedPhotos.isEmpty else { return photoURLs }
        
        for (index, photo) in selectedPhotos.enumerated() {
            guard let imageData = photo.jpegData(compressionQuality: 0.8) else { continue }
            
            let storageRef = Storage.storage().reference().child("locations/\(location.id ?? UUID().uuidString)/photo\(index).jpg")
            let _ = try? await storageRef.putDataAsync(imageData, metadata: nil)
            
            if let downloadURL = try? await storageRef.downloadURL() {
                photoURLs.append(downloadURL.absoluteString)
            }
        }
        
        return photoURLs
    }

    // Function to delete a photo
    private func deletePhoto(photoURL: String) {
        guard let index = location.photoURLs.firstIndex(of: photoURL) else { return }
        location.photoURLs.remove(at: index)
        // Here, you may also want to delete the image from Firebase Storage if necessary.
    }
}

struct UserDisplayView_Previews: PreviewProvider {
    static var previews: some View {
        UserDisplayView(location: Location())
            .environmentObject(LocationViewModel())
    }
}
