import SwiftUI
import FirebaseAuth
import CoreLocation
import PhotosUI
import FirebaseStorage

struct NewLocationDetailView: View {
    @EnvironmentObject var locationVM: LocationViewModel
    @State var location: Location
    @Environment(\.dismiss) private var dismiss
    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var selectedPhotos: [UIImage] = []
    @State private var uploading = false
    let geocoder = CLGeocoder()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 12) {
                        Group {
                            Text("Enter Name:")
                                .font(.headline)
                            TextField("Name", text: $location.name)
                                .textFieldStyle(.roundedBorder)
                                .padding(8)
                                .background(Color.white)
                                .cornerRadius(10)
                                .shadow(radius: 5)
                        }

                        Group {
                            Text("Enter Address:")
                                .font(.headline)
                            TextField("Street, City, Zipcode", text: $location.address)
                                .textFieldStyle(.roundedBorder)
                                .padding(8)
                                .background(Color.white)
                                .cornerRadius(10)
                                .shadow(radius: 5)
                        }

                        Group {
                            Text("Asking Price: \(Int(location.numberValue))")
                                .font(.headline)
                            Slider(value: $location.numberValue, in: 500...4500, step: 10)
                                .padding(.horizontal, 8)
                        }

                        Group {
                            Toggle(isOn: $location.negotiate) {
                                Text("Willing to Negotiate")
                                    .font(.headline)
                            }
                            .padding(8)
                            .background(Color.white)
                            .cornerRadius(10)
                            .shadow(radius: 5)
                        }

                        Group {
                            Stepper("Rooms: \(location.number_of_bedrooms)", value: $location.number_of_bedrooms)
                                .font(.headline)
                                .padding(8)
                                .background(Color.white)
                                .cornerRadius(10)
                                .shadow(radius: 5)
                        }

                        Group {
                            Toggle(isOn: $location.parking) {
                                Text("Parking Availability")
                                    .font(.headline)
                            }
                            .padding(8)
                            .background(Color.white)
                            .cornerRadius(10)
                            .shadow(radius: 5)
                        }

                        Group {
                            Text("Contact Email:")
                                .font(.headline)
                            TextField("Email", text: $location.email)
                                .textFieldStyle(.roundedBorder)
                                .padding(8)
                                .background(Color.white)
                                .cornerRadius(10)
                                .shadow(radius: 5)
                        }

                        Group {
                            Text("Contact Phone #:")
                                .font(.headline)
                            TextField("Phone #", text: $location.phone)
                                .textFieldStyle(.roundedBorder)
                                .padding(8)
                                .background(Color.white)
                                .cornerRadius(10)
                                .shadow(radius: 5)
                        }

                        Group {
                            Text("Amenities Notes:")
                                .font(.headline)
                            TextField("Laundry Service, Wifi, Other Notes", text: $location.ammenities)
                                .textFieldStyle(.roundedBorder)
                                .padding(8)
                                .background(Color.white)
                                .cornerRadius(10)
                                .shadow(radius: 5)
                        }

                        // PhotosPicker for selecting multiple images
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Upload Photos:")
                                .font(.headline)
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
                    }
                    .padding(.horizontal)
                    .background(Color("BCGold"))
                    .cornerRadius(15)
                    .shadow(radius: 10)
                }
                .padding()
            }
            .background(Color("BCGold").edgesIgnoringSafeArea(.all))
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Back") {
                        dismiss()
                    }
                    .foregroundColor(Color("BC"))
                    .bold()
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    if uploading {
                        ProgressView()
                    } else {
                        Button("Save") {
                            uploading = true
                            Task {
                                guard let userID = Auth.auth().currentUser?.uid else { return }
                                location.userID = userID
                                
                                // Geocode the address
                                let geocodedLocation = try await geocodeAddress(location.address)
                                location.latitude = geocodedLocation.latitude
                                location.longitude = geocodedLocation.longitude
                                
                                // Upload selected photos to Firebase Storage
                                let photoURLs = await uploadPhotos()
                                location.photoURLs = photoURLs

                                // Save the location with photo URLs to Firestore
                                let success = await locationVM.saveLocation(location: location)
                                
                                if success {
                                    dismiss()
                                } else {
                                    print("Error saving")
                                }
                                uploading = false
                            }
                        }
                        .foregroundColor(Color("BC"))
                        .bold()
                    }
                }
            }
        }
        .navigationBarBackButtonHidden()
    }
    
    private func geocodeAddress(_ address: String) async throws -> CLLocationCoordinate2D {
        let placemarks = try await geocoder.geocodeAddressString(address)
        guard let location = placemarks.first?.location else {
            throw NSError(domain: "GeocodingError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unable to geocode address"])
        }
        return location.coordinate
    }
    
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
}

struct NewLocationDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NewLocationDetailView(location: Location())
            .environmentObject(LocationViewModel())
    }
}
